package entity

import "testing"

func TestOrderValidate_Success(t *testing.T) {
	order := &Order{
		UserID:      "user-123",
		Symbol:      "BTCUSDT",
		Type:        OrderTypeBuy,
		Amount:      0.5,
		TargetPrice: 25000,
		Status:      OrderStatusPending,
	}

	if err := order.Validate(); err != nil {
		t.Fatalf("beklenmiyor hata: %v", err)
	}
}

func TestOrderValidate_Error_InvalidType(t *testing.T) {
	order := &Order{
		UserID:      "user-123",
		Symbol:      "BTCUSDT",
		Type:        "INVALID",
		Amount:      0.5,
		TargetPrice: 25000,
		Status:      OrderStatusPending,
	}

	if err := order.Validate(); err == nil {
		t.Fatal("geçersiz order type için hata bekleniyordu")
	}
}

func TestOrderMatchesPrice(t *testing.T) {
	buy := &Order{Type: OrderTypeBuy, TargetPrice: 20000}
	if !buy.MatchesPrice(19999.99) {
		t.Fatal("BUY order için fiyat eşleşmesi bekleniyor")
	}
	if buy.MatchesPrice(20001) {
		t.Fatal("BUY order için yüksek piyasa fiyatı eşleşmemeli")
	}

	sell := &Order{Type: OrderTypeSell, TargetPrice: 30000}
	if !sell.MatchesPrice(30000) {
		t.Fatal("SELL order için eşit fiyatda eşleşme bekleniyor")
	}
	if sell.MatchesPrice(29999.99) {
		t.Fatal("SELL order için düşük piyasa fiyatı eşleşmemeli")
	}
}
