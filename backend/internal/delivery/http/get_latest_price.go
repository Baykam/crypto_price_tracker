package httpHandler

import (
	"net/http"
	"strings"
	"time"

	"go.uber.org/zap"
)

func (s *Provider) HandleLatestPrice(w http.ResponseWriter, r *http.Request) {
	symbol := strings.ToUpper(r.PathValue("symbol"))
	if symbol == "" {
		s.log.Error("symbol gerekli")
		http.Error(w, "symbol gerekli", http.StatusBadRequest)
		return
	}

	data, err := s.cache.Get(r.Context(), symbol).Bytes()

	if err != nil {
		s.log.Info("Cache miss, fetching from Binance REST API", zap.String("symbol", symbol))

		liveData, err := s.provider.GetLatestPrice(r.Context(), symbol)
		if err != nil {
			s.log.Error("Error fetching latest price", zap.String("symbol", symbol), zap.Error(err))
			http.Error(w, "fiyat çekilemedi: "+err.Error(), http.StatusNotFound)
			return
		}

		s.cache.Set(r.Context(), symbol, liveData, 1*time.Minute)

		data = liveData
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(data)
}
