# crypto-price-tracker — backend

A real-time cryptocurrency price tracking backend built with Go. Pulls live data from Binance WebSocket, pushes it through Kafka, and broadcasts to connected Flutter and React clients via WebSocket. Also has a basic P2P order matching system on top.

Built this as a portfolio project to demonstrate clean architecture, event-driven systems, and real-time data handling in Go.

---

## What it does

- Connects to Binance's free market data WebSocket stream
- Receives live ticker data for BTC, ETH, BNB, SOL (configurable)
- Publishes each price update to a Kafka topic
- A Kafka consumer picks it up and broadcasts to all WebSocket clients subscribed to that symbol
- Price history is saved to PostgreSQL
- Latest prices are cached in Redis (10s TTL) so you don't hammer the DB on every request
- Simple P2P order book — place BUY/SELL orders, they get matched when market price crosses your target

---

## Stack

| What | Why |
|---|---|
| Go 1.24.5 | Fast, great concurrency primitives, goroutines make WebSocket hubs clean |
| Fiber v2 | HTTP framework, faster than net/http for this use case |
| gorilla/websocket | WebSocket upgrade and connection management |
| Apache Kafka | Decouples Binance ingestion from client broadcasting |
| PostgreSQL 16 | Price history, order storage |
| Redis 7 | Latest price cache, reduces DB reads significantly |
| Docker Compose | One command to spin everything up |
| Zap | Structured logging, way better than log.Printf in production |

---

## Architecture

```
Binance WebSocket
      |
      | ticker events (BTC, ETH, BNB, SOL)
      v
  Go Backend
      |
      |-- usecase.ProcessTicker()
      |       |-- save to PostgreSQL
      |       |-- cache in Redis (10s TTL)
      |       |-- publish to Kafka topic "price-updates"
      |
      |-- Kafka Consumer
              |-- reads from "price-updates"
              |-- hub.Broadcast(symbol, data)
                      |
                      |-- Flutter clients (WebSocket or gRPC stream)
                      |-- React clients (WebSocket)
```

The Kafka layer might seem overkill for a single instance, but it means if you ever need to scale horizontally (multiple server instances), each one just subscribes to the same Kafka topic and broadcasts to its own connected clients. No code changes needed.

### Clean Architecture layers

```
internal/
├── domain/         pure Go structs and interfaces, zero dependencies
├── usecase/        business logic, depends only on domain interfaces  
├── repository/     PostgreSQL and Redis implementations
└── delivery/       HTTP handlers, WebSocket hub, gRPC server
```

The domain layer has no idea Postgres or Redis even exist. Swap them out anytime.

---

## Getting started

You need Docker and Docker Compose. That's it.

```bash
git clone https://github.com/Baykam/crypto-tracker
cd crypto-tracker/backend

# start everything
docker-compose up --build
```

This starts PostgreSQL, Redis, Zookeeper, Kafka, and the Go server. The Go server waits for all dependencies to be healthy before starting (healthchecks in compose).

Once running:

```bash
# health check
curl http://localhost:8080/health

# latest BTC price
curl http://localhost:8080/api/v1/prices/BTCUSDT/latest

# connect to live price stream
# (use wscat, Postman, or your Flutter/React app)
wscat -c ws://localhost:8080/ws/BTCUSDT
```

---

## Configuration

The project uses two config files:

| File | When |
|---|---|
| `config/config.yaml` | Local development (uses localhost) |
| `config/config.docker.yaml` | Docker (uses container names) |

The server picks the right one via `CONFIG_PATH` env variable. Dockerfile sets this to `config/config.docker.yaml` automatically.

If you want to run the server locally but infrastructure in Docker:

```bash
# start only the infrastructure
docker-compose up crypto_postgres crypto_redis crypto_kafka crypto_zookeeper

# run server locally (uses config.yaml with localhost)
go run ./cmd/server
```

To change which symbols you track, edit `config.yaml`:

```yaml
binance:
  symbols:
    - BTCUSDT
    - ETHUSDT
    - SOLUSDT
    - XRPUSDT   # add whatever you want
```

---

## API

### REST

```
GET  /health
GET  /api/v1/prices/:symbol/latest
GET  /api/v1/prices/:symbol/history?from=2024-01-01&to=2024-01-02
POST /api/v1/orders
```

Place a P2P order:
```bash
curl -X POST http://localhost:8080/api/v1/orders \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user_1",
    "symbol": "BTCUSDT",
    "type": "BUY",
    "amount": 0.001,
    "target_price": 68000.00
  }'
```

### WebSocket

Connect to live price updates for any symbol:

```
ws://localhost:8080/ws/BTCUSDT
ws://localhost:8080/ws/ETHUSDT
```

Message format:
```json
{
  "symbol": "BTCUSDT",
  "current_price": 70358.76,
  "change_percent": -0.083,
  "high_price": 71367.00,
  "low_price": 68793.35,
  "bid_price": 70358.75,
  "ask_price": 70358.76,
  "spread": 0.01,
  "volume": 19863.42,
  "timestamp": 1704067200000
}
```

### gRPC

Server streaming endpoint for Flutter — more efficient than WebSocket for mobile:

```
PriceService/StreamPrices  — subscribe to one or more symbols
PriceService/GetLatestPrice — single price fetch
OrderService/PlaceOrder
```

Proto file is at `internal/delivery/grpc/proto/price.proto`. Run `make proto` to regenerate Go code.

## Project structure

```
cmd/server/main.go          entry point, wires everything together
config/                     yaml configs + Go struct
internal/
  domain/entity/            Price, Order structs + domain methods
  domain/repository/        repository interfaces (no implementations here)
  usecase/                  business logic lives here
  repository/postgres/      PostgreSQL implementations
  repository/redis/         Redis cache implementation
  delivery/http/            REST handlers
  delivery/websocket/       hub + connection handlers
  delivery/grpc/            gRPC server + streaming
  server/                   server struct, runs everything
pkg/
  binance/                  Binance WebSocket client
  kafka/                    producer + consumer
  log/                      global zap wrapper
  psql/                     PostgreSQL connect + config
  redis/                    Redis connect + config
```

---

## Known limitations

- No authentication on WebSocket or REST endpoints yet — fine for a portfolio project, not for production
- Single Kafka broker setup — would need replication factor changes for real production
- Order matching runs on every price tick — would need a proper order book with indexes at scale
- No rate limiting on the WebSocket endpoint

---

## Author

Baymuhammet Gummanov — Flutter & Go developer
[github.com/Baykam](https://github.com/Baykam) · [LinkedIn](https://linkedin.com/in/baymuhammet-gummanow-0aaa96204)