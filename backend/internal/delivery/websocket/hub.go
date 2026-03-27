package websocket

import (
	"context"
	"crypto_price_tracker_backend/internal/domain/entity"
	"crypto_price_tracker_backend/pkg/binance"
	"encoding/json"
	"fmt"
	"sync"
	"time"

	"github.com/redis/go-redis/v9"
	"go.uber.org/zap"
)

const gracePeriod = 30 * time.Second

type Client struct {
	ID     string
	Symbol string
	Send   chan []byte
	Hub    *Hub
}

type unsubscribeRequest struct {
	symbol string
	timer  *time.Timer
}

type Hub struct {
	mu           sync.RWMutex
	rooms        map[string]map[*Client]bool
	pendingUnsub map[string]*time.Timer

	register    chan *Client
	unregister  chan *Client
	subscribe   chan string
	unsubscribe chan string
	redis       redis.UniversalClient
}

func NewHub(redis redis.UniversalClient) *Hub {
	return &Hub{
		rooms:        make(map[string]map[*Client]bool),
		pendingUnsub: make(map[string]*time.Timer),
		register:     make(chan *Client, 32),
		unregister:   make(chan *Client, 32),
		subscribe:    make(chan string, 64),
		unsubscribe:  make(chan string, 64),
		redis:        redis,
	}
}

func (h *Hub) Run(ctx context.Context, binanceClient binance.ClientInterface) {
	for {
		select {
		case client := <-h.register:
			h.mu.Lock()

			// Eğer bu symbol için bekleyen unsubscribe timer varsa iptal et
			if timer, ok := h.pendingUnsub[client.Symbol]; ok {
				timer.Stop()
				delete(h.pendingUnsub, client.Symbol)
			}

			if _, ok := h.rooms[client.Symbol]; !ok {
				h.rooms[client.Symbol] = make(map[*Client]bool)
				h.subscribe <- client.Symbol
			}
			h.rooms[client.Symbol][client] = true
			h.mu.Unlock()

		case client := <-h.unregister:
			h.mu.Lock()
			if room, ok := h.rooms[client.Symbol]; ok {
				if _, ok := room[client]; ok {
					delete(room, client)
					close(client.Send)

					if len(room) == 0 {
						delete(h.rooms, client.Symbol)

						// Hemen unsubscribe etme, 30sn bekle
						symbol := client.Symbol
						timer := time.AfterFunc(gracePeriod, func() {
							h.unsubscribe <- symbol
							h.mu.Lock()
							delete(h.pendingUnsub, symbol)
							h.mu.Unlock()
						})
						h.pendingUnsub[symbol] = timer
					}
				}
			}
			h.mu.Unlock()

		case symbol := <-h.subscribe:
			go func(s string) {
				if err := binanceClient.Subscribe(s); err != nil {
					// log
				}
			}(symbol)

		case symbol := <-h.unsubscribe:
			go func(s string) {
				if err := binanceClient.Unsubscribe(s); err != nil {
					// log
				}
			}(symbol)

		case <-ctx.Done():
			// Bekleyen tüm timer'ları temizle
			h.mu.Lock()
			for _, timer := range h.pendingUnsub {
				timer.Stop()
			}
			h.mu.Unlock()
			return
		}
	}
}

func (h *Hub) Subscribe(symbol string) {
	h.subscribe <- symbol
}

func (h *Hub) Unsubscribe(symbol string) {
	h.unsubscribe <- symbol
}

func (h *Hub) Register(client *Client) {
	h.register <- client
}

func (h *Hub) Unregister(client *Client) {
	h.unregister <- client
}

func (h *Hub) Broadcast(symbol string, data []byte) {
	h.mu.RLock()
	room, ok := h.rooms[symbol]
	if !ok {
		h.mu.RUnlock()
		return
	}

	clients := make([]*Client, 0, len(room))
	for client := range room {
		clients = append(clients, client)
	}
	h.mu.RUnlock()

	for _, client := range clients {
		select {
		case client.Send <- data:
		default:
			h.Unregister(client)
		}
	}
}

func (h *Hub) SwitchSymbol(client *Client, oldSymbol, newSymbol string) {
	h.mu.Lock()
	defer h.mu.Unlock()

	// 1. Eski odadan (room) çıkar
	if room, ok := h.rooms[oldSymbol]; ok {
		delete(room, client)
		if len(room) == 0 {
			// Eğer odada kimse kalmadıysa Binance'ten çıkış isteği gönder (Grace period başlat)
			delete(h.rooms, oldSymbol)
			symbol := oldSymbol
			timer := time.AfterFunc(gracePeriod, func() {
				h.unsubscribe <- symbol
			})
			h.pendingUnsub[symbol] = timer
		}
	}

	// 2. Yeni odaya (room) ekle
	client.Symbol = newSymbol // Client'ın yeni sembolünü güncelle
	if _, ok := h.rooms[newSymbol]; !ok {
		h.rooms[newSymbol] = make(map[*Client]bool)
		h.subscribe <- newSymbol // Yeni sembole Binance üzerinden abone ol
	}
	h.rooms[newSymbol][client] = true

	// 3. Eğer yeni sembol için bekleyen bir iptal (unsubscribe) varsa durdur
	if timer, ok := h.pendingUnsub[newSymbol]; ok {
		timer.Stop()
		delete(h.pendingUnsub, newSymbol)
	}
}

func (h *Hub) ListenRedis(ctx context.Context) {
	pubsub := h.redis.PSubscribe(ctx, "*")
	defer pubsub.Close()

	ch := pubsub.Channel()

	for msg := range ch {

		symbol := msg.Channel[7:]

		fmt.Println("Redis --> WebSocket", zap.String("symbol", symbol))

		var rawTicker entity.Ticker
		if err := json.Unmarshal([]byte(msg.Payload), &rawTicker); err != nil {
			continue
		}

		publicData := rawTicker.ToPublic()
		finalJson, _ := json.Marshal(publicData)
		h.Broadcast(symbol, finalJson)
	}
}

func (h *Hub) BroadcastJSON(symbol string, v any) {
	data, err := json.Marshal(v)
	if err != nil {
		return
	}
	h.Broadcast(symbol, data)
}

func (h *Hub) OnlineCount() int {
	h.mu.RLock()
	defer h.mu.RUnlock()
	total := 0
	for _, room := range h.rooms {
		total += len(room)
	}
	return total
}
