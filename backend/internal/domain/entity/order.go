package entity

import (
	"fmt"
	"time"
)

type OrderType string
type OrderStatus string

const (
	OrderTypeBuy  OrderType = "BUY"
	OrderTypeSell OrderType = "SELL"

	OrderStatusPending  OrderStatus = "PENDING"
	OrderStatusMatched  OrderStatus = "MATCHED"
	OrderStatusCanceled OrderStatus = "CANCELED"
)

type Order struct {
	ID          int64
	UserID      string
	Symbol      string
	Type        OrderType
	Amount      float64
	TargetPrice float64
	Status      OrderStatus
	CreatedAt   time.Time
}

// ── Methods ───────────────────────────────────────────────────────────────────

// Validate — domain kurallarını kontrol eder
func (o *Order) Validate() error {
	if o.UserID == "" {
		return fmt.Errorf("user_id boş olamaz")
	}
	if o.Symbol == "" {
		return fmt.Errorf("symbol boş olamaz")
	}
	if o.Type != OrderTypeBuy && o.Type != OrderTypeSell {
		return fmt.Errorf("geçersiz order type: %s", o.Type)
	}
	if o.Amount <= 0 {
		return fmt.Errorf("amount sıfırdan büyük olmalı")
	}
	if o.TargetPrice <= 0 {
		return fmt.Errorf("target_price sıfırdan büyük olmalı")
	}
	return nil
}

// IsBuy — BUY order mı
func (o *Order) IsBuy() bool {
	return o.Type == OrderTypeBuy
}

// IsSell — SELL order mı
func (o *Order) IsSell() bool {
	return o.Type == OrderTypeSell
}

// IsPending — hala bekliyor mu
func (o *Order) IsPending() bool {
	return o.Status == OrderStatusPending
}

// Match — order'ı matched olarak işaretle
func (o *Order) Match() {
	o.Status = OrderStatusMatched
}

// Cancel — order'ı iptal et
func (o *Order) Cancel() {
	o.Status = OrderStatusCanceled
}

// MatchesPrice — piyasa fiyatı bu order'ı tetikler mi?
// BUY  → target_price >= market_price ise eşleşir
// SELL → target_price <= market_price ise eşleşir
func (o *Order) MatchesPrice(marketPrice float64) bool {
	switch o.Type {
	case OrderTypeBuy:
		return o.TargetPrice >= marketPrice
	case OrderTypeSell:
		return o.TargetPrice <= marketPrice
	default:
		return false
	}
}
