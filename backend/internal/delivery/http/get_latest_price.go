package httpHandler

import (
	"net/http"

	"go.uber.org/zap"
)

func (s *Provider) HandleLatestPrice(w http.ResponseWriter, r *http.Request) {
	symbol := r.PathValue("symbol")
	if symbol == "" {
		s.log.Error("symbol gerekli")
		http.Error(w, "symbol gerekli", http.StatusBadRequest)
		return
	}

	data, err := s.provider.GetLatestPrice(r.Context(), symbol)
	if err != nil {
		s.log.Error("Error fetching latest price", zap.String("symbol", symbol), zap.Error(err))
		http.Error(w, "fiyat çekilemedi: "+err.Error(), http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(data)
}
