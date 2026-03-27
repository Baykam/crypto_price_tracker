# crypto-price-tracker — backend

> 🚀 Real-time cryptocurrency price tracking backend (Go + Kafka + PostgreSQL + Redis)

This project is a Go service that reads live market data from Binance WebSocket, publishes ticker updates to Kafka, broadcasts them to frontend clients (Flutter/React) via WebSocket, persists historical prices in PostgreSQL, caches latest prices in Redis, and supports a simple P2P order matching engine.

---

## 🧩 What it does

- Fetches live ticker updates for selected symbols from Binance API
- Publishes each tick to Kafka topic `price-updates`
- Kafka consumer picks up the event and broadcasts it to all WebSocket clients listening on that symbol
- Stores price history to PostgreSQL
- Stores latest price in Redis cache (10s TTL) to avoid extra DB hits
- Accepts buy/sell P2P orders and matches them when market price hits the target

---

## 🛠️ Tech stack

| Component | Purpose |
|---|---|
| Go 1.24.5 | Performance, concurrency, clean architecture |
| Fiber v2 | REST API and WebSocket delivery |
| gorilla/websocket | WebSocket connection management |
| Apache Kafka | Event-driven, horizontally scalable message bus |
| PostgreSQL 16 | Price history and order storage |
| Redis 7 | Latest price caching |
| Docker Compose | Spin up service stack with one command |
| Zap | Structured logging |

---

## 🏗️ Architecture (high level)

```
Binance WebSocket
      |
      v
  Go Backend
      |-- usecase.ProcessTicker()
      |      |-- PostgreSQL: price_history
      |      |-- Redis: latest_price
      |      |-- Kafka: price-updates
      |
      |-- Kafka Consumer
             |-- hub.Broadcast(symbol, data)
             |-- WebSocket clients (live feed)
             |-- P2P order matching
```

### Clean architecture layers

- `internal/domain`: Entities and interfaces
- `internal/usecase`: Business logic, infrastructure-agnostic
- `internal/repository`: PostgreSQL, Redis, Kafka adapters
- `internal/delivery`: HTTP + WebSocket + gRPC endpoints

---

## ▶️ Quick start (Docker)

Requirements:
- Docker
- Docker Compose

```bash
git clone https://github.com/Baykam/crypto_price_tracker.git
cd crypto-tracker/backend
docker-compose up --build
```

Then verify:

```bash
curl http://localhost:8080/health
curl http://localhost:8080/api/v1/prices/BTCUSDT/latest
wscat -c ws://localhost:8080/ws/BTCUSDT
```

---

## ⚙️ Configuration

- `config/config.yaml` (local development)
- `config/config.docker.yaml` (Docker)

`CONFIG_PATH` selects which configuration file is loaded (Dockerfile sets it to `config/config.docker.yaml`).

### Change service IP/host

In both config files you can set the server host and ports for PostgreSQL, Redis, Kafka and app HTTP listener.

- For local development, use `localhost` (or `127.0.0.1`) in `config/config.yaml`
- For Docker, use service names (`crypto_postgres`, `crypto_redis`, `crypto_kafka`, etc.) in `config/config.docker.yaml`

If you need to change to a specific IP (e.g. different interface or remote DB), edit the corresponding `host` field in the config and restart the service.

Change tracked symbols in `config/config.yaml`:

```yaml
binance:
  symbols:
    - BTCUSDT
    - ETHUSDT
    - SOLUSDT
    - BNBUSDT
```

---

## 🔌 API

### REST

- `GET /health`
- `GET /api/v1/prices/:symbol/latest`
- `GET /api/v1/prices/:symbol/history?from=YYYY-MM-DD&to=YYYY-MM-DD`
- `POST /api/v1/orders`

Example order post:

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

- `ws://localhost:8080/ws/BTCUSDT`
- `ws://localhost:8080/ws/ETHUSDT`

Example payload:

```json
{
  "symbol": "BTCUSDT",
  "current_price": 70358.76,
  "high_price": 71367.00,
  "low_price": 68793.35,
  "volume": 19863.42,
  "timestamp": 1704067200000
}
```

## 🧪 Testing & code quality

- Run unit tests: `go test ./...`
- Format code: `gofmt`
- Regenerate proto code: `make proto`

---

## 📁 Project layout

- `cmd/server`: main entry point
- `config`: YAML configuration files
- `internal/delivery/http`: REST handlers
- `internal/delivery/websocket`: WebSocket hub and handlers
- `internal/domain/entity`: data models
- `internal/repository/server`: repository interfaces
- `internal/usecase`: business logic
- `pkg`: Binance/Kafka/Postgres/Redis helpers

---

## 💡 Notes

- No auth for REST/WebSocket (portfolio-ready, not production-ready)
- Single Kafka broker, no replication configuration
- Price tick-based matching for P2P orders (not optimized order book)
- No rate limiting on WebSocket endpoint

---

## Known limitations

- No authentication for WebSocket or REST endpoints yet — good for a portfolio project but not production
- Single Kafka broker setup — requires replication for high availability
- Order matching runs on every price tick — scaling requires indexed order book and efficient matching
- No WebSocket rate limiting

---

## Author

Baymuhammet Gummanov — Flutter & Go developer
[github.com/Baykam](https://github.com/Baykam) · [LinkedIn](https://linkedin.com/in/baymuhammet-gumanow-0aaa96204)

---

## 🧪 Test coverage added (English summary)

The following unit tests were added to the project and are currently passing with `go test ./...`:

1. `internal/domain/entity/order_test.go`
   - `TestOrderValidate_Success`
   - `TestOrderValidate_Error_InvalidType`
   - `TestOrderMatchesPrice`

2. `internal/domain/entity/price_test.go`
   - `TestPrice_IsValid`
   - `TestPrice_IsRising_IsFalling`
   - `TestPrice_SpreadPercent_String`

3. `pkg/psql/psql_test.go`
   - `TestConfigDSN` - ensures `DSN()` builds a correct PostgreSQL connection string.

4. `internal/server/http_test.go`
   - `TestHandleHealth` - checks `handleHealth` returns HTTP 200 and JSON content type.

---

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