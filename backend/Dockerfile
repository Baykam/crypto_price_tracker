FROM golang:1.24.5-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-w -s" -o server ./cmd/server

# ── Final image ────────────────────────────────────────────────────────────────
FROM alpine:3.19

# Binance WSS için SSL sertifikası şart
RUN apk --no-cache add ca-certificates tzdata

WORKDIR /app

COPY --from=builder /app/server .
COPY --from=builder /app/config ./config

# Docker container config.docker.yaml kullanır
ENV CONFIG_PATH=config/config.docker.yaml

EXPOSE 8080 9090

CMD ["./server"]