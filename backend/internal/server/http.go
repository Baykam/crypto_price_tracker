package server

import (
	"crypto_price_tracker_backend/internal/delivery/websocket"
	"encoding/json"
	"net/http"
)

// registerRoutes — tüm HTTP ve WebSocket route'larını buraya ekle
func (s *server) registerRoutes(mux *http.ServeMux) {

	// ── Health ────────────────────────────────────────────────────────────────
	mux.HandleFunc("GET /health", s.handleHealth)

	// ── Prices ───────────────────────────────────────────────────────────────
	// GET /api/v1/prices/BTCUSDT/latest
	// GET /api/v1/prices/BTCUSDT/history?symbol=BTCUSDT&limit=10
	mux.HandleFunc("GET /api/v1/prices/{symbol}/latest", s.httpProvider.HandleLatestPrice)
	mux.HandleFunc("GET /api/v1/prices/{symbol}/history", s.httpProvider.GetHistory)

	// ── WebSocket ─────────────────────────────────────────────────────────────
	// ws://host/ws/BTCUSDT,TOKI,ETH
	wsHandler := websocket.NewHandler(s.hub)
	mux.HandleFunc("/ws/{symbol}", wsHandler.HandleConnection)
}

// ── Handlers ─────────────────────────────────────────────────────────────────

func (s *server) handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(s.hub.OnlineCount())
}
