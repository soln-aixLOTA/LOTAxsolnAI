# Build Stage
FROM golang:1.20-alpine AS builder

WORKDIR /app

# Copy go.mod and go.sum files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy the source code
COPY . .

# Build the application
RUN go build -o go-app ./cmd

# Runtime Stage
FROM alpine:latest

WORKDIR /root/

# Copy the built binary from the builder stage
COPY --from=builder /app/go-app .

# Set environment variables (can also be passed at runtime)
ENV HUGGINGFACE_API_KEY=""
ENV ERP_API_KEY=""
ENV SPEECH_API_KEY=""

# Expose the application port
EXPOSE 8080

# Command to run the application
CMD ["./go-app"]
