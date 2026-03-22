package server

import (
	"crypto_price_tracker_backend/internal/delivery/websocket"
	"encoding/json"
	"net/http"
	"strings"
)

// registerRoutes — tüm HTTP ve WebSocket route'larını buraya ekle
func (s *server) registerRoutes(mux *http.ServeMux) {

	// ── Health ────────────────────────────────────────────────────────────────
	mux.HandleFunc("GET /health", s.handleHealth)

	// ── Prices ───────────────────────────────────────────────────────────────
	// GET /api/v1/prices/BTCUSDT/latest
	// GET /api/v1/prices/BTCUSDT/history?from=2024-01-01&to=2024-01-02
	mux.HandleFunc("GET /api/v1/prices/{symbol}/latest", s.handleLatestPrice)
	mux.HandleFunc("GET /api/v1/prices/{symbol}/history", s.handlePriceHistory)

	// ── Orders (P2P) ─────────────────────────────────────────────────────────
	// POST /api/v1/orders
	mux.HandleFunc("POST /api/v1/orders", s.handlePlaceOrder)

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

func (s *server) handleLatestPrice(w http.ResponseWriter, r *http.Request) {
	symbol := strings.ToUpper(r.PathValue("symbol"))
	if symbol == "" {
		writeError(w, http.StatusBadRequest, "symbol gerekli")
		return
	}

	// TODO: usecase inject edilince buraya gelecek
	// price, err := s.priceUC.GetLatest(r.Context(), symbol)
	// şimdilik cache'den oku
	data, err := s.cache.Get(r.Context(), "price:latest:"+symbol).Bytes()
	if err != nil {
		writeError(w, http.StatusNotFound, "fiyat bulunamadı: "+symbol)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(data)
}

func (s *server) handlePriceHistory(w http.ResponseWriter, r *http.Request) {
	symbol := strings.ToUpper(r.PathValue("symbol"))
	from := r.URL.Query().Get("from")
	to := r.URL.Query().Get("to")

	// TODO: usecase inject edilince buraya gelecek
	writeJSON(w, http.StatusOK, map[string]any{
		"symbol": symbol,
		"from":   from,
		"to":     to,
		"data":   []any{},
	})
}

func (s *server) handlePlaceOrder(w http.ResponseWriter, r *http.Request) {
	// var req OrderRequests
	// if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
	// 	writeError(w, http.StatusBadRequest, "geçersiz istek body'si")
	// 	return
	// }

	// if err := req.Validate(); err != nil {
	// 	writeError(w, http.StatusBadRequest, err.Error())
	// 	return
	// }

	// // TODO: usecase inject edilince buraya gelecek
	// writeJSON(w, http.StatusCreated, map[string]any{
	// 	"status":  "pending",
	// 	"message": "sipariş alındı",
	// })
}

// ── Helpers ───────────────────────────────────────────────────────────────────

func writeJSON(w http.ResponseWriter, status int, data any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

func writeError(w http.ResponseWriter, status int, msg string) {
	writeJSON(w, status, map[string]string{"error": msg})
}
