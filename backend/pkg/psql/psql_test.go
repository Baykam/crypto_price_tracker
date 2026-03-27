package postgres

import "testing"

func TestConfigDSN(t *testing.T) {
	cfg := &Config{
		Host:     "localhost",
		Port:     5432,
		User:     "test",
		Password: "secret",
		DBName:   "db",
		SSLMode:  "disable",
	}
	got := cfg.DSN()
	want := "postgres://test:secret@localhost:5432/db?sslmode=disable"
	if got != want {
		t.Fatalf("DSN yanlış: got=%q, want=%q", got, want)
	}
}
