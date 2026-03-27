package server

import (
	"crypto_price_tracker_backend/internal/delivery/websocket"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestHandleHealth(t *testing.T) {
	srv := &server{hub: websocket.NewHub(nil)}

	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	w := httptest.NewRecorder()

	srv.handleHealth(w, req)

	resp := w.Result()
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("StatusCode yanlış: got=%d, want=%d", resp.StatusCode, http.StatusOK)
	}
	if ct := resp.Header.Get("Content-Type"); ct != "application/json" {
		t.Fatalf("Content-Type yanlış: got=%q, want=%q", ct, "application/json")
	}
}
