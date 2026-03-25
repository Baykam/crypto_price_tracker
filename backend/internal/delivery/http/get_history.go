// internal/delivery/http/price_handler.go
package httpHandler

import (
	"crypto_price_tracker_backend/pkg/binance"
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/redis/go-redis/v9"
	"go.uber.org/zap"
)

type Provider struct {
	provider binance.ClientInterface
	log      *zap.Logger
	cache    redis.UniversalClient
}

type ProviderInterface interface {
	HandleLatestPrice(w http.ResponseWriter, r *http.Request)
	GetHistory(w http.ResponseWriter, r *http.Request)
}

func NewProvider(p binance.ClientInterface, log *zap.Logger, cache redis.UniversalClient) ProviderInterface {
	return &Provider{provider: p, log: log, cache: cache}
}

func (h *Provider) GetHistory(w http.ResponseWriter, r *http.Request) {
	symbol := r.URL.Query().Get("symbol")
	limitStr := r.URL.Query().Get("limit")

	limit, _ := strconv.Atoi(limitStr)
	if limit <= 0 {
		limit = 5
	}

	if symbol == "" {
		http.Error(w, "symbol is required", http.StatusBadRequest)
		return
	}

	prices, err := h.provider.GetHistoricalPrices(r.Context(), symbol, limit)
	if err != nil {
		h.log.Error("Error fetching historical prices", zap.Error(err))
		http.Error(w, "Geçmiş veri çekilemedi", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(prices)
}
