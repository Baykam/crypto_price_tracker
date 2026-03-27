# crypto_price_tracker

## 📌 Project Overview

`crypto_price_tracker` is an application for tracking cryptocurrency prices. This repository contains two main components:
- `backend/`: Go-based server with WebSocket + REST API layers, data sources (Binance), and middleware.
- `mobile/`: Flutter-based cross-platform mobile application (Android/iOS/Web/Desktop).

---

## 🌍 Git Location (Repo URL)

Clone the project using the URL below:

```bash
git clone https://github.com/Baykam/crypto_price_tracker
```

> Note: Because both components are inside the same monorepo, one URL is enough.

---

## 🧩 Architecture & Paths Overview

### Architecture Decision
This project uses Kafka to provide durable, scalable message streaming between data ingestion services and backend consumers, enabling resilient handling of high-frequency market updates and horizontal scaling. WebSocket is chosen for real-time price distribution to mobile clients because it delivers low-latency bidirectional communication and keeps the client state synchronized with server-side market changes. Go is selected for backend processing due to its performance characteristics and built-in concurrency, which fits event-driven price streams well. Flutter enables a single codebase for mobile/web/desktop support, accelerating UI development and consistent design. This architecture emphasizes a clean separation of concerns, fault tolerance, and fast feedback loops for both API and front-end clients.

### backend (Go)
- Root: `backend/`
- Entry point: `backend/cmd/server/main.go`
- Configuration: `backend/config/config.yaml` and `backend/config/config.docker.yaml`
- Dependencies: `backend/go.mod`
- API server module: `backend/internal/server/`
- Data source client: `backend/pkg/binance/` (Binance REST API client)
- Data stores: `backend/pkg/redis`, `backend/pkg/psql`, Kafka consumer: `backend/pkg/kafka`

#### Run the backend
1. Download Go modules:
   ```bash
   cd backend
   go mod download
   ```
2. Set environment variables:
   - `REDIS_URL`, `DATABASE_URL`, `BINANCE_API_KEY`, `BINANCE_SECRET` (if required)
3. Preferred Docker approach:
   ```bash
   cd backend
   docker-compose up --build
   ```
4. Run locally:
   ```bash
   go run ./cmd/server
   ```

#### Fast test startup
- In backend directory:
  ```bash
  go test ./...
  ```

#### Key endpoints
- REST API: `http://localhost:8080/api/...`
- WebSocket example: `ws://localhost:8080/ws/price`

---

### mobile (Flutter)
- Root: `mobile/`
- Entry point: `mobile/lib/main.dart` (`mobile/lib/src/app.dart`)
- State management: configured in source code (see `mobile/lib/src/` with services, repositories, models).

#### Run the mobile app
1. Install Flutter dependencies:
   ```bash
   cd mobile
   flutter pub get
   ```
2. Connect a device or open an emulator:
   ```bash
   flutter devices
   flutter run -d <device_id>
   ```
3. Run on web:
   ```bash
   flutter run -d chrome
   ```

#### Build commands
- Android APK: `flutter build apk`
- iOS: `flutter build ios`
- Web: `flutter build web`

#### Tests
- Widget tests:
  ```bash
  flutter test
  ```

---

## 🛠️ How to Develop

1. For a new feature, first add an endpoint in the backend.
2. Match API models and DTOs in `backend/internal/domain/entity` and `mobile/lib/src/domain`.
3. Run backend, then configure mobile client base URL and settings.
4. Code formatting and static checks:
   - Go: `go fmt ./...`, `golangci-lint run`
   - Flutter: `flutter format .`, `flutter analyze`

---

## 🧪 Environment Variables & Configuration Summary

### backend/config/config.yaml (example)
- `server.port`
- `database.url`
- `redis.url`
- `binance.endpoint`

### Mobile config
- Manage API URL via `lib/src/core/constants` or `.env` if present.

---

## 📌 Git Reference for Each Component

- For backend folder, verify remote URL with: `git remote get-url origin`.
- For mobile folder, use same parent repo URL; separate URL is not needed (subfolder).

```
cd backend && git remote get-url origin
cd mobile && git remote get-url origin
```

---

## 💡 Tips

- Inspect `docker-compose.yaml` for dependency services (`redis`, `postgres`, `kafka`).
- After code changes, run `go test ./...` and `flutter test` for regression checks.
- Consider maintaining separate component README files as features are added (`backend/README.md`, `mobile/README.md`).

---

## 🚀 Quick Start

1. Clone your repository.
2. Install dependencies for `backend` and `mobile`.
3. Start backend and test API.
4. Start mobile app and verify data flows in UI.

---

## 📂 File & Path Quick Reference
- `backend/cmd/server/main.go`
- `backend/config/config.yaml`
- `backend/pkg/binance/client.go`
- `mobile/lib/main.dart`
- `mobile/lib/src/app.dart`
- `mobile/pubspec.yaml`

---

## 📣 FAQ
- Is Binance API key required? Yes, for real-time price data.
- Is Redis required? For cache and performance in this architecture, yes (but optional based on local deployment).

