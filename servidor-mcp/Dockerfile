FROM golang:1.23-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -o mcp-server main.go

# Final stage
FROM alpine:latest

WORKDIR /root/

COPY --from=builder /app/mcp-server .

# Expose the SSE port
EXPOSE 3001

CMD ["./mcp-server"]
