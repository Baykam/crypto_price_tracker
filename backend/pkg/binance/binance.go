package binance

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
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

func DefaultConfig(symbols []string) *Config {
	return &Config{
		Symbols:       symbols,
		BaseURL:       "wss://stream.binance.com:9443/stream?streams=",
		ReconnectWait: 3 * time.Second,
		ReadTimeout:   60 * time.Second,
	}
}

type Ticker struct {
	Symbol        string `json:"s"`
	CurrentPrice  string `json:"c"`
	OpenPrice     string `json:"o"`
	HighPrice     string `json:"h"`
	LowPrice      string `json:"l"`
	PriceChange   string `json:"p"`
	ChangePercent string `json:"P"`
	Volume        string `json:"v"`
	BestBid       string `json:"b"`
	BestAsk       string `json:"a"`
	EventTime     int64  `json:"E"`
	TradeCount    int64  `json:"n"`
}

type combinedStream struct {
	Data Ticker `json:"data"`
}

type Client struct {
	cfg      *Config
	log      *zap.Logger
	TickerCh chan *Ticker
}

func NewClient(cfg *Config, log *zap.Logger) *Client {
	return &Client{
		cfg:      cfg,
		log:      log,
		TickerCh: make(chan *Ticker, 256),
	}
}

func (c *Client) Connect(ctx context.Context) error {
	url := c.buildURL()
	c.log.Info("Binance connecting", zap.String("url", url))

	for {
		if ctx.Err() != nil {
			return nil
		}

		conn, _, err := websocket.DefaultDialer.DialContext(ctx, url, nil)
		if err != nil {
			c.log.Warn("Binance connect error", zap.Error(err), zap.Duration("wait", c.cfg.ReconnectWait))
			select {
			case <-ctx.Done():
				c.log.Error("Context cancelled", zap.Error(ctx.Err()))
				return nil
			case <-time.After(c.cfg.ReconnectWait):
				continue
			}
		}

		c.log.Info("✅ Binance bağlandı")
		c.readLoop(ctx, conn)

		// readLoop if closed connection, try to reconnect
		if ctx.Err() != nil {
			return nil
		}
		c.log.Warn("Binance connection lost, reconnecting...", zap.Duration("wait", c.cfg.ReconnectWait))
		time.Sleep(c.cfg.ReconnectWait)
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

func (c *Client) parse(msg []byte) (*Ticker, error) {
	var s combinedStream
	if err := json.Unmarshal(msg, &s); err != nil {
		return nil, err
	}
	if s.Data.Symbol == "" {
		return nil, fmt.Errorf("empty symbol in data: %s", string(msg))
	}
	return &s.Data, nil
}

func (c *Client) buildURL() string {
	streams := make([]string, len(c.cfg.Symbols))
	for i, s := range c.cfg.Symbols {
		streams[i] = strings.ToLower(s) + "@ticker"
	}
	return c.cfg.BaseURL + strings.Join(streams, "/")
}
