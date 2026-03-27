package server

import (
	"context"
	"crypto_price_tracker_backend/config"
	httpHandler "crypto_price_tracker_backend/internal/delivery/http"
	"crypto_price_tracker_backend/internal/delivery/websocket"
	"crypto_price_tracker_backend/pkg/binance"
	kafkaConsumer "crypto_price_tracker_backend/pkg/kafka"
	logger "crypto_price_tracker_backend/pkg/log"
	postgres "crypto_price_tracker_backend/pkg/psql"
	redisClient "crypto_price_tracker_backend/pkg/redis"
	"encoding/json"
	"net/http"
	"os/signal"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"
	"go.uber.org/zap"
)

type server struct {
	log *zap.Logger
	// kafkaReader   *kafka.Reader

	kafkaProducer *kafkaConsumer.Producer
	kafkaConsumer *kafkaConsumer.Consumer
	sql           *pgxpool.Pool
	cache         redis.UniversalClient
	binanceClient binance.ClientInterface
	cfg           *config.Config

	httpServer   *http.Server
	httpProvider httpHandler.ProviderInterface
	hub          *websocket.Hub
}

func NewServer(cfg *config.Config) *server {
	return &server{
		cfg: cfg,
	}
}

func (s *server) Run() error {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	log := logger.New(s.cfg.Log)
	defer log.Sync()
	s.log = log

	s.runRedis(ctx)
	s.runSql(ctx)
	s.runKafka()

	s.runBinance(ctx)

	s.httpProvider = httpHandler.NewProvider(s.binanceClient, s.log, s.cache)
	s.hub = websocket.NewHub(s.cache)
	go s.hub.Run(ctx, s.binanceClient)
	go s.hub.ListenRedis(ctx)

	s.setupHTTP()
	go func() {
		s.log.Info("🚀 HTTP server started", zap.String("addr", s.cfg.Server.ServerHost))
		if err := s.httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			s.log.Fatal("http server error", zap.Error(err))
		}
	}()

	<-ctx.Done()
	s.log.Info("🔌 Graceful shutdown initiated...")
	return s.shutdown()
}

// // ── Binance ───────────────────────────────────────────────────────────────────

func (s *server) runBinance(ctx context.Context) {
	cfg := binance.DefaultConfig()
	s.binanceClient = binance.NewClient(cfg, s.log)

	go func() {
		if err := s.binanceClient.Connect(ctx); err != nil {
			s.log.Error("binance connection error", zap.Error(err))
		}
	}()

	// Binance ticker → Kafka publisher goroutine
	go func() {
		for ticker := range s.binanceClient.GetTickerChan() {
			data, err := json.Marshal(ticker)
			if err != nil {
				s.log.Error("ticker marshal error", zap.Error(err))
				continue
			}
			if err := s.kafkaProducer.Publish(ctx, ticker.Symbol, data); err != nil {
				s.log.Warn("kafka publish error", zap.Error(err))
			}
		}
	}()

	s.log.Info("✅ Binance stream started",
		zap.Strings("symbols", s.cfg.Binance.Symbols),
	)
}

func (s *server) shutdown() error {
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := s.httpServer.Shutdown(shutdownCtx); err != nil {
		s.log.Error("http shutdown error", zap.Error(err))
	}

	if s.binanceClient != nil {
		s.log.Info("Closing Binance connection...")
		s.binanceClient.Close()
	}

	s.kafkaProducer.Close()
	s.kafkaConsumer.Close()
	s.sql.Close()
	s.cache.Close()

	s.log.Info("✅ Servis closed gracefully")
	return nil
}

func (s *server) setupHTTP() {
	mux := http.NewServeMux()
	s.registerRoutes(mux)

	s.httpServer = &http.Server{
		Addr:         s.cfg.Server.ServerPort,
		Handler:      mux,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  60 * time.Second,
	}
}

func (s *server) runSql(ctx context.Context) {
	sql, err := postgres.Connect(ctx, s.cfg.Postgres)
	if err != nil {
		s.log.Fatal("postgres connect", zap.Error(err))
	}
	s.sql = sql
}

func (s *server) runRedis(ctx context.Context) {
	cache, err := redisClient.Connect(ctx, s.cfg.Redis)
	if err != nil {
		s.log.Fatal("redis connect", zap.Error(err))
	}
	s.cache = cache
}

func (s *server) runKafka() {
	producer, err := kafkaConsumer.NewProducer(s.cfg.Kafka)
	if err != nil {
		s.log.Fatal("kafka producer not started", zap.Error(err))
	}
	s.kafkaProducer = producer

	kk, err := kafkaConsumer.NewConsumer(s.cfg.Kafka, s.log)
	if err != nil {
		s.log.Fatal("kafka consumer not started", zap.Error(err))
	}

	go func() {
		if err := kk.Consume(context.Background(), func(key, value []byte) error {
			symbol := string(key)
			ctx := context.Background()

			s.log.Debug("Kafka --> Redis", zap.String("symbol", symbol))

			// Cache için Set
			s.cache.Set(ctx, "ticker:"+symbol, value, 0)

			// WebSocket için Publish ✅
			if err := s.cache.Publish(ctx, "ticker:"+symbol, value).Err(); err != nil {
				s.log.Error("redis publish error", zap.Error(err))
			}
			return nil
		}); err != nil {
			s.log.Fatal("kafka consume", zap.Error(err))
		}
	}()
}
