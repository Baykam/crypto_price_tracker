package binance

import (
	"context"
	"crypto_price_tracker_backend/internal/domain/entity"
	"encoding/json"
	"fmt"
	"strings"
	"sync"
	"time"

	"github.com/gorilla/websocket"
	"go.uber.org/zap"
)

type Config struct {
	Symbols       []string
	BaseURL       string
	ReconnectWait time.Duration
	ReadTimeout   time.Duration
}

func DefaultConfig() *Config {
	return &Config{
		Symbols:       []string{},
		BaseURL:       "wss://stream.binance.com:9443",
		ReconnectWait: 3 * time.Second,
		ReadTimeout:   60 * time.Second,
	}
}

type combinedStream struct {
	Data entity.Ticker `json:"data"`
}

type Client struct {
	cfg       *Config
	log       *zap.Logger
	TickerCh  chan *entity.Ticker
	connReady chan struct{}

	mu   sync.Mutex
	conn *websocket.Conn
}

type ClientInterface interface {
	Connect(ctx context.Context) error
	Subscribe(symbol string) error
	Unsubscribe(symbol string) error
	GetTickerChan() chan *entity.Ticker
	Close()
	GetHistoricalPrices(ctx context.Context, symbol string, limit int) ([]byte, error)
	GetLatestPrice(ctx context.Context, symbol string) ([]byte, error)
}

func NewClient(cfg *Config, log *zap.Logger) ClientInterface {
	return &Client{
		cfg:       cfg,
		log:       log,
		TickerCh:  make(chan *entity.Ticker, 256),
		connReady: make(chan struct{}, 1),
	}
}

func (c *Client) Connect(ctx context.Context) error {
	url := c.buildURL()
	c.log.Info("Binance connecting", zap.String("url", url))

	minWait := c.cfg.ReconnectWait
	maxWait := 1 * time.Minute
	currentWait := minWait

	for {
		if ctx.Err() != nil {
			return nil
		}

		conn, _, err := websocket.DefaultDialer.DialContext(ctx, url, nil)
		if err != nil {
			c.log.Warn("Binance connect error", zap.Error(err), zap.Duration("wait", currentWait))
			select {
			case <-ctx.Done():
				c.log.Error("Context cancelled", zap.Error(ctx.Err()))
				return nil
			case <-time.After(currentWait):
				currentWait *= 2
				if currentWait > maxWait {
					currentWait = maxWait
				}
				continue
			}
		}

		c.mu.Lock()
		c.conn = conn
		c.mu.Unlock()

		select {
		case c.connReady <- struct{}{}:
		default:
		}

		c.log.Info("✅ Binance bağlandı")
		c.readLoop(ctx, conn)

		c.mu.Lock()
		c.conn = nil
		c.mu.Unlock()

		if ctx.Err() != nil {
			return nil
		}
		c.log.Warn("Binance connection lost, reconnecting...", zap.Duration("wait", currentWait))
		select {
		case <-ctx.Done():
			return nil
		case <-time.After(currentWait):
			currentWait *= 2
			if currentWait > maxWait {
				currentWait = maxWait
			}
		}
	}
}

func (c *Client) readLoop(ctx context.Context, conn *websocket.Conn) {
	defer conn.Close()

	conn.SetReadDeadline(time.Now().Add(c.cfg.ReadTimeout))
	conn.SetPongHandler(func(string) error {
		conn.SetReadDeadline(time.Now().Add(c.cfg.ReadTimeout))
		return nil
	})

	for {
		_, msg, err := conn.ReadMessage()
		if err != nil {
			if ctx.Err() != nil {
				return
			}
			c.log.Error("Binance read error", zap.Error(err))
			return
		}

		ticker, err := c.parse(msg)
		if err != nil {
			c.log.Debug("parse error", zap.Error(err))
			continue
		}

		select {
		case c.TickerCh <- ticker:
		default:
			// read loop
		}
	}
}

