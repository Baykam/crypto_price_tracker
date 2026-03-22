package kafkaConsumer

import (
	"context"
	"fmt"
	"net"
	"time"

	"github.com/segmentio/kafka-go"
	"go.uber.org/zap"
)

type Config struct {
	Brokers      []string
	Topic        string
	GroupID      string
	WriteTimeout time.Duration
	ReadTimeout  time.Duration
}

func Ping(cfg *Config) error {
	for _, broker := range cfg.Brokers {
		conn, err := net.DialTimeout("tcp", broker, 5*time.Second)
		if err != nil {
			return fmt.Errorf("kafka broker not reachable (%s): %w", broker, err)
		}
		conn.Close()
	}
	return nil
}

// ── Producer ──────────────────────────────────────────────────────────────────

type Producer struct {
	writer *kafka.Writer
}

func NewProducer(cfg *Config) (*Producer, error) {
	if err := Ping(cfg); err != nil {
		return nil, err
	}

	writer := &kafka.Writer{
		Addr:                   kafka.TCP(cfg.Brokers...),
		Topic:                  cfg.Topic,
		Balancer:               &kafka.LeastBytes{},
		WriteTimeout:           cfg.WriteTimeout,
		BatchSize:              100,
		BatchBytes:             5 << 20,
		BatchTimeout:           10 * time.Millisecond,
		AllowAutoTopicCreation: true,
	}

	return &Producer{writer: writer}, nil
}

func (p *Producer) Publish(ctx context.Context, key string, value []byte) error {
	return p.writer.WriteMessages(ctx, kafka.Message{
		Key:   []byte(key),
		Value: value,
	})
}

func (p *Producer) Close() error { return p.writer.Close() }

// ── Consumer ──────────────────────────────────────────────────────────────────

type Consumer struct {
	reader *kafka.Reader
	logger *zap.Logger
}

func NewConsumer(cfg *Config, log *zap.Logger) (*Consumer, error) {
	if err := Ping(cfg); err != nil {
		return nil, err
	}

	reader := kafka.NewReader(kafka.ReaderConfig{
		Brokers:     cfg.Brokers,
		GroupID:     cfg.GroupID,
		Topic:       cfg.Topic,
		MinBytes:    1,
		MaxBytes:    10 << 20,
		StartOffset: kafka.LastOffset,
		MaxWait:     100 * time.Millisecond,
	})

	return &Consumer{reader: reader, logger: log}, nil
}

func (c *Consumer) Consume(ctx context.Context, handler func(key, value []byte) error) error {
	for {
		msg, err := c.reader.ReadMessage(ctx)
		if err != nil {
			if ctx.Err() != nil {
				return nil
			}
			c.logger.Error("kafka read", zap.Error(err))
			continue
		}
		if err := handler(msg.Key, msg.Value); err != nil {
			c.logger.Error("handler", zap.String("key", string(msg.Key)), zap.Error(err))
		}
	}
}

func (c *Consumer) Close() error { return c.reader.Close() }
