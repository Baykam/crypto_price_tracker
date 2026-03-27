package binance

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"

	"go.uber.org/zap"
)

type HistoricalPrice struct {
	OpenTime int64  `json:"open_time"`
	Open     string `json:"open"`
	High     string `json:"high"`
	Low      string `json:"low"`
	Close    string `json:"close"`
	Volume   string `json:"volume"`
}

func (c *Client) GetHistoricalPrices(ctx context.Context, symbol string, limit int) ([]byte, error) {
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

	var raw [][]any
	if err := json.NewDecoder(resp.Body).Decode(&raw); err != nil {
		return nil, err
	}

	prices := make([]HistoricalPrice, 0)
	for _, item := range raw {
		prices = append(prices, HistoricalPrice{
			OpenTime: int64(item[0].(float64)),
			Open:     fmt.Sprintf("%v", item[1]),
			High:     fmt.Sprintf("%v", item[2]),
			Low:      fmt.Sprintf("%v", item[3]),
			Close:    fmt.Sprintf("%v", item[4]),
			Volume:   fmt.Sprintf("%v", item[5]),
		})
	}
	lastList, err := json.Marshal(prices)
	if err != nil {
		return nil, err
	}

	return lastList, nil
}

// GetLatestPrice — Binance REST API üzerinden anlık fiyatı çeker
func (c *Client) GetLatestPrice(ctx context.Context, symbol string) ([]byte, error) {
	url := fmt.Sprintf("https://api.binance.com/api/v3/ticker/price?symbol=%s", strings.ToUpper(symbol))

	c.log.Debug("Inside GetLatestPrice", zap.String("symbol", symbol), zap.String("url", url))

	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		c.log.Error("Inside GetLatestPrice", zap.Error(err))
		return nil, err
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		c.log.Error("Inside GetLatestPrice do func", zap.Error(err))
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("binance api error: %d", resp.StatusCode)
	}

	return io.ReadAll(resp.Body)
}
