package main

import (
	"crypto_price_tracker_backend/config"
	"crypto_price_tracker_backend/internal/server"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		panic(err)
	}

	srv := server.NewServer(cfg)
	if err := srv.Run(); err != nil {
		panic(err)
	}
}
