#!/bin/bash

# === Strict Mode ===
set -euo pipefail
IFS=$'\n\t'

# === Variables ===
PROJECT_DIR="gpt4o_finetuning_project"

# === Logging Functions ===
log_info() {
    printf "[%s][\e[32mINFO\e[0m] %s\n" "$(date +"%Y-%m-%d %H:%M:%S")" "$1"
}

log_warn() {
    printf "[%s][\e[33mWARN\e[0m] %s\n" "$(date +"%Y-%m-%d %H:%M:%S")" "$1"
}

log_error() {
    printf "[%s][\e[31mERROR\e[0m] %s\n" "$(date +"%Y-%m-%d %H:%M:%S")" "$1" >&2
}

# === Error Handling ===
error_exit() {
    log_error "$1"
    exit 1
}

# === Dependency Checks ===
check_dependencies() {
    log_info "Checking for required dependencies..."

    declare -A dependencies
    dependencies=(
        [git]="git --version"
        [docker]="docker --version"
        [docker-compose]="docker-compose --version"
        [openssl]="openssl version"
        [python3]="python3 --version"
        [pip3]="pip3 --version"
        [make]="make --version"
    )

    for cmd in "${!dependencies[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            error_exit "$cmd is not installed. Please install it and rerun the script."
        else
            # Capture version information
            version_info=$(${dependencies[$cmd]} 2>/dev/null || echo "Unable to retrieve version.")
            log_info "$cmd is installed: $version_info"
        fi
    done

    log_info "All dependencies are satisfied."
}

# === User Input ===
get_user_input() {
    log_info "Please provide the following details for project setup:"

    # Function to prompt and validate input with optional default
    prompt_input() {
        local var_name=$1
        local prompt_message=$2
        local default_value=$3
        local input=""

        while true; do
            if [[ -n "$default_value" ]]; then
                read -rp "$prompt_message [$default_value]: " input
                input=${input:-$default_value}
            else
                read -rp "$prompt_message: " input
            fi

            if [[ -n "$input" ]]; then
                # Additional validation can be added here
                printf -v "$var_name" '%s' "$input"
                break
            else
                log_warn "Input cannot be empty. Please try again."
            fi
        done
    }

    prompt_input "GITHUB_USERNAME" "GitHub Username" ""
    prompt_input "DOCKERHUB_USERNAME" "Docker Hub Username" ""

    # Prompt for Production URL with enhanced validation
    while true; do
        read -rp "Production URL (e.g., yourdomain.com): " PRODUCTION_URL
        if [[ "$PRODUCTION_URL" =~ ^([a-zA-Z0-9]+(-[a-zA-Z0-9]+)*\.)+[a-zA-Z]{2,}$ ]]; then
            break
        else
            log_warn "Please enter a valid Production URL."
        fi
    done

    # Export variables for envsubst
    export GITHUB_USERNAME
    export DOCKERHUB_USERNAME
    export PRODUCTION_URL
}

# === Directory and File Creation ===
create_directories() {
    log_info "Creating project directories..."

    local dirs=(
        "$PROJECT_DIR/.github/workflows"
        "$PROJECT_DIR/configs"
        "$PROJECT_DIR/data/raw"
        "$PROJECT_DIR/data/processed"
        "$PROJECT_DIR/data/augmented"
        "$PROJECT_DIR/docker/certs"
        "$PROJECT_DIR/docker/nginx"
        "$PROJECT_DIR/docs"
        "$PROJECT_DIR/scripts"
        "$PROJECT_DIR/logs"
        "$PROJECT_DIR/src/api"
        "$PROJECT_DIR/src/data_processing"
        "$PROJECT_DIR/src/models"
        "$PROJECT_DIR/src/optimizations/cython_modules"
        "$PROJECT_DIR/src/optimizations/cpp_modules"
        "$PROJECT_DIR/src/optimizations/go_service"
        "$PROJECT_DIR/src/utils"
        "$PROJECT_DIR/tests"
    )

    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir" && log_info "Created directory: $dir"
        else
            log_warn "Directory already exists: $dir. Skipping."
        fi
    done

    log_info "Project directories created."
}

# Function to create a file if it does not exist, with optional ShellCheck disables
create_file_if_not_exists() {
    local file_path="$1"
    local content="$2"
    local description="$3"
    local sc_disable="${4:-}"  # Set to empty string if $4 is not provided

    if [ ! -f "$file_path" ]; then
        if [ -n "$sc_disable" ]; then
            echo "# shellcheck disable=${sc_disable}" > "$file_path"
        fi
        echo "$content" | envsubst >> "$file_path" && log_info "Created $description: $file_path"
    else
        log_warn "$description already exists: $file_path. Skipping."
    fi
}

