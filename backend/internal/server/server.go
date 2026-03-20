package server

import (
	"context"
	"crypto_price_tracker_backend/config"
	"crypto_price_tracker_backend/pkg/binance"
	kafkaConsumer "crypto_price_tracker_backend/pkg/kafka"
	logger "crypto_price_tracker_backend/pkg/log"
	postgres "crypto_price_tracker_backend/pkg/psql"
	redisClient "crypto_price_tracker_backend/pkg/redis"
	"net/http"
	"os/signal"
	"syscall"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"
	"github.com/segmentio/kafka-go"
	"go.uber.org/zap"
)

type server struct {
	log           *zap.Logger
	kafkaReader   *kafka.Reader
	sql           *pgxpool.Pool
	cache         redis.UniversalClient
	binanceClient binance.Client
	cfg           *config.Config
	network       *http.Server
	// hub           *websocket.Hub
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
	s.log = log

	s.httpAdd()
	s.runRedis(ctx)
	s.runSql(ctx)
	s.runKafka()

	return nil
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
	kk, err := kafkaConsumer.NewConsumer(s.cfg.Kafka, s.log)
	if err != nil {
		s.log.Fatal("kafka consumer", zap.Error(err))
	}

	go func() {
		if err := kk.Consume(context.Background(), func(key, value []byte) error {
			s.log.Info("kafka message", zap.String("Key", string(key)), zap.ByteString("value", value))
			return nil
		}); err != nil {
			s.log.Fatal("kafka consume", zap.Error(err))
		}
	}()
}

func (s *server) httpAdd() {
	s.network = &http.Server{
		Addr:    s.cfg.Server.ServerHost,
		Handler: http.NewServeMux(),
	}
}
