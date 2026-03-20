package config

import (
	"crypto_price_tracker_backend/pkg/binance"
	kafkaConsumer "crypto_price_tracker_backend/pkg/kafka"
	logger "crypto_price_tracker_backend/pkg/log"
	postgres "crypto_price_tracker_backend/pkg/psql"
	redisConsumer "crypto_price_tracker_backend/pkg/redis"
	"fmt"
	"os"
	"time"

	"gopkg.in/yaml.v3"
)

// ── YAML struct ───────────────────────────────────────────────────────────────

type yamlConfig struct {
	App struct {
		Host       string `yaml:"server_host"`
		ServerPort string `yaml:"server_port"`
		GRPCPort   string `yaml:"grpc_port"`
	} `yaml:"app"`

	Log struct {
		Level string `yaml:"level"`
		Env   string `yaml:"env"`
	} `yaml:"log"`

	Postgres struct {
		Host     string `yaml:"host"`
		Port     int    `yaml:"port"`
		User     string `yaml:"user"`
		Password string `yaml:"password"`
		DBName   string `yaml:"db_name"`
		SSLMode  string `yaml:"ssl_mode"`
		MaxConns int32  `yaml:"max_conns"`
		MinConns int32  `yaml:"min_conns"`
	} `yaml:"postgres"`

	Redis struct {
		Host     string `yaml:"host"`
		Port     int    `yaml:"port"`
		Password string `yaml:"password"`
		DB       int    `yaml:"db"`
		PoolSize int    `yaml:"pool_size"`
	} `yaml:"redis"`

	Kafka struct {
		Brokers         []string `yaml:"brokers"`
		Topic           string   `yaml:"topic"`
		GroupID         string   `yaml:"group_id"`
		WriteTimeoutSec int      `yaml:"write_timeout_sec"`
		ReadTimeoutSec  int      `yaml:"read_timeout_sec"`
	} `yaml:"kafka"`

	Binance struct {
		BaseURL          string   `yaml:"base_url"`
		ReconnectWaitSec int      `yaml:"reconnect_wait_sec"`
		ReadTimeoutSec   int      `yaml:"read_timeout_sec"`
		Symbols          []string `yaml:"symbols"`
	} `yaml:"binance"`
}

type Server struct {
	ServerHost string
	ServerPort string
	GRPCPort   string
}

type Config struct {
	Log      *logger.Config
	Postgres *postgres.Config
	Redis    *redisConsumer.Config
	Kafka    *kafkaConsumer.Config
	Binance  *binance.Config
	Server   *Server
}

func Load() (*Config, error) {
	path := os.Getenv("CONFIG_PATH")
	if path == "" {
		path = "config/config.yaml"
	}

	f, err := os.Open(path)
	if err != nil {
		return nil, fmt.Errorf("config açılamadı (%s): %w", path, err)
	}
	defer f.Close()

	var y yamlConfig
	if err := yaml.NewDecoder(f).Decode(&y); err != nil {
		return nil, fmt.Errorf("config parse hatası: %w", err)
	}

	return &Config{
		Server: &Server{
			ServerHost: y.App.Host,
			ServerPort: y.App.ServerPort,
			GRPCPort:   y.App.GRPCPort,
		},

		Log: &logger.Config{
			Level: y.Log.Level,
			Env:   y.Log.Env,
		},

		Postgres: &postgres.Config{
			Host:     y.Postgres.Host,
			Port:     y.Postgres.Port,
			User:     y.Postgres.User,
			Password: y.Postgres.Password,
			DBName:   y.Postgres.DBName,
			SSLMode:  y.Postgres.SSLMode,
			MaxConns: y.Postgres.MaxConns,
			MinConns: y.Postgres.MinConns,
		},

		Redis: &redisConsumer.Config{
			Host:     y.Redis.Host,
			Port:     y.Redis.Port,
			Password: y.Redis.Password,
			DB:       y.Redis.DB,
			PoolSize: y.Redis.PoolSize,
		},

		Kafka: &kafkaConsumer.Config{
			Brokers:      y.Kafka.Brokers,
			Topic:        y.Kafka.Topic,
			GroupID:      y.Kafka.GroupID,
			WriteTimeout: time.Duration(y.Kafka.WriteTimeoutSec) * time.Second,
			ReadTimeout:  time.Duration(y.Kafka.ReadTimeoutSec) * time.Second,
		},

		Binance: &binance.Config{
			BaseURL:       y.Binance.BaseURL,
			Symbols:       y.Binance.Symbols,
			ReconnectWait: time.Duration(y.Binance.ReconnectWaitSec) * time.Second,
			ReadTimeout:   time.Duration(y.Binance.ReadTimeoutSec) * time.Second,
		},
	}, nil
}