# === Root Files Creation ===
create_root_files() {
    log_info "Creating root files..."

    # README.md
    # shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
    README_CONTENT=$(cat <<'EOL'
# README.md

# GPT-4o Fine-Tuning Project

![Build Status](https://github.com/${GITHUB_USERNAME}/gpt4o_finetuning_project/actions/workflows/ci.yml/badge.svg)
![Coverage](https://coveralls.io/repos/github/${GITHUB_USERNAME}/gpt4o_finetuning_project/badge.svg?branch=main)
![Docker Pulls](https://img.shields.io/docker/pulls/${DOCKERHUB_USERNAME}/gpt4o_finetuning_project)
![License](https://img.shields.io/github/license/${GITHUB_USERNAME}/gpt4o_finetuning_project)

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Documentation](#documentation)
- [Quick Start](#quick-start)
- [Usage Instructions](#usage-instructions)
- [Benchmarking Performance](#benchmarking-performance)
- [Architecture Diagram](#architecture-diagram)
- [Contribution Guidelines](#contribution-guidelines)
- [License](#license)

## Overview

This project implements a fine-tuning system for GPT-4o, optimized for performance using multiple programming languages (**Python**, **Cython**, **C++**, and **Go**).

## Features
- **FastAPI** for building a high-performance API.
- **Cython** and **C++ with PyBind11** for accelerating compute-intensive tasks.
- **Go** service for handling concurrent API requests with low latency.
- **Docker Compose** setup for containerization and orchestration.
- **Redis** for caching responses.
- **Prometheus** and **Grafana** for monitoring.
- **Unit and Integration Tests** with `pytest`.
- **CI/CD Pipeline** using GitHub Actions.
- **Rate Limiting** and **JWT Authentication** for security.
- **Automated Rollbacks** and **Deployment Verification**.

## Documentation
- [Setup Guide](docs/setup.md)
- [Usage Instructions](docs/usage.md)
- [Performance Optimization](docs/performance_optimization.md)
- [Contribution Guidelines](CONTRIBUTING.md)
- [Architecture Diagram](docs/architecture_diagram.md)
- [Contribution Examples](docs/contribution_examples.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Glossary](docs/glossary.md)

## Quick Start

1. **Clone the Repository:**

    ```bash
    git clone "https://github.com/${GITHUB_USERNAME}/gpt4o_finetuning_project.git"
    cd gpt4o_finetuning_project
    ```

2. **Set Up Environment Variables:**

    ```bash
    cp .env.example .env
    # Edit the .env file with your configurations
    ```

3. **Build and Run with Docker Compose:**

    ```bash
    make build
    ```

    This will:
    - Build the Python application with Cython and C++ extensions.
    - Start the Go service.
    - Launch Redis, Nginx, Prometheus, and Grafana.
    - Expose the API on port 8000 and Nginx on ports 80 & 443.

4. **Verify Services:**
    - **API Health Check:**
        ```bash
        curl http://localhost:8000/api/health
        ```
    - **Prometheus:** [http://localhost:9090](http://localhost:9090)
    - **Grafana:** [http://localhost:3000](http://localhost:3000) (Default credentials: admin/admin)

5. **Run Tests:**

    ```bash
    make test
    ```

6. **Benchmark Performance:**

    ```bash
    make benchmark
    ```

## Additional Setup

- **Logging:**
    Logs are stored in the `logs/` directory. Ensure appropriate permissions are set.

- **SSL Certificates:**
    SSL certificates are located in `docker/certs/`. For production, replace self-signed certificates with those from a trusted Certificate Authority (CA).

- **Database Setup (Optional):**
    If integrating a database, ensure it's properly configured and services are updated accordingly.

---
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/README.md" "$README_CONTENT" "README.md" "SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296"

    # CONTRIBUTING.md
    # shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
    CONTRIBUTING_CONTENT=$(cat <<'EOL'
# CONTRIBUTING.md

# Contribution Guidelines

Thank you for considering contributing to the GPT-4o Fine-Tuning Project! We welcome contributions of all kinds. To ensure a smooth process, please follow these guidelines.

## How to Contribute

1. **Fork the Repository:**
   - Click the "Fork" button at the top-right of the repository page.

2. **Clone Your Fork:**

    ```bash
    git clone "https://github.com/${GITHUB_USERNAME}/gpt4o_finetuning_project.git"
    cd gpt4o_finetuning_project
    ```

3. **Create a New Branch:**

    ```bash
    git checkout -b feature/your-feature-name
    ```

4. **Make Your Changes:**
   - Implement your feature or fix.

5. **Run Tests:**

    ```bash
    make test
    ```

6. **Commit Your Changes:**

    ```bash
    git commit -m "Add feature: your feature description"
    ```

7. **Push to Your Fork:**

    ```bash
    git push origin feature/your-feature-name
    ```

8. **Create a Pull Request:**
   - Navigate to your forked repository on GitHub.
   - Click on "Compare & pull request" for the `feature/your-feature-name` branch.
   - Provide a descriptive title and description for your PR.
   - Submit the pull request for review.

## Code of Conduct

Please adhere to our [Code of Conduct](CODE_OF_CONDUCT.md) in all interactions with the project.

## Reporting Issues

If you encounter any issues or have suggestions for improvements, please open an issue in the [Issues](https://github.com/${GITHUB_USERNAME}/gpt4o_finetuning_project/issues) section.
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/CONTRIBUTING.md" "$CONTRIBUTING_CONTENT" "CONTRIBUTING.md" "SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296"

    # CODE_OF_CONDUCT.md
    # shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
    CODE_OF_CONDUCT_CONTENT=$(cat <<'EOL'
# CODE_OF_CONDUCT.md

# Code of Conduct

## Our Pledge

We as members, contributors, and leaders pledge to make participation in our community a harassment-free experience for everyone, regardless of age, body size, disability, ethnicity, gender identity and expression, level of experience, nationality, personal appearance, race, religion, or sexual identity and orientation.

## Our Standards

Examples of behavior that contributes to creating a positive environment include:
- Using welcoming and inclusive language
- Being respectful of differing viewpoints and experiences
- Gracefully accepting constructive criticism
- Focusing on what is best for the community

Examples of unacceptable behavior include:
- The use of sexualized language or imagery
- Personal attacks
- Trolling or insulting comments
- Public or private harassment

## Enforcement Responsibilities

Community leaders are responsible for clarifying and enforcing our standards of acceptable behavior and will take appropriate and fair corrective action in response to any behavior that violates these standards.

## Enforcement Guidelines

1. **Correction:** Community leaders will privately reach out to the offender to correct inappropriate behavior.
2. **Warning:** Community leaders may issue a warning to offenders who exhibit unacceptable behavior.
3. **Temporary Ban:** Community leaders may temporarily ban offenders from the community for a period of time.
4. **Permanent Ban:** Community leaders may permanently ban offenders from the community if they continue to violate community standards.

## Attribution

This Code of Conduct is adapted from the [Contributor Covenant][homepage], version 2.0, available at https://www.contributor-covenant.org/version/2/0/code_of_conduct.html

[homepage]: https://www.contributor-covenant.org
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/CODE_OF_CONDUCT.md" "$CODE_OF_CONDUCT_CONTENT" "CODE_OF_CONDUCT.md" "SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296"

    # .gitignore
    # shellcheck disable=SC2006
    GITIGNORE_CONTENT=$(cat <<'EOL'
# .gitignore

# Python cache
__pycache__/
*.pyc
*.pyo
*.pyd

# Cython build files
*.so
*.c
*.cpp

# Git files
.git
.gitignore

# Logs
logs/
*.log

# Docker files
docker-compose.yml
Dockerfile

# Environment variables
.env
.env.*

# Coverage reports
htmlcov/
.coverage
.coverage.*
.nosetests.xml
coverage.xml
*.cover
*.py,cover

# Virtual environments
venv/
ENV/
env/

# Node modules (if any)
node_modules/

# Build directories
build/
dist/
*.egg-info/
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/.gitignore" "$GITIGNORE_CONTENT" ".gitignore"

    # LICENSE
    # shellcheck disable=SC2006
    LICENSE_CONTENT=$(cat <<'EOL'
# LICENSE

MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/LICENSE" "$LICENSE_CONTENT" "LICENSE"

    log_info "Root files creation completed."
}

# === Makefile Creation ===
create_makefile() {
    log_info "Creating Makefile..."

    # shellcheck disable=SC2006
    MAKEFILE_CONTENT=$(cat <<'EOL'
# Makefile

.PHONY: setup build test docker benchmark clean lint

setup:
	./scripts/setup_project.sh

build:
	docker-compose -f docker/docker-compose.yml up --build -d

test:
	docker exec -it gpt4o_finetuning_project_app pytest

docker:
	docker build -t "${DOCKERHUB_USERNAME}/gpt4o_finetuning_project:latest" .

benchmark:
	python3 scripts/benchmark_performance.py --n 1000 --iterations 10000

clean:
	docker-compose -f docker/docker-compose.yml down --rmi all --volumes --remove-orphans
	rm -rf build/ dist/ *.egg-info
	find . -type d -name "__pycache__" -exec rm -r {} +
	find . -type f -name "*.pyc" -delete

lint:
	pip3 install flake8 black bandit
	flake8 src/ tests/
	black --check src/ tests/
	bandit -r src/
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/Makefile" "$MAKEFILE_CONTENT" "Makefile" "SC2006"

    log_info "Makefile creation completed."
}

# === Environment Variable Example Creation ===
create_env_example() {
    log_info "Creating .env.example..."

    # shellcheck disable=SC2006
    ENV_EXAMPLE_CONTENT=$(cat <<'EOL'
# .env.example

# OpenAI API Key
OPENAI_API_KEY=your_openai_api_key

# JWT Secret
JWT_SECRET=your_jwt_secret

# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379

# Redis Cache TTL (in seconds)
REDIS_TTL=3600

# Database URL (if applicable)
DATABASE_URL=sqlite+aiosqlite:///./test.db

# Logging Levels
LOG_LEVEL_CONSOLE=INFO
LOG_LEVEL_FILE=DEBUG
LOG_LEVEL_SRC=DEBUG
LOG_LEVEL_ROOT=WARNING

# Prometheus Configuration
PROMETHEUS_PORT=9090

# Grafana Configuration
GRAFANA_PORT=3000

# JWT Token for Testing (Replace with actual token generation in production)
TEST_JWT_TOKEN=your_jwt_token

# Vault Configuration
VAULT_URL=http://localhost:8200
VAULT_TOKEN=your_vault_token
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/.env.example" "$ENV_EXAMPLE_CONTENT" ".env.example"

    log_info ".env.example creation completed."
}

# === Configuration Files Creation ===
create_config_files() {
    log_info "Creating configuration files..."

    # configs/hyperparams.yaml
    # shellcheck disable=SC2006
    HYPERPARAMS_CONTENT=$(cat <<'EOL'
# configs/hyperparams.yaml

model:
  name: "gpt-4o"
  version: "1.0"

training:
  epochs: 10
  batch_size: 32
  learning_rate: 0.001
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/configs/hyperparams.yaml" "$HYPERPARAMS_CONTENT" "configs/hyperparams.yaml"

    # configs/logging.yaml
    LOGGING_CONTENT=$(cat <<'EOL'
# configs/logging.yaml

version: 1
formatters:
  json:
    format: '{"time": "%(asctime)s", "name": "%(name)s", "level": "%(levelname)s", "message": "%(message)s"}'
handlers:
  console:
    class: logging.StreamHandler
    formatter: json
    level: ${LOG_LEVEL_CONSOLE:INFO}
  file:
    class: logging.FileHandler
    formatter: json
    level: ${LOG_LEVEL_FILE:DEBUG}
    filename: logs/app.log
loggers:
  src:
    level: ${LOG_LEVEL_SRC:DEBUG}
    handlers: [console, file]
    propagate: no
root:
  level: ${LOG_LEVEL_ROOT:WARNING}
  handlers: [console]
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/configs/logging.yaml" "$LOGGING_CONTENT" "configs/logging.yaml"

    # configs/prometheus.yml
    PROMETHEUS_CONTENT=$(cat <<'EOL'
# configs/prometheus.yml

global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'app'
    metrics_path: '/metrics'
    static_configs:
      - targets: ['app:8000']

  - job_name: 'go_service'
    metrics_path: '/metrics'
    static_configs:
      - targets: ['go_service:8081']

  - job_name: 'redis'
    metrics_path: '/metrics'
    static_configs:
      - targets: ['redis:6379']
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/configs/prometheus.yml" "$PROMETHEUS_CONTENT" "configs/prometheus.yml"

    # configs/prometheus_alerts.yml
    PROMETHEUS_ALERTS_CONTENT=$(cat <<'EOL'
# configs/prometheus_alerts.yml

groups:
  - name: example
    rules:
      - alert: HighCPUUsage
        expr: rate(container_cpu_usage_seconds_total{container="app"}[1m]) > 0.9
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "High CPU usage detected on app"
          description: "CPU usage is above 90% for more than 2 minutes."
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/configs/prometheus_alerts.yml" "$PROMETHEUS_ALERTS_CONTENT" "configs/prometheus_alerts.yml"

    log_info "Configuration files creation completed."
}

# === Docker Files Creation ===
create_docker_files() {
    log_info "Creating Docker files..."

    # docker/Dockerfile
    # shellcheck disable=SC2006
    DOCKERFILE_CONTENT=$(cat <<'EOL'
# docker/Dockerfile

# Stage 1: Build Cython and C++ modules
FROM python:3.9-slim as builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    gcc \
    g++ \
    libboost-all-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip3 install --upgrade pip
RUN pip3 install cython pybind11

# Copy source code and build extensions
COPY src/ /app/src/
COPY setup.py /app/

RUN python3 setup.py build_ext --inplace

# Stage 2: Final image
FROM python:3.9-slim

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Create logs directory
RUN mkdir -p logs && chmod -R 755 logs

# Create a non-root user
RUN addgroup --system appgroup && adduser --system appuser --ingroup appgroup

# Copy built extensions and source code from builder
COPY --from=builder /app /app

# Install remaining dependencies
RUN pip3 install --no-cache-dir -r requirements.txt

# Change to non-root user
USER appuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8000/api/health || exit 1

# Command to run the application
CMD ["uvicorn", "src.api.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/docker/Dockerfile" "$DOCKERFILE_CONTENT" "docker/Dockerfile" "SC2006"

    # docker/.dockerignore
    # shellcheck disable=SC2006
    DOCKERIGNORE_CONTENT=$(cat <<'EOL'
# docker/.dockerignore

# Python cache
__pycache__/
*.pyc
*.pyo
*.pyd

# Cython build files
*.so
*.c
*.cpp

# Git files
.git
.gitignore

# Logs
../logs/
*.log

# Docker files
docker-compose.yml
Dockerfile

# Environment variables
../.env
../.env.*

# Coverage reports
htmlcov/
.coverage
.coverage.*
.nosetests.xml
coverage.xml
*.cover
*.py,cover

# Virtual environments
venv/
ENV/
env/

# Node modules (if any)
node_modules/

# Build directories
build/
dist/
*.egg-info/
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/docker/.dockerignore" "$DOCKERIGNORE_CONTENT" "docker/.dockerignore"

    # docker/nginx.conf
    # shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
    NGINX_CONF_CONTENT=$(cat <<'EOL'
# docker/nginx.conf

events {}

http {
    upstream app_servers {
        server app:8000;
    }

    upstream go_service_servers {
        server go_service:8081;
    }

    server {
        listen 80;
        server_name "${PRODUCTION_URL}";

        # Redirect HTTP to HTTPS
        location / {
            return 301 https://$host$request_uri;
        }
    }

    server {
        listen 443 ssl;
        server_name "${PRODUCTION_URL}";

        ssl_certificate /etc/nginx/certs/fullchain.pem;
        ssl_certificate_key /etc/nginx/certs/privkey.pem;

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers on;
        ssl_ciphers HIGH:!aNULL:!MD5;

        # Enable HSTS
        add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;

        location /api/ {
            proxy_pass http://app_servers/api/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        location /go-chat {
            proxy_pass http://go_service_servers/go-chat;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Health Check Endpoint
        location /health {
            proxy_pass http://app_servers/api/health;
        }
    }
}
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/docker/nginx.conf" "$NGINX_CONF_CONTENT" "docker/nginx.conf" "SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296"

    # docker/docker-compose.yml
    # shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
    DOCKER_COMPOSE_CONTENT=$(cat <<'EOL'
# docker/docker-compose.yml

version: '3.8'

services:
  app:
    build:
      context: ..
      dockerfile: docker/Dockerfile
    container_name: gpt4o_finetuning_project_app
    restart: always
    environment:
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - JWT_SECRET=${JWT_SECRET}
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - REDIS_TTL=${REDIS_TTL}
      - LOG_LEVEL_CONSOLE=${LOG_LEVEL_CONSOLE}
      - LOG_LEVEL_FILE=${LOG_LEVEL_FILE}
      - LOG_LEVEL_SRC=${LOG_LEVEL_SRC}
      - LOG_LEVEL_ROOT=${LOG_LEVEL_ROOT}
      - DATABASE_URL=${DATABASE_URL}
    depends_on:
      - redis
    networks:
      - app-network
    volumes:
      - ./logs:/app/logs

  go_service:
    build:
      context: src/optimizations/go_service
      dockerfile: Dockerfile
    container_name: gpt4o_finetuning_project_go_service
    restart: always
    ports:
      - "8081:8081"
    networks:
      - app-network
    volumes:
      - ./logs:/app/logs

  redis:
    image: "redis:alpine"
    container_name: gpt4o_finetuning_project_redis
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    networks:
      - app-network
    command: ["redis-server", "--appendonly", "yes"]

  nginx:
    image: "nginx:alpine"
    container_name: gpt4o_finetuning_project_nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./certs:/etc/nginx/certs
    depends_on:
      - app
      - go_service
    networks:
      - app-network

  prometheus:
    image: "prom/prometheus:latest"
    container_name: gpt4o_finetuning_project_prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - ./prometheus_alerts.yml:/etc/prometheus/prometheus_alerts.yml
    ports:
      - "9090:9090"
    networks:
      - app-network

  grafana:
    image: "grafana/grafana:latest"
    container_name: gpt4o_finetuning_project_grafana
    ports:
      - "3000:3000"
    depends_on:
      - prometheus
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    networks:
      - app-network

networks:
  app-network:
    driver: bridge

volumes:
  redis-data:
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/docker/docker-compose.yml" "$DOCKER_COMPOSE_CONTENT" "docker/docker-compose.yml" "SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296"

    log_info "Docker files creation completed."
}

# === Documentation Files Creation ===
create_documentation_files() {
    log_info "Creating documentation files..."

    # docs/setup.md
    # shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
    SETUP_MD_CONTENT=$(cat <<'EOL'
# docs/setup.md

# Setup Guide

## Prerequisites

- **Docker & Docker Compose:** Ensure Docker and Docker Compose are installed on your system.
- **Git:** To clone the repository.
- **Python 3.9+, pip3:** For local development (optional if using Docker).

## Steps

1. **Clone the Repository:**

    ```bash
    git clone "https://github.com/${GITHUB_USERNAME}/gpt4o_finetuning_project.git"
    cd gpt4o_finetuning_project
    ```

2. **Set Up Environment Variables:**

    ```bash
    cp .env.example .env
    # Edit the .env file with your configurations
    ```

3. **Build and Run with Docker Compose:**

    ```bash
    make build
    ```

    This will:
    - Build the Python application with Cython and C++ extensions.
    - Start the Go service.
    - Launch Redis, Nginx, Prometheus, and Grafana.
    - Expose the API on port 8000 and Nginx on ports 80 & 443.

4. **Verify Services:**
    - **API Health Check:**
        ```bash
        curl http://localhost:8000/api/health
        ```
    - **Prometheus:** [http://localhost:9090](http://localhost:9090)
    - **Grafana:** [http://localhost:3000](http://localhost:3000) (Default credentials: admin/admin)

5. **Run Tests:**

    ```bash
    make test
    ```

6. **Benchmark Performance:**

    ```bash
    make benchmark
    ```

## Additional Setup

- **Logging:**
    Logs are stored in the `logs/` directory. Ensure appropriate permissions are set.

- **SSL Certificates:**
    SSL certificates are located in `docker/certs/`. For production, replace self-signed certificates with those from a trusted Certificate Authority (CA).

- **Database Setup (Optional):**
    If integrating a database, ensure it's properly configured and services are updated accordingly.

---
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/docs/setup.md" "$SETUP_MD_CONTENT" "docs/setup.md" "SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296"

    # docs/usage.md
    # shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
    USAGE_MD_CONTENT=$(cat <<'EOL'
# docs/usage.md

# Usage Instructions

This guide explains how to use the GPT-4o Fine-Tuning Project.

## API Endpoints

- **GET /api/health**

  Health check endpoint.

- **POST /api/fine-tune**

  Endpoint to fine-tune the GPT-4o model.

- **POST /api/predict**

  Endpoint to get predictions from the fine-tuned model.

- **GET /api/status**

  Retrieves the status of a specific fine-tuning job.

## Authentication

All endpoints require JWT authentication. Include the JWT token in the `Authorization` header:

```
Authorization: Bearer your_jwt_token
```

## Example Requests

- **Fine-Tuning the Model:**

  ```bash
  curl -X POST "http://localhost:8000/api/fine-tune" \
       -H "Authorization: Bearer your_jwt_token" \
       -H "Content-Type: application/json" \
       -d '{"training_file_id": "file-12345"}'
  ```

- **Getting Predictions:**

  ```bash
  curl -X POST "http://localhost:8000/api/predict" \
       -H "Authorization: Bearer your_jwt_token" \
       -H "Content-Type: application/json" \
       -d '{"text": "Your input text here"}'
  ```

- **Checking Fine-Tuning Job Status:**

  ```bash
  curl -X GET "http://localhost:8000/api/status?fine_tune_id=ft-12345" \
       -H "Authorization: Bearer your_jwt_token"
  ```

---
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/docs/usage.md" "$USAGE_MD_CONTENT" "docs/usage.md" "SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296"

    # docs/performance_optimization.md
    # shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
    PERFORMANCE_OPT_CONTENT=$(cat <<'EOL'
# docs/performance_optimization.md

# Performance Optimization

## Cython Modules

- Located in `src/optimizations/cython_modules`.
- Compiled for faster execution of critical sections.
- Example: `math_operations.pyx` leverages C++ functions for performance.

## C++ Extensions

- Located in `src/optimizations/cpp_modules`.
- Use PyBind11 for seamless integration with Python.
- Example: `math_operations.cpp` provides high-performance functions like `reverse_string`.

## Go Service

- Located in `src/optimizations/go_service`.
- Handles concurrent requests efficiently.
- Optimized for low latency and high throughput.

## Benchmarking

Use the benchmarking script to compare performance:

```bash
make benchmark
```

*(Note: Adjust `--n` and `--iterations` based on your requirements.)*

## Optimizing Model Performance

- **Batch Processing:** Implement batch processing in the prediction endpoint to handle multiple requests simultaneously.
- **Caching:** Utilize Redis to cache frequent predictions, reducing latency and API calls.
- **Asynchronous Programming:** Use asynchronous programming paradigms in FastAPI and Go to handle I/O-bound tasks efficiently.

---
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/docs/performance_optimization.md" "$PERFORMANCE_OPT_CONTENT" "docs/performance_optimization.md" "SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296"

    # docs/troubleshooting.md
    # shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
    TROUBLESHOOTING_MD_CONTENT=$(cat <<'EOL'
# docs/troubleshooting.md

# Troubleshooting

This section provides solutions to common issues encountered while setting up or using the GPT-4 Fine-Tuning Project.

## Common Issues

### 1. Fine-Tuning Job Fails

**Symptoms:**
- Fine-tuning job status changes to `failed`.
- Error messages in the logs indicating invalid training data.

**Solutions:**
- **Check Training Data Format:** Ensure your training data is in the correct JSONL format.
- **Review Error Logs:** Access the fine-tuning job logs via OpenAI's dashboard to identify specific errors.
- **Validate JSONL File:** Use a JSON validator to ensure there are no syntax errors in your training data.

### 2. API Returns 401 Unauthorized

**Symptoms:**
- Accessing protected endpoints without a valid JWT token.

**Solutions:**
- **Ensure Token is Included:** Include the `Authorization: Bearer <your_jwt_token>` header in your requests.
- **Validate Token:** Ensure that the JWT token is correctly generated and not expired.
- **Check Secret Key:** Verify that the `JWT_SECRET` is correctly set in your environment variables and matches the one used to generate the tokens.

### 3. SSL Certificate Errors

**Symptoms:**
- Browser warnings about insecure connections.
- API requests failing due to SSL verification errors.

**Solutions:**
- **Use Trusted Certificates:** Ensure that you're using SSL certificates from a trusted CA in production.
- **Certificate Paths:** Verify that the SSL certificate paths in `nginx.conf` are correct.
- **Renew Certificates:** If using Let's Encrypt, ensure that your certificates are renewed before expiration.

### 4. Dependency Issues

**Symptoms:**
- Errors during installation of Python packages or building C++/Cython modules.

**Solutions:**
- **Check Requirements:** Ensure all dependencies listed in `requirements.txt` are correctly installed.
- **C++ Compiler:** Verify that a C++ compiler is installed on your system for building extensions.
- **PyBind11:** Ensure that `pybind11` is installed and correctly referenced in `setup.py`.

## Getting Further Help

If you encounter issues not covered in this guide:

1. **Check the GitHub Issues:** Search for similar problems in the [Issues](https://github.com/${GITHUB_USERNAME}/gpt4o_finetuning_project/issues) section.
2. **Open a New Issue:** Provide detailed information about the problem, including error messages and steps to reproduce.
3. **Contact Maintainers:** Reach out to project maintainers or contributors for assistance.

---
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/docs/troubleshooting.md" "$TROUBLESHOOTING_MD_CONTENT" "docs/troubleshooting.md" "SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296"

    # docs/architecture_diagram.md
    # shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
    ARCHITECTURE_DIAGRAM_CONTENT=$(cat <<'EOL'
# docs/architecture_diagram.md

# Architecture Diagram

![Architecture Diagram](architecture_diagram.png)

## Components Overview

1. **API Server (FastAPI):**
   - Handles incoming requests for fine-tuning and predictions.
   - Secured with JWT authentication.
   - Utilizes Cython and C++ extensions for performance-critical tasks.

2. **Go Service:**
   - Manages concurrent API requests.
   - Provides low-latency responses.

3. **Redis:**
   - Caches frequent predictions to reduce API calls and improve response times.

4. **Nginx:**
   - Acts as a reverse proxy.
   - Manages SSL termination for HTTPS connections.

5. **Prometheus & Grafana:**
   - Prometheus collects metrics from various services.
   - Grafana visualizes these metrics for monitoring and analysis.

6. **GitHub Actions (CI/CD Pipeline):**
   - Automates testing, linting, formatting, and security scans on each push or pull request.

## Data Flow

1. **Fine-Tuning:**
   - User uploads training data via the API.
   - The system uploads the data to OpenAI and initiates a fine-tuning job.
   - Once fine-tuned, the model is ready to generate predictions.

2. **Prediction:**
   - User sends a prediction request to the API.
   - If the prediction is cached in Redis, it returns immediately.
   - Otherwise, it processes the prediction using the fine-tuned model and caches the result.

3. **Monitoring:**
   - All services emit metrics to Prometheus.
   - Grafana dashboards visualize these metrics for real-time monitoring.

---
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/docs/architecture_diagram.md" "$ARCHITECTURE_DIAGRAM_CONTENT" "docs/architecture_diagram.md" "SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296"

    # docs/contribution_examples.md
    # shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
    CONTRIBUTION_EXAMPLES_CONTENT=$(cat <<'EOL'
# docs/contribution_examples.md

# Contribution Examples

This section provides examples to guide contributors in implementing features or fixes within the GPT-4 Fine-Tuning Project.

## Example 1: Adding a New API Endpoint

### Scenario:

Add a new endpoint `/api/status` that returns the current status of the fine-tuning job.

### Steps:

1. **Update API Routes:**

   **File:** `src/api/main.py`

   ```python
   @app.get("/api/status")
   async def get_status(fine_tune_id: str, current_user: str = Depends(get_current_user)):
       """
       Retrieves the status of a specific fine-tuning job.
       """
       status_response = model.get_fine_tune_status(fine_tune_id)
       return {"fine_tune_id": fine_tune_id, "status": status_response['status']}
   ```

2. **Update Tests:**

   **File:** `tests/test_api.py`

   ```python
   def test_get_status():
       # Mocking the get_fine_tune_status method
       with patch.object(GPT4oModel, 'get_fine_tune_status', return_value={'status': 'succeeded'}):
           response = client.get(
               "/api/status",
               headers={"Authorization": "Bearer your_jwt_token"},
               params={"fine_tune_id": "ft-12345"}
           )
           assert response.status_code == 200
           assert response.json() == {"fine_tune_id": "ft-12345", "status": "succeeded"}
   ```

3. **Update Documentation:**

   **File:** `docs/usage.md`

   ```markdown
   ## API Endpoints

   - **GET /api/status**
   
     Retrieves the status of a specific fine-tuning job.
   
     **Parameters:**
     - `fine_tune_id` (query): The ID of the fine-tuning job.
   
     **Example Request:**
   
     ```bash
     curl -X GET "http://localhost:8000/api/status?fine_tune_id=ft-12345" \
          -H "Authorization: Bearer your_jwt_token"
     ```
   
     **Example Response:**
   
     ```json
     {
       "fine_tune_id": "ft-12345",
       "status": "succeeded"
     }
     ```
   ```

4. **Commit and Push Changes:**

    ```bash
    git add src/api/main.py tests/test_api.py docs/usage.md
    git commit -m "Add /api/status endpoint to retrieve fine-tuning job status"
    git push origin feature/add-status-endpoint
    ```

5. **Create Pull Request:**
   - Navigate to your forked repository on GitHub.
   - Click on "Compare & pull request" for the `feature/add-status-endpoint` branch.
   - Provide a descriptive title and description for your PR.
   - Submit the pull request for review.

**Result:**

A new API endpoint `/api/status` is available, allowing users to check the status of their fine-tuning jobs. Comprehensive tests and documentation ensure reliability and ease of use.

---
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/docs/contribution_examples.md" "$CONTRIBUTION_EXAMPLES_CONTENT" "docs/contribution_examples.md" "SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296"

    # docs/glossary.md
    # shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
    GLOSSARY_CONTENT=$(cat <<'EOL'
# docs/glossary.md

# Glossary

- **API (Application Programming Interface):** A set of rules and protocols for building and interacting with software applications.
- **Cython:** A superset of Python that additionally supports calling C functions and declaring C types, aimed at increasing execution speed.
- **PyBind11:** A lightweight header-only library that exposes C++ types in Python and vice versa, mainly to create Python bindings of existing C++ code.
- **FastAPI:** A modern, fast (high-performance) web framework for building APIs with Python 3.6+ based on standard Python type hints.
- **Go (Golang):** A statically typed, compiled programming language designed at Google known for its simplicity and efficiency in handling concurrent tasks.
- **Redis:** An in-memory data structure store, used as a database, cache, and message broker.
- **Prometheus:** An open-source systems monitoring and alerting toolkit.
- **Grafana:** An open-source platform for monitoring and observability, providing visualization and analytics.
- **JWT (JSON Web Token):** A compact, URL-safe means of representing claims to be transferred between two parties.
- **CI/CD (Continuous Integration/Continuous Deployment):** Practices that enable development teams to deliver code changes more frequently and reliably.
- **Docker Compose:** A tool for defining and running multi-container Docker applications.
- **SSL (Secure Sockets Layer):** A standard security technology for establishing an encrypted link between a server and a client.

---
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/docs/glossary.md" "$GLOSSARY_CONTENT" "docs/glossary.md" "SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296"

    log_info "Documentation files creation completed."
}

# === Script Files Creation ===
create_script_files() {
    log_info "Creating script files..."

    # scripts/setup_project.sh
    # shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
    SETUP_PROJECT_SCRIPT_CONTENT=$(cat <<'EOL'
#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -euo pipefail
IFS=$'\n\t'

# Function to display error messages
error_exit() {
    log_error "$1"
    exit 1
}

# Logging functions
log_info() {
    printf "[%s][\e[32mINFO\e[0m] %s\n" "$(date +"%Y-%m-%d %H:%M:%S")" "$1"
}

log_warn() {
    printf "[%s][\e[33mWARN\e[0m] %s\n" "$(date +"%Y-%m-%d %H:%M:%S")" "$1"
}

log_error() {
    printf "[%s][\e[31mERROR\e[0m] %s\n" "$(date +"%Y-%m-%d %H:%M:%S")" "$1" >&2
}

# Check if requirements.txt exists
if [ ! -f "requirements.txt" ]; then
    error_exit "requirements.txt not found. Please ensure it exists in the project root."
fi

# Check if bc is installed
if ! command -v bc &> /dev/null; then
    error_exit "bc is not installed. Please install it and rerun the script."
fi

# Check Python version
PYTHON_VERSION=$(python3 --version | awk '{print $2}')
if [[ "$(echo "$PYTHON_VERSION < 3.9" | bc -l)" -eq 1 ]]; then
    error_exit "Python 3.9 or higher is required. Current version: $PYTHON_VERSION"
fi

# Install Python dependencies
log_info "Installing Python dependencies..."
pip3 install --upgrade pip
pip3 install -r requirements.txt || error_exit "Failed to install Python dependencies."

# Build Cython and C++ extensions
log_info "Building Cython and C++ extensions..."
python3 setup.py build_ext --inplace || error_exit "Failed to build Cython/C++ extensions."

# Install testing dependencies
log_info "Installing testing dependencies..."
pip3 install pytest flake8 black bandit python-jose[cryptography] hvac || error_exit "Failed to install testing dependencies."

# Apply database migrations (if any)
# Uncomment the following lines if using Alembic for migrations
# pip3 install alembic
# alembic upgrade head

log_info "Project setup completed successfully."
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/scripts/setup_project.sh" "$SETUP_PROJECT_SCRIPT_CONTENT" "scripts/setup_project.sh" "SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296"
    chmod +x "$PROJECT_DIR/scripts/setup_project.sh"

    # scripts/benchmark_performance.py
    # shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
    BENCHMARK_PERFORMANCE_CONTENT=$(cat <<'EOL'
import argparse
import time
from src.models.model import GPT4oModel

def benchmark(n, iterations):
    model = GPT4oModel()
    start_time = time.time()
    for _ in range(iterations):
        model.predict("Sample input")
    end_time = time.time()
    total_time = end_time - start_time
    print(f"Total time for {iterations} predictions: {total_time} seconds")
    print(f"Average time per prediction: {total_time / iterations:.6f} seconds")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Benchmark Performance")
    parser.add_argument("--n", type=int, default=1000, help="Number of predictions")
    parser.add_argument("--iterations", type=int, default=10000, help="Number of iterations")
    args = parser.parse_args()
    benchmark(args.n, args.iterations)
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/scripts/benchmark_performance.py" "$BENCHMARK_PERFORMANCE_CONTENT" "scripts/benchmark_performance.py" "SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296"

    # scripts/generate_jwt.py
    # shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
    GENERATE_JWT_CONTENT=$(cat <<'EOL'
from jose import jwt
import os
from datetime import datetime, timedelta
import argparse

# Configuration
SECRET_KEY = os.getenv("JWT_SECRET", "your_jwt_secret")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def main():
    parser = argparse.ArgumentParser(description="Generate JWT Token")
    parser.add_argument("--sub", type=str, required=True, help="Subject (e.g., user ID)")
    parser.add_argument("--expires_minutes", type=int, default=30, help="Token expiration time in minutes")
    args = parser.parse_args()

    data = {"sub": args.sub}
    expires = timedelta(minutes=args.expires_minutes)
    token = create_access_token(data, expires_delta=expires)
    print(f"JWT Token: {token}")

if __name__ == "__main__":
    main()
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/scripts/generate_jwt.py" "$GENERATE_JWT_CONTENT" "scripts/generate_jwt.py" "SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296"
    chmod +x "$PROJECT_DIR/scripts/generate_jwt.py"

    # scripts/benchmark_math_operations.py
    # shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
    BENCHMARK_MATH_OPERATIONS_CONTENT=$(cat <<'EOL'
import time
from src.optimizations.cython_modules.math_operations import cython_reverse_string

def pure_python_reverse(input_str):
    return input_str[::-1]

def benchmark():
    test_string = "A" * 1000000  # 1,000,000 characters

    start_time = time.time()
    pure_result = pure_python_reverse(test_string)
    pure_duration = time.time() - start_time
    print(f"Pure Python Reverse: Completed in {pure_duration:.4f} seconds")

    start_time = time.time()
    cython_result = cython_reverse_string(test_string)
    cython_duration = time.time() - start_time
    print(f"Cython-Optimized Reverse: Completed in {cython_duration:.4f} seconds")

    improvement = pure_duration / cython_duration
    print(f"Performance Improvement: {improvement:.2f}x faster")

if __name__ == "__main__":
    benchmark()
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/scripts/benchmark_math_operations.py" "$BENCHMARK_MATH_OPERATIONS_CONTENT" "scripts/benchmark_math_operations.py" "SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296"

    log_info "Script files creation completed."
}

# === Source Files Creation ===
create_source_files() {
    log_info "Creating source files..."

    # src/api/main.py
    # shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
    MAIN_API_CONTENT=$(cat <<'EOL'
from fastapi import FastAPI, Depends, HTTPException
from src.models.model import GPT4oModel
from src.utils.auth import get_current_user
import asyncio

app = FastAPI()
model = GPT4oModel()

@app.get("/api/health")
async def health_check():
    return {"status": "healthy"}

@app.post("/api/fine-tune")
async def fine_tune(training_data: dict, current_user: str = Depends(get_current_user)):
    # Fine-tuning logic
    fine_tune_id = model.fine_tune(training_data['training_file_id'])
    return {"status": "Model fine-tuned", "fine_tune_id": fine_tune_id}

@app.post("/api/predict")
async def predict(input_data: dict, current_user: str = Depends(get_current_user)):
    if "text" not in input_data:
        raise HTTPException(status_code=400, detail="Input data must contain 'text' field.")
    # Prediction logic
    prediction = await asyncio.get_event_loop().run_in_executor(None, model.predict, input_data["text"], "davinci-finetuned-xyz")
    return {"prediction": prediction}

@app.get("/api/status")
async def get_status(fine_tune_id: str, current_user: str = Depends(get_current_user)):
    """
    Retrieves the status of a specific fine-tuning job.
    """
    status_response = model.get_fine_tune_status(fine_tune_id)
    return {"fine_tune_id": fine_tune_id, "status": status_response['status']}
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/src/api/main.py" "$MAIN_API_CONTENT" "src/api/main.py" "SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296"

    # src/models/model.py
    # shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
    MODEL_CONTENT=$(cat <<'EOL'
import openai
import os
from typing import Optional, Dict, Any
import time

class GPT4oModel:
    def __init__(self):
        # Initialize the model with OpenAI API key
        self.api_key = os.getenv("OPENAI_API_KEY")
        if not self.api_key:
            raise ValueError("OPENAI_API_KEY is not set in environment variables.")
        openai.api_key = self.api_key

    def upload_training_file(self, file_path: str, purpose: str = "fine-tune") -> str:
        """
        Uploads a training file to OpenAI.
        :param file_path: Path to the training JSONL file.
        :param purpose: The purpose of the file upload. Default is 'fine-tune'.
        :return: The file ID.
        """
        try:
            response = openai.File.create(
                file=open(file_path, "rb"),
                purpose=purpose
            )
            file_id = response['id']
            print(f"Training file uploaded. File ID: {file_id}")
            return file_id
        except Exception as e:
            print(f"Error uploading training file: {e}")
            raise

    def fine_tune(self, training_file_id: str, model_name: str = "davinci") -> str:
        """
        Initiates a fine-tuning job.
        :param training_file_id: The ID of the uploaded training file.
        :param model_name: The base model to fine-tune.
        :return: The Fine-tune ID.
        """
        try:
            response = openai.FineTune.create(
                training_file=training_file_id,
                model=model_name,
                n_epochs=4,
                batch_size=8,
                learning_rate_multiplier=0.1,
                prompt_loss_weight=0.01,
                compute_classification_metrics=False
            )
            fine_tune_id = response['id']
            print(f"Fine-tuning initiated. Fine-tune ID: {fine_tune_id}")
            return fine_tune_id
        except Exception as e:
            print(f"Error initiating fine-tuning: {e}")
            raise

    def get_fine_tune_status(self, fine_tune_id: str) -> Dict[str, Any]:
        """
        Retrieves the status of a fine-tuning job.
        :param fine_tune_id: The ID of the fine-tuning job.
        :return: A dictionary containing the fine-tuning status.
        """
        try:
            response = openai.FineTune.retrieve(id=fine_tune_id)
            status = response['status']
            print(f"Fine-tune ID: {fine_tune_id} Status: {status}")
            return response
        except Exception as e:
            print(f"Error retrieving fine-tuning status: {e}")
            raise

    def wait_for_fine_tuning(self, fine_tune_id: str, poll_interval: int = 60):
        """
        Waits for the fine-tuning job to complete.
        :param fine_tune_id: The ID of the fine-tuning job.
        :param poll_interval: Time in seconds between status checks.
        """
        print(f"Waiting for fine-tuning job {fine_tune_id} to complete...")
        while True:
            status_response = self.get_fine_tune_status(fine_tune_id)
            status = status_response['status']
            if status in ['succeeded', 'failed']:
                print(f"Fine-tuning job {fine_tune_id} completed with status: {status}")
                break
            print(f"Current status: {status}. Checking again in {poll_interval} seconds...")
            time.sleep(poll_interval)

    def predict(self, prompt: str, model: Optional[str] = None) -> str:
        """
        Generates a prediction using the fine-tuned GPT-4o model.
        :param prompt: Input text for prediction.
        :param model: The fine-tuned model to use. If None, uses the base model.
        :return: Generated prediction.
        """
        try:
            selected_model = model if model else "davinci"
            response = openai.Completion.create(
                model=selected_model,
                prompt=prompt,
                max_tokens=150,
                temperature=0.7,
                top_p=1,
                frequency_penalty=0,
                presence_penalty=0
            )
            prediction = response.choices[0].text.strip()
            return prediction
        except Exception as e:
            print(f"Error during prediction: {e}")
            raise
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/src/models/model.py" "$MODEL_CONTENT" "src/models/model.py" "SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296"

    # src/utils/auth.py
    # shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
    AUTH_CONTENT=$(cat <<'EOL'
from fastapi import HTTPException, Header
from jose import JWTError, jwt
from typing import Optional
import os
import hvac

# Initialize Vault client
vault_url = os.getenv("VAULT_URL", "http://localhost:8200")
vault_token = os.getenv("VAULT_TOKEN")
if not vault_token:
    raise ValueError("VAULT_TOKEN is not set in environment variables.")

vault_client = hvac.Client(url=vault_url, token=vault_token)
if not vault_client.is_authenticated():
    raise ValueError("Vault authentication failed.")

# Retrieve JWT secret
try:
    secrets = vault_client.secrets.kv.v2.read_secret_version(path='gpt4o_finetuning_project')
    SECRET_KEY = secrets['data']['data']['JWT_SECRET']
except Exception as e:
    raise ValueError(f"Failed to retrieve JWT_SECRET from Vault: {e}")

ALGORITHM = "HS256"

def get_current_user(authorization: Optional[str] = Header(None)):
    if not authorization:
        raise HTTPException(status_code=401, detail="Authorization header missing")
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid authorization header format")
    token = authorization.split(" ")[1]
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Token payload invalid")
        return user_id
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/src/utils/auth.py" "$AUTH_CONTENT" "src/utils/auth.py" "SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296"

    log_info "Source files creation completed."
}

# === Test Files Creation ===
create_test_files() {
    log_info "Creating test files..."

    # tests/test_api.py
    # shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
    TEST_API_CONTENT=$(cat <<'EOL'
from fastapi.testclient import TestClient
from src.api.main import app
from unittest.mock import patch
from src.models.model import GPT4oModel

client = TestClient(app)

def test_health_check():
    response = client.get("/api/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}

def test_predict():
    with patch.object(GPT4oModel, 'predict', return_value="Predicted output for: Test input"):
        response = client.post(
            "/api/predict",
            headers={"Authorization": "Bearer your_jwt_token"},
            json={"text": "Test input"}
        )
        assert response.status_code == 200
        assert "prediction" in response.json()
        assert response.json()["prediction"] == "Predicted output for: Test input"

def test_predict_no_auth():
    response = client.post(
        "/api/predict",
        json={"text": "Test input"}
    )
    assert response.status_code == 401

def test_predict_missing_text():
    response = client.post(
        "/api/predict",
        headers={"Authorization": "Bearer your_jwt_token"},
        json={}
    )
    assert response.status_code == 400

def test_fine_tune():
    with patch.object(GPT4oModel, 'fine_tune', return_value="ft-12345"):
        response = client.post(
            "/api/fine-tune",
            headers={"Authorization": "Bearer your_jwt_token"},
            json={"training_file_id": "file-12345"}
        )
        assert response.status_code == 200
        assert response.json()["status"] == "Model fine-tuned"
        assert response.json()["fine_tune_id"] == "ft-12345"

def test_get_status():
    with patch.object(GPT4oModel, 'get_fine_tune_status', return_value={'status': 'succeeded'}):
        response = client.get(
            "/api/status",
            headers={"Authorization": "Bearer your_jwt_token"},
            params={"fine_tune_id": "ft-12345"}
        )
        assert response.status_code == 200
        assert response.json() == {"fine_tune_id": "ft-12345", "status": "succeeded"}
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/tests/test_api.py" "$TEST_API_CONTENT" "tests/test_api.py" "SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296"

    log_info "Test files creation completed."
}

# === Setup.py Creation ===
create_setup_py() {
    log_info "Creating setup.py..."

    # shellcheck disable=SC2006
    SETUP_PY_CONTENT=$(cat <<'EOL'
from setuptools import setup, Extension
from Cython.Build import cythonize
import pybind11
import os

extensions = [
    Extension(
        "src.optimizations.cpp_modules.math_operations",
        ["src/optimizations/cpp_modules/math_operations.cpp"],
        include_dirs=[pybind11.get_include()],
        language='c++'
    ),
    Extension(
        "src.optimizations.cython_modules.math_operations",
        ["src/optimizations/cython_modules/math_operations.pyx"],
        include_dirs=[pybind11.get_include()],
        language='c++'
    )
]

setup(
    name="gpt4o_finetuning_project",
    version="1.0.0",
    author="Your Name",
    author_email="your.email@example.com",
    description="GPT-4 Fine-Tuning Project with Cython, C++, and Go optimizations.",
    long_description=open("README.md").read(),
    long_description_content_type="text/markdown",
    packages=["src", "src.optimizations.cython_modules", "src.optimizations.cpp_modules", "src.optimizations.go_service"],
    ext_modules=cythonize(extensions),
    install_requires=[
        # Add your Python dependencies here
        "fastapi",
        "uvicorn",
        "openai",
        "jose",
        "hvac",
        # ... other dependencies
    ],
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires='>=3.9',
)
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/setup.py" "$SETUP_PY_CONTENT" "setup.py" "SC2006"

    log_info "setup.py creation completed."
}

# === Go Service Files Creation ===
create_go_service_files() {
    log_info "Creating Go service files..."

    # src/optimizations/go_service/Dockerfile
    # shellcheck disable=SC2006
    GO_DOCKERFILE_CONTENT=$(cat <<'EOL'
# src/optimizations/go_service/Dockerfile

# Dockerfile for Go Service

FROM golang:1.16-alpine

WORKDIR /app

COPY . .

RUN go build -o go_service

EXPOSE 8081

CMD ["./go_service"]
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/src/optimizations/go_service/Dockerfile" "$GO_DOCKERFILE_CONTENT" "src/optimizations/go_service/Dockerfile" "SC2006"

    # src/optimizations/go_service/main.go
    # shellcheck disable=SC2006
    GO_MAIN_CONTENT=$(cat <<'EOL'
package main

import (
    "fmt"
    "net/http"
)

func goChatHandler(w http.ResponseWriter, r *http.Request) {
    // Placeholder for Go service logic
    fmt.Fprintf(w, "Go Chat Service is running.")
}

func main() {
    http.HandleFunc("/go-chat", goChatHandler)
    fmt.Println("Go Chat Service is running on port 8081")
    if err := http.ListenAndServe(":8081", nil); err != nil {
        fmt.Println("Error starting Go service:", err)
    }
}
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/src/optimizations/go_service/main.go" "$GO_MAIN_CONTENT" "src/optimizations/go_service/main.go" "SC2006"

    log_info "Go service files creation completed."
}

# === C++ Module Creation ===
create_cpp_module() {
    log_info "Creating C++ module..."

    # src/optimizations/cpp_modules/math_operations.cpp
    # shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
    CPP_MODULE_CONTENT=$(cat <<'EOL'
#include <pybind11/pybind11.h>
#include <string>

namespace py = pybind11;

// Example function: Reverse a string
std::string reverse_string(const std::string &input) {
    std::string reversed(input.rbegin(), input.rend());
    return reversed;
}

PYBIND11_MODULE(math_operations, m) {
    m.doc() = "C++ extension module for GPT-4o fine-tuning project";
    m.def("reverse_string", &reverse_string, "A function that reverses a string");
}
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/src/optimizations/cpp_modules/math_operations.cpp" "$CPP_MODULE_CONTENT" "src/optimizations/cpp_modules/math_operations.cpp" "SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296"

    log_info "C++ module creation completed."
}

# === Cython Module Creation ===
create_cython_module() {
    log_info "Creating Cython module..."

    # src/optimizations/cython_modules/math_operations.pyx
    # shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
    CYTHON_MODULE_CONTENT=$(cat <<'EOL'
# cython: language_level=3

from src.optimizations.cpp_modules.math_operations import reverse_string

def cython_reverse_string(str input):
    """
    Reverses the input string using the C++ extension.
    """
    return reverse_string(input)
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/src/optimizations/cython_modules/math_operations.pyx" "$CYTHON_MODULE_CONTENT" "src/optimizations/cython_modules/math_operations.pyx" "SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296"

    log_info "Cython module creation completed."
}

# === GitHub Actions Workflows Creation ===
create_github_workflows() {
    log_info "Creating GitHub Actions workflows..."

    # .github/workflows/ci.yml
    # shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
    CI_YML_CONTENT=$(cat <<'EOL'
# .github/workflows/ci.yml

name: CI Pipeline

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:

    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2
    - name: Set up Python
      uses: actions/setup-python@v2
      with:
        python-version: '3.9'
    - name: Install dependencies
      run: |
        python3 -m pip install --upgrade pip
        pip3 install -r requirements.txt
    - name: Lint with flake8
      run: |
        pip3 install flake8
        flake8 src/ tests/
    - name: Format with black
      run: |
        pip3 install black
        black --check src/ tests/
    - name: Security scan with bandit
      run: |
        pip3 install bandit
        bandit -r src/
    - name: Run tests
      run: |
        pytest
EOL
)

    create_file_if_not_exists "$PROJECT_DIR/.github/workflows/ci.yml" "$CI_YML_CONTENT" ".github/workflows/ci.yml" "SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296"

    # Optional: deploy.yml
    # shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
    DEPLOY_YML_CONTENT=$(cat <<'EOL'
# .github/workflows/deploy.yml

name: Deploy to Production

on:
  push:
    branches: [ main ]

jobs:
  deploy:

    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v1
    - name: Log in to Docker Hub
      uses: docker/login-action@v1
      with:
        username: "${DOCKERHUB_USERNAME}"
        password: "${{ secrets.DOCKERHUB_PASSWORD }}"
    - name: Build and Push Docker Image
      uses: docker/build-push-action@v2
      with:
        context: ..
        file: docker/Dockerfile
        push: true
        tags: "${DOCKERHUB_USERNAME}/gpt4o_finetuning_project:latest"
    - name: Deploy to Server
      uses: easingthemes/ssh-deploy@v2.1.5
      with:
        ssh-private-key: "${{ secrets.SSH_PRIVATE_KEY }}"
        remote-user: ubuntu
        server-ip: "${DEPLOY_SERVER_IP}"
        remote-path: "${DEPLOY_REMOTE_PATH}"
        script: |
          docker-compose -f docker/docker-compose.yml pull
          docker-compose -f docker/docker-compose.yml up -d
EOL
)

    # Prompt user to decide whether to create deployment workflow
    while true; do
        read -rp "Do you want to set up a deployment workflow? (y/n): " SETUP_DEPLOY_WF
        case "$SETUP_DEPLOY_WF" in
            [Yy]* )
                # Prompt for deployment server details
                while true; do
                    read -rp "Enter Deployment Server IP Address: " DEPLOY_SERVER_IP
                    if [[ "$DEPLOY_SERVER_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
                        break
                    else
                        log_warn "Please enter a valid IP address."
                    fi
                done

                read -rp "Enter Deployment Remote Path (e.g., /var/www/gpt4o_finetuning_project): " DEPLOY_REMOTE_PATH
                if [[ -z "$DEPLOY_REMOTE_PATH" ]]; then
                    log_warn "Remote path cannot be empty. Using default: /var/www/gpt4o_finetuning_project"
                    DEPLOY_REMOTE_PATH="/var/www/gpt4o_finetuning_project"
                fi

                export DEPLOY_SERVER_IP DEPLOY_REMOTE_PATH

                create_file_if_not_exists "$PROJECT_DIR/.github/workflows/deploy.yml" "$DEPLOY_YML_CONTENT" ".github/workflows/deploy.yml" "SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296"
                break
                ;;
            [Nn]* )
                log_warn "Skipping deployment workflow setup."
                break
                ;;
            * )
                log_warn "Please answer yes (y) or no (n)."
                ;;
        esac
    done

    log_info "GitHub Actions workflows creation completed."
}

# === SSL Certificates Generation ===
generate_ssl_certificates() {
    log_info "Generating self-signed SSL certificates for development..."

    local cert_dir="$PROJECT_DIR/docker/certs"

    if [ ! -f "$cert_dir/fullchain.pem" ] || [ ! -f "$cert_dir/privkey.pem" ]; then
        mkdir -p "$cert_dir"
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "$cert_dir/privkey.pem" \
            -out "$cert_dir/fullchain.pem" \
            -subj "/C=US/ST=State/L=City/O=Organization/OU=OrgUnit/CN=localhost" || error_exit "Failed to generate SSL certificates."
        log_info "Self-signed SSL certificates generated."
    else
        log_warn "SSL certificates already exist in \"$cert_dir\". Skipping."
    fi
}

# === Initialize Git Repository ===
initialize_git_repo() {
    while true; do
        read -rp "Do you want to initialize a Git repository? (y/n): " INIT_GIT
        case "$INIT_GIT" in
            [Yy]* )
                log_info "Initializing Git repository..."
                cd "$PROJECT_DIR"
                git init
                git add .
                git commit -m "Initial commit: Setup project structure and essential files"
                log_info "Git repository initialized and initial commit made."
                cd ..
                break
                ;;
            [Nn]* )
                log_warn "Skipping Git repository initialization."
                break
                ;;
            * )
                log_warn "Please answer yes (y) or no (n)."
                ;;
        esac
    done
}

# === Prompt to Add GitHub Secrets ===
prompt_github_secrets() {
    log_info "Please manually add the following secrets to your GitHub repository's Settings > Secrets and variables > Actions:"
    echo "- OPENAI_API_KEY"
    echo "- JWT_SECRET"
    echo "- VAULT_TOKEN"
    echo "- DOCKERHUB_PASSWORD (if deploying)"
    echo "- SSH_PRIVATE_KEY (if deploying)"
}

# === Final Instructions ===
final_instructions() {
    log_info "All project files have been generated successfully!"

    echo -e "\nNext Steps:"
    echo "1. Customize placeholder values in the generated files (e.g., .env, README.md)."
    echo "2. Set up your secret management tool (e.g., HashiCorp Vault) and configure secrets."
    echo "3. Run the setup script to install dependencies and build extensions:"
    echo "   cd \"$PROJECT_DIR\" && ./scripts/setup_project.sh"
    echo "4. Start the application using Docker Compose with:"
    echo "   make build"
    echo "5. Add GitHub secrets as prompted."
    echo "6. (Optional) Push your repository to GitHub and set up remote origins if Git was initialized."
}

# === Main Execution ===
main() {
    log_info "Starting GPT-4 Fine-Tuning Project setup..."

    check_dependencies
    get_user_input
    create_directories
    create_root_files
    create_makefile
    create_env_example
    create_config_files
    create_docker_files
    create_documentation_files
    create_script_files
    create_source_files
    create_test_files
    create_setup_py
    create_go_service_files
    create_cpp_module
    create_cython_module
    create_github_workflows
    generate_ssl_certificates
    initialize_git_repo
    prompt_github_secrets
    final_instructions
}

# Execute main function
main
