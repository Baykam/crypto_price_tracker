package websocket

import (
	"context"
	"crypto_price_tracker_backend/internal/domain/entity"
	"encoding/json"
	"sync"

	"github.com/redis/go-redis/v9"
)

type Client struct {
	ID     string
	Symbol string
	Send   chan []byte
	Hub    *Hub
}

type Hub struct {
	mu          sync.RWMutex
	rooms       map[string]map[*Client]bool
	register    chan *Client
	unregister  chan *Client
	subscribe   chan string
	unsubscribe chan string
	redis       redis.UniversalClient
}

func NewHub(redis redis.UniversalClient) *Hub {
	return &Hub{
		rooms:       make(map[string]map[*Client]bool),
		register:    make(chan *Client, 32),
		unregister:  make(chan *Client, 32),
		subscribe:   make(chan string, 32),
		unsubscribe: make(chan string, 32),
		redis:       redis,
	}
}

func (h *Hub) Run() {
	for {
		select {
		case client := <-h.register:
			h.mu.Lock()
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
						h.unsubscribe <- client.Symbol
					}
				}
			}
			h.mu.Unlock()
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

func (h *Hub) ListenRedis(ctx context.Context) {
	pubsub := h.redis.PSubscribe(ctx, "ticker:*")
	defer pubsub.Close()

	ch := pubsub.Channel()

	for msg := range ch {
		var rawTicker entity.Ticker

		if err := json.Unmarshal([]byte(msg.Payload), &rawTicker); err != nil {
			continue
		}

		publicData := rawTicker.ToPublic()
		finalJson, _ := json.Marshal(publicData)
		symbol := msg.Channel[7:]
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
