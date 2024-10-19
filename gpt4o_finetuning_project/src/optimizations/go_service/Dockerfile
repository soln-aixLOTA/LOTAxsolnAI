# shellcheck disable=SC2006
# src/optimizations/go_service/Dockerfile

# Dockerfile for Go Service

FROM golang:1.16-alpine

WORKDIR /app

COPY . .

RUN go build -o go_service

EXPOSE 8081

CMD ["./go_service"]
