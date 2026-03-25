package binance

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
)

type HistoricalPrice struct {
	OpenTime int64  `json:"open_time"`
	Price    string `json:"price"`
}

func (c *Client) GetHistoricalPrices(ctx context.Context, symbol string, limit int) ([]HistoricalPrice, error) {
	url := fmt.Sprintf("https://api.binance.com/api/v3/klines?symbol=%s&interval=1m&limit=%d",
		strings.ToUpper(symbol), limit)

	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return nil, err
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var raw [][]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&raw); err != nil {
		return nil, err
	}

	prices := make([]HistoricalPrice, 0)
	for _, item := range raw {
		prices = append(prices, HistoricalPrice{
			OpenTime: int64(item[0].(float64)),
			Price:    item[4].(string),
		})
	}
	return prices, nil
}

// GetLatestPrice — Binance REST API üzerinden anlık fiyatı çeker
func (c *Client) GetLatestPrice(ctx context.Context, symbol string) ([]byte, error) {
	url := fmt.Sprintf("https://api.binance.com/api/v3/ticker/price?symbol=%s", strings.ToUpper(symbol))

	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return nil, err
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("binance api error: %d", resp.StatusCode)
	}

	return io.ReadAll(resp.Body)
}
