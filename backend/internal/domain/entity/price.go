package entity

import (
	"fmt"
	"time"
)

// Price — core domain entity, DB veya JSON tag yok
type Price struct {
	ID            int64
	Symbol        string
	CurrentPrice  float64
	OpenPrice     float64
	HighPrice     float64
	LowPrice      float64
	ChangeAmount  float64
	ChangePercent float64
	Volume        float64
	BidPrice      float64
	AskPrice      float64
	Spread        float64
	TradeCount    int64
	Timestamp     time.Time
}

// ── Price Methods ─────────────────────────────────────────────────────────────

// IsValid — gerekli alanlar dolu mu
func (p *Price) IsValid() bool {
	return p.Symbol != "" && p.CurrentPrice > 0
}

// IsRising — fiyat yükseliyor mu
func (p *Price) IsRising() bool {
	return p.ChangePercent > 0
}

// IsFalling — fiyat düşüyor mu
func (p *Price) IsFalling() bool {
	return p.ChangePercent < 0
}

// SpreadPercent — spread yüzde olarak
func (p *Price) SpreadPercent() float64 {
	if p.AskPrice == 0 {
		return 0
	}
	return (p.Spread / p.AskPrice) * 100
}

// String — debug için
func (p *Price) String() string {
	return fmt.Sprintf("%s: %.2f (%.2f%%)", p.Symbol, p.CurrentPrice, p.ChangePercent)
}

// ── Binance Ticker ────────────────────────────────────────────────────────────

// BinanceTicker — Binance WebSocket'ten gelen ham veri
type BinanceTicker struct {
	EventType     string `json:"e"`
	EventTime     string `json:"E"`
	Symbol        string `json:"s"`
	PriceChange   string `json:"p"`
	ChangePercent string `json:"P"`
	WeightedAvg   string `json:"w"`
	OpenPrice     string `json:"x"`
	CurrentPrice  string `json:"c"`
	BestBid       string `json:"b"`
	BestBidQty    string `json:"B"`
	BestAsk       string `json:"a"`
	BestAskQty    string `json:"A"`
	OpenPrice24h  string `json:"o"`
	HighPrice     string `json:"h"`
	LowPrice      string `json:"l"`
	Volume        string `json:"v"`
	TradeCount    string `json:"n"`
}
