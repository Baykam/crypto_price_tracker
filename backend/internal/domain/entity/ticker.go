package entity

import "encoding/json"

type Ticker struct {
	EventType string `json:"e"`
	EventTime int64  `json:"E"`
	Symbol    string `json:"s"`
	// json.Number kullanarak hem string hem number formatını destekliyoruz
	PriceChange     json.Number `json:"p"`
	ChangePercent   json.Number `json:"P"`
	WeightedAvg     json.Number `json:"w"`
	PrevClose       json.Number `json:"x"`
	CurrentPrice    json.Number `json:"c"`
	LastQty         json.Number `json:"Q"`
	BestBid         json.Number `json:"b"`
	BestBidQty      json.Number `json:"B"`
	BestAsk         json.Number `json:"a"`
	BestAskQty      json.Number `json:"A"`
	OpenPrice       json.Number `json:"o"`
	HighPrice       json.Number `json:"h"`
	LowPrice        json.Number `json:"l"`
	Volume          json.Number `json:"v"`
	QuoteVolume     json.Number `json:"q"`
	StatisticsOpen  int64       `json:"O"`
	StatisticsClose int64       `json:"C"`
	FirstTradeID    int64       `json:"F"`
	LastTradeID     int64       `json:"L"`
	TradeCount      int64       `json:"n"`
}

type PublicTicker struct {
	Symbol    string `json:"s"`
	Price     string `json:"p"`
	Change    string `json:"c"`
	Timestamp int64  `json:"t"`
}

func (t *Ticker) ToPublic() *PublicTicker {
	return &PublicTicker{
		Symbol:    t.Symbol,
		Price:     t.CurrentPrice.String(),
		Change:    t.PriceChange.String(),
		Timestamp: t.EventTime,
	}
}
