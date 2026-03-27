package entity

import "testing"

func TestPrice_IsValid(t *testing.T) {
	p := &Price{Symbol: "BTCUSDT", CurrentPrice: 30000}
	if !p.IsValid() {
		t.Fatal("bekleniyor: geçerli fiyat için true")
	}

	p2 := &Price{Symbol: "", CurrentPrice: 30000}
	if p2.IsValid() {
		t.Fatal("beklenmiyor: sembol boş iken true")
	}
}

func TestPrice_IsRising_IsFalling(t *testing.T) {
	p := &Price{ChangePercent: 5.5}
	if !p.IsRising() || p.IsFalling() {
		t.Fatal("bekleniyor: yükseliş, düşüş değil")
	}

	p.ChangePercent = -3.2
	if p.IsRising() || !p.IsFalling() {
		t.Fatal("beklenmiyor: düşüş, yükseliş değil")
	}
}

func TestPrice_SpreadPercent_String(t *testing.T) {
	p := &Price{Spread: 10, AskPrice: 200}
	if got := p.SpreadPercent(); got != 5 {
		t.Fatalf("SpreadPercent yanlış: got=%v, want=5", got)
	}

	p.AskPrice = 0
	if got := p.SpreadPercent(); got != 0 {
		t.Fatalf("SpreadPercent sıfır ask için 0 olmalı, got=%v", got)
	}

	p.Symbol = "ETHUSDT"
	p.CurrentPrice = 1500
	p.ChangePercent = 1.2
	if got := p.String(); got == "" {
		t.Fatalf("String boş olmamalı: %q", got)
	}
}