func (c *Client) parse(msg []byte) (*entity.Ticker, error) {
	var s combinedStream
	if err := json.Unmarshal(msg, &s); err == nil && s.Data.Symbol != "" {
		return &s.Data, nil
	}

	var ticker entity.Ticker
	if err := json.Unmarshal(msg, &ticker); err != nil {
		return nil, err
	}

	if ticker.Symbol == "" {
		return nil, fmt.Errorf("empty symbol in data: %s", string(msg))
	}

	return &ticker, nil
}

func (c *Client) buildURL() string {
	baseURL := strings.TrimSuffix(c.cfg.BaseURL, "/")

	if len(c.cfg.Symbols) == 0 {
		return baseURL + "/ws"
	}

	streams := make([]string, len(c.cfg.Symbols))
	for i, s := range c.cfg.Symbols {
		streams[i] = strings.ToLower(s) + "@ticker"
	}
	return fmt.Sprintf("%s/stream?streams=%s", baseURL, strings.Join(streams, "/"))
}

func (c *Client) Subscribe(symbol string) error {
	const (
		maxAttempts = 5
		retryWait   = 2 * time.Second
		connTimeout = 30 * time.Second
	)

	for attempt := 1; attempt <= maxAttempts; attempt++ {
		c.mu.Lock()
		conn := c.conn
		c.mu.Unlock()

		// Bağlantı hazırsa direkt gönder
		if conn != nil {
			msg := map[string]any{
				"method": "SUBSCRIBE",
				"params": []string{strings.ToLower(symbol) + "@ticker"},
				"id":     time.Now().Unix(),
			}
			c.mu.Lock()
			err := c.conn.WriteJSON(msg)
			c.mu.Unlock()

			if err == nil {
				c.log.Info("✅ Subscribed", zap.String("symbol", symbol))
				return nil
			}
			c.log.Warn("Subscribe write error, retrying...",
				zap.String("symbol", symbol),
				zap.Int("attempt", attempt),
				zap.Error(err),
			)
		} else {
			c.log.Warn("Connection not ready, waiting...",
				zap.String("symbol", symbol),
				zap.Int("attempt", attempt),
			)

			// Bağlantı bekleme — connReady sinyali veya timeout
			select {
			case <-c.connReady:
				c.log.Info("Connection ready, retrying subscribe",
					zap.String("symbol", symbol),
				)
				continue // hemen tekrar dene, wait yapma
			case <-time.After(connTimeout):
				return fmt.Errorf("timeout waiting for connection: symbol=%s", symbol)
			}
		}

		// Hata aldık ama conn vardı — kısa bekle ve tekrar dene
		if attempt < maxAttempts {
			time.Sleep(retryWait)
		}
	}

	return fmt.Errorf("subscribe failed after %d attempts: symbol=%s", maxAttempts, symbol)
}
func (c *Client) Unsubscribe(symbol string) error {
	const maxAttempts = 3

	for attempt := 1; attempt <= maxAttempts; attempt++ {
		c.mu.Lock()
		conn := c.conn
		c.mu.Unlock()

		if conn == nil {
			// Bağlantı zaten yok, unsubscribe'a gerek yok
			return nil
		}

		msg := map[string]any{
			"method": "UNSUBSCRIBE",
			"params": []string{strings.ToLower(symbol) + "@ticker"},
			"id":     time.Now().Unix(),
		}

		c.mu.Lock()
		err := c.conn.WriteJSON(msg)
		c.mu.Unlock()

		if err == nil {
			c.log.Info("✅ Unsubscribed", zap.String("symbol", symbol))
			return nil
		}

		c.log.Warn("Unsubscribe error, retrying...",
			zap.String("symbol", symbol),
			zap.Int("attempt", attempt),
			zap.Error(err),
		)

		if attempt < maxAttempts {
			time.Sleep(time.Second)
		}
	}

	return fmt.Errorf("unsubscribe failed after %d attempts: symbol=%s", maxAttempts, symbol)
}

func (c *Client) Close() {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.conn != nil {
		c.conn.Close()
	}
}

func (c *Client) GetTickerChan() chan *entity.Ticker {
	return c.TickerCh
}
