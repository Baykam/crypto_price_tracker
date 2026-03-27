package websocket

import (
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"
	gows "github.com/gorilla/websocket"
)

const (
	writeWait      = 10 * time.Second
	pongWait       = 60 * time.Second
	pingPeriod     = (pongWait * 9) / 10
	maxMessageSize = 512
)

var upgrader = gows.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin:     func(r *http.Request) bool { return true },
}

type Handler struct {
	hub *Hub
}

func NewHandler(hub *Hub) *Handler {
	return &Handler{hub: hub}
}

func (h *Handler) HandleConnection(w http.ResponseWriter, r *http.Request) {
	symbol := strings.ToUpper(r.PathValue("symbol"))

	if symbol == "" {
		symbol = strings.ToUpper(strings.TrimPrefix(r.URL.Path, "/ws/"))
		symbol = strings.Trim(symbol, "/")
	}

	if symbol == "" {
		http.Error(w, "symbol gerekli", http.StatusBadRequest)
		return
	}

	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		return
	}

	client := &Client{
		ID:     uuid.NewString(),
		Symbol: symbol,
		Send:   make(chan []byte, 256),
		Hub:    h.hub,
	}

	h.hub.Register(client)

	go h.writePump(conn, client)
	h.readPump(conn, client)
}

func (h *Handler) writePump(conn *gows.Conn, client *Client) {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		conn.Close()
	}()

	for {
		select {
		case message, ok := <-client.Send:
			conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				conn.WriteMessage(gows.CloseMessage, []byte{})
				return
			}
			if err := conn.WriteMessage(gows.TextMessage, message); err != nil {
				return
			}

		case <-ticker.C:
			conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := conn.WriteMessage(gows.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

func (h *Handler) readPump(conn *gows.Conn, client *Client) {
	defer func() {
		h.hub.Unregister(client)
		conn.Close()
	}()

	conn.SetReadLimit(maxMessageSize)
	conn.SetReadDeadline(time.Now().Add(pongWait))
	conn.SetPongHandler(func(string) error {
		conn.SetReadDeadline(time.Now().Add(pongWait))
		return nil
	})

	for {
		messageType, message, err := conn.ReadMessage()
		if err != nil {
			break
		}

		if messageType == gows.TextMessage {
			msgStr := string(message)

			if strings.Contains(msgStr, "->") {
				parts := strings.Split(msgStr, "->")
				if len(parts) == 2 {
					oldSymbol := strings.ToUpper(strings.TrimSpace(parts[0]))
					newSymbol := strings.ToUpper(strings.TrimSpace(parts[1]))

					fmt.Printf("🔄 Switch Request: %s to %s\n", oldSymbol, newSymbol)

					h.hub.SwitchSymbol(client, oldSymbol, newSymbol)
				}
			}
		}
	}
}
