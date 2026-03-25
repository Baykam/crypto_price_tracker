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
	// GET /api/v1/prices/BTCUSDT/history?from=2024-01-01&to=2024-01-02
	mux.HandleFunc("GET /api/v1/prices/{symbol}/latest", s.httpProvider.HandleLatestPrice)
	mux.HandleFunc("GET /api/v1/prices/{symbol}/history", s.httpProvider.GetHistory)

	// ── WebSocket ─────────────────────────────────────────────────────────────
	// ws://host/ws/BTCUSDT
	wsHandler := websocket.NewHandler(s.hub)
	mux.HandleFunc("/ws/{symbol}", wsHandler.HandleConnection)
}

// ── Handlers ─────────────────────────────────────────────────────────────────

func (s *server) handleHealth(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{
		"status":       "ok",
		"online_users": s.hub.OnlineCount(),
	})
}

// ── Helpers ───────────────────────────────────────────────────────────────────

func writeJSON(w http.ResponseWriter, status int, data any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}
