package websocket

import (
	"encoding/json"
	"sync"
)

type Client struct {
	ID     string
	Symbol string
	Send   chan []byte
	Hub    *Hub
}

type Hub struct {
	mu         sync.RWMutex
	rooms      map[string]map[*Client]bool
	register   chan *Client
	unregister chan *Client
}

func NewHub() *Hub {
	return &Hub{
		rooms:      make(map[string]map[*Client]bool),
		register:   make(chan *Client, 32),
		unregister: make(chan *Client, 32),
	}
}

func (h *Hub) Run() {
	for {
		select {
		case client := <-h.register:
			h.mu.Lock()
			if _, ok := h.rooms[client.Symbol]; !ok {
				h.rooms[client.Symbol] = make(map[*Client]bool)
			}
			h.rooms[client.Symbol][client] = true
			h.mu.Unlock()

		case client := <-h.unregister:
			h.mu.Lock()
			if room, ok := h.rooms[client.Symbol]; ok {
				if _, ok := room[client]; ok {
					delete(room, client)
					close(client.Send)
				}
			}
			h.mu.Unlock()
		}
	}
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
