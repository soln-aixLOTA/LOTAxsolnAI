#!/bin/bash

###############################################################################
#                                                                             #
#                                gen.sh                                       #
#                                                                             #
#  Description:                                                               #
#    Automates the setup and deployment of a comprehensive AI Platform,       #
#    including modules such as AI Chatbot, Predictive Analytics,              #
#    Personalization Engine, Cybersecurity AI, Content Creation AI,           #
#    Healthcare AI, AI Consulting, VR/AR AI, Supply Chain AI, and AutoML.     #
#                                                                             #
#    Supports Debian/Ubuntu-based systems.                                    #
#                                                                             #
#  Usage:                                                                     #
#    sudo bash gen.sh [options]                                               #
#                                                                             #
#  Options:                                                                   #
#    -h, --help            Display this help message                          #
#    -v, --verbose         Enable verbose logging                             #
#    -j, --jenkins-version Specify Jenkins version (default: 2.387.3)         #
#                                                                             #
#  Note:                                                                      #
#    - Ensure required environment variables are exported before running      #
#      the script (e.g., GITHUB_PAT, REPO_OWNER, REPO_NAME, etc.).            #
#    - Review and modify configuration variables as needed.                   #
#                                                                             #
###############################################################################

set -euo pipefail
IFS=$'\n\t'

# =============================================================================
#                           GLOBAL VARIABLES
# =============================================================================

# Default versions for tools
readonly TERRAFORM_VERSION="1.5.7"
readonly GO_VERSION="1.21.1"
readonly DOCKER_COMPOSE_VERSION="2.20.2"
readonly KUBE_VERSION="1.27.3"
readonly HELM_VERSION="3.12.3"
readonly JENKINS_VERSION_DEFAULT="2.387.3"
readonly ARGOCD_VERSION="2.7.3"
readonly PROMETHEUS_VERSION="14.11.1"
readonly GRAFANA_VERSION="6.50.1"

# Determine project root with fallback
determine_project_root() {
    if git rev-parse --is-inside-work-tree &> /dev/null; then
        git rev-parse --show-toplevel
    else
        pwd
    fi
}

PROJECT_ROOT="$(determine_project_root)"
LOG_FILE="${PROJECT_ROOT}/logs/ai_platform_setup.log"
BACKUP_DIR="${PROJECT_ROOT}/backups"
DEPLOYMENT_DIR="${PROJECT_ROOT}/deployment"

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Verbose flag
VERBOSE=false

# =============================================================================
#                           CONFIGURATION VARIABLES
# =============================================================================

# Jenkins Configuration Variables
readonly JENKINS_URL="${JENKINS_URL:-http://localhost:8080}"
readonly JENKINS_USER="${JENKINS_USER:-admin}"
readonly JENKINS_API_TOKEN="${JENKINS_API_TOKEN:-}"

# GitHub Configuration Variables
readonly GITHUB_PAT="${GITHUB_PAT:-}"
readonly REPO_OWNER="${REPO_OWNER:-}"
readonly REPO_NAME="${REPO_NAME:-}"

# Docker Credentials
readonly DOCKER_USERNAME="${DOCKER_USERNAME:-}"
readonly DOCKER_PASSWORD="${DOCKER_PASSWORD:-}"
readonly DOCKER_CREDENTIALS_ID="${DOCKER_CREDENTIALS_ID:-docker-credentials-id}"

# Kubernetes Configuration Variables
readonly KUBECONFIG_CONTENT="${KUBECONFIG_CONTENT:-}"
readonly KUBECONFIG_CREDENTIALS_ID="${KUBECONFIG_CREDENTIALS_ID:-kubeconfig-credentials-id}"

# Slack Configuration Variables
readonly SLACK_TOKEN="${SLACK_TOKEN:-}"
readonly SLACK_CHANNEL="${SLACK_CHANNEL:-#ci-cd-notifications}"
readonly SLACK_CREDENTIALS_ID="${SLACK_CREDENTIALS_ID:-slack-credentials-id}"

# Webhook Secret for GitHub
readonly WEBHOOK_SECRET="${WEBHOOK_SECRET:-}"

# =============================================================================
#                           LOGGING FUNCTIONS
# =============================================================================

# Enhanced logging with timestamps and colors
log() {
    local level="$1"
    shift
    local message="$*"
    local color=""
    case "${level}" in
        "ERROR")   color="${RED}" ;;
        "SUCCESS") color="${GREEN}" ;;
        "WARN")    color="${YELLOW}" ;;
        "INFO")    color="${NC}" ;;
        *)         color="${NC}" ;;
    esac
    echo -e "${color}$(date '+%Y-%m-%d %H:%M:%S') [${level}] - ${message}${NC}" | tee -a "${LOG_FILE}"
}

# Initialize logging
init_logging() {
    mkdir -p "$(dirname "${LOG_FILE}")"
    mkdir -p "${BACKUP_DIR}"
    mkdir -p "${DEPLOYMENT_DIR}/docker"
    mkdir -p "${DEPLOYMENT_DIR}/k8s"
    mkdir -p "${DEPLOYMENT_DIR}/terraform"
    mkdir -p "${PROJECT_ROOT}/monitoring/grafana/dashboards"
    mkdir -p "${PROJECT_ROOT}/monitoring/prometheus"
    mkdir -p "${PROJECT_ROOT}/scripts"
    mkdir -p "${PROJECT_ROOT}/tests/unit"
    mkdir -p "${PROJECT_ROOT}/tests/integration"
    mkdir -p "${PROJECT_ROOT}/tests/e2e"
    mkdir -p "${PROJECT_ROOT}/docs/api"
    mkdir -p "${PROJECT_ROOT}/docs/user"
    mkdir -p "${PROJECT_ROOT}/monitoring/prometheus"
    exec > >(tee -a "${LOG_FILE}") 2>&1
    log "INFO" "===== AI Platform Setup Started ====="
    log "INFO" "Project root: ${PROJECT_ROOT}"
}

# Error handler with stack trace
handle_error() {
    local line_num=$1
    local error_code=$2
    log "ERROR" "Error occurred in function ${FUNCNAME[1]} at line ${line_num}"
    log "ERROR" "Exit code: ${error_code}"
    # Print stack trace
    local frame=1
    while caller $frame; do
        ((frame++))
    done | awk '{print "ERROR: "$2" called from line "$1}' | while read -r line; do
            log "ERROR" "${line}"
    done
}
trap 'handle_error ${LINENO} $?' ERR

# =============================================================================
#                           HELP FUNCTION
# =============================================================================

usage() {
    echo -e "${YELLOW}Usage: sudo bash gen.sh [options]${NC}"
    echo ""
    echo "Options:"
    echo "  -h, --help             Display this help message"
    echo "  -v, --verbose          Enable verbose logging"
    echo "  -j, --jenkins-version  Specify Jenkins version (default: ${JENKINS_VERSION_DEFAULT})"
    exit 1
}

# =============================================================================
#                           PARSE COMMAND-LINE ARGUMENTS
# =============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
            -h|--help)
                usage
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -j|--jenkins-version)
                JENKINS_VERSION="$2"
                shift
                shift
                ;;
            *)
                log "WARN" "Unknown option: $1"
                usage
                ;;
        esac
    done
}

# =============================================================================
#                           VALIDATE ENVIRONMENT VARIABLES
# =============================================================================

validate_env_vars() {
    log "INFO" "Validating required environment variables..."
    local required_vars=("GITHUB_PAT" "REPO_OWNER" "REPO_NAME" "DOCKER_USERNAME" "DOCKER_PASSWORD" "KUBECONFIG_CONTENT" "SLACK_TOKEN" "JENKINS_API_TOKEN" "WEBHOOK_SECRET")
    local missing_vars=()
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            missing_vars+=("${var}")
        fi
    done

    if [ ${#missing_vars[@]} -ne 0 ]; then
        log "ERROR" "The following environment variables are not set: ${missing_vars[*]}"
        exit 1
    fi
    log "SUCCESS" "All required environment variables are set."
}

# =============================================================================
#                           OS DETECTION
# =============================================================================

detect_os() {
    case "$OSTYPE" in
        linux-gnu*)
            if [ -f /etc/os-release ]; then
                # shellcheck source=/etc/os-release
                . /etc/os-release
                case "$ID" in
                    ubuntu|debian) echo "debian" ;;
                    fedora|rhel|centos) echo "redhat" ;;
                    arch) echo "arch" ;;
                    *) echo "unknown" ;;
                esac
            else
                echo "unknown"
            fi
            ;;
        darwin*)
            echo "macos"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# =============================================================================
#                           SECURITY FUNCTIONS
# =============================================================================

# Verify checksum of downloaded files
verify_checksum() {
    local file="$1"
    local expected_checksum="$2"
    local algorithm="${3:-sha256}"

    if ! command -v "${algorithm}sum" &> /dev/null; then
        log "ERROR" "${algorithm}sum command not found"
        return 1
    fi

    local actual_checksum
    actual_checksum=$("${algorithm}sum" "$file" | cut -d' ' -f1)
    if [ "$actual_checksum" != "$expected_checksum" ]; then
        log "ERROR" "Checksum verification failed for $file"
        log "ERROR" "Expected: $expected_checksum"
        log "ERROR" "Got: $actual_checksum"
        return 1
    fi
    log "INFO" "Checksum verified for $file"
}

# Generate secure random password
generate_secure_password() {
    local length="${1:-32}"
    if command -v openssl &> /dev/null; then
        openssl rand -base64 48 | cut -c1-"${length}"
    else
        tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~' </dev/urandom | head -c "${length}"
    fi
}

# Secure file permissions
secure_file_permissions() {
    local file="$1"
    local perms="${2:-600}"
    chmod "${perms}" "${file}"
    log "INFO" "Secured permissions for ${file}"
}

# =============================================================================
#                           DEPENDENCY MANAGEMENT
# =============================================================================

# Enhanced package installation with retry mechanism
install_package() {
    local package="$1"
    local cmd="$2"
    local os
    os=$(detect_os)
    local max_attempts=3
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        log "INFO" "Installing ${package} (attempt ${attempt}/${max_attempts})"
        case "${os}" in
            debian)
                if ! dpkg -s "${package}" &> /dev/null; then
                    sudo apt-get update -qq
                    if sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${package}"; then
                        log "SUCCESS" "${package} installed successfully"
                        return 0
                    fi
                else
                    log "INFO" "${package} is already installed"
                    return 0
                fi
                ;;
            redhat)
                if ! rpm -q "${package}" &> /dev/null; then
                    if sudo yum install -y "${package}"; then
                        log "SUCCESS" "${package} installed successfully"
                        return 0
                    fi
                else
                    log "INFO" "${package} is already installed"
                    return 0
                fi
                ;;
            arch)
                if ! pacman -Qi "${package}" &> /dev/null; then
                    if sudo pacman -Syu --noconfirm "${package}"; then
                        log "SUCCESS" "${package} installed successfully"
                        return 0
                    fi
                else
                    log "INFO" "${package} is already installed"
                    return 0
                fi
                ;;
            macos)
                if ! command -v brew &> /dev/null; then
                    log "ERROR" "Homebrew is required for installing ${package} on macOS."
                    exit 1
                fi
                if ! brew list "${package}" &> /dev/null; then
                    if brew install "${package}"; then
                        log "SUCCESS" "${package} installed successfully"
                        return 0
                    fi
                else
                    log "INFO" "${package} is already installed"
                    return 0
                fi
                ;;
            *)
                log "ERROR" "Unsupported OS for installing ${package}"
                return 1
                ;;
        esac

        log "WARN" "Attempt ${attempt} failed. Retrying..."
        ((attempt++))
        sleep 5
    done

    log "ERROR" "Failed to install ${package} after ${max_attempts} attempts"
    return 1
}

# Install all required dependencies
install_dependencies() {
    log "INFO" "Installing dependencies..."

    local dependencies=(
        "git:git"
        "curl:curl"
        "wget:wget"
        "jq:jq"
        "make:make"
        "gcc:gcc"
        "g++:g++"
        "python3:python3"
        "python3-pip:pip3"
        "unzip:unzip"
        "kubectl:kubectl"
        "docker:docker"
        "openjdk-11-jdk:java"
    )

    for dep in "${dependencies[@]}"; do
        IFS=':' read -r pkg cmd <<< "${dep}"
        if ! command -v "${cmd}" &> /dev/null; then
            install_package "${pkg}" "${cmd}"
        else
            log "INFO" "${pkg} is already installed"
        fi
    done
}

# =============================================================================
#                           DOCKER INSTALLATION
# =============================================================================

install_docker() {
    log "INFO" "Installing Docker..."

    local os
    os=$(detect_os)

    case "${os}" in
        debian)
            # Install dependencies
            sudo apt-get update -qq
            sudo apt-get install -y -qq \
                apt-transport-https \
                ca-certificates \
                curl \
                gnupg \
                lsb-release

            # Add Docker's official GPG key
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

            # Set up stable repository
            echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
                $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

            # Install Docker Engine
            sudo apt-get update -qq
            if ! dpkg -l docker-ce &> /dev/null; then
                sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io
                log "SUCCESS" "Docker installed successfully."
            else
                log "INFO" "Docker is already installed."
            fi

            # Start and enable Docker service
            sudo systemctl enable --now docker

            # Add current user to docker group
            sudo usermod -aG docker "$USER"
            log "INFO" "Added ${USER} to docker group. Please log out and log back in to apply changes."
            ;;
        redhat)
            # Similar steps for RedHat-based systems
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io
            sudo systemctl enable --now docker
            sudo usermod -aG docker "$USER"
            log "SUCCESS" "Docker installed successfully on RedHat-based system."
            ;;
        arch)
            sudo pacman -Syu --noconfirm docker
            sudo systemctl enable --now docker
            sudo usermod -aG docker "$USER"
            log "SUCCESS" "Docker installed successfully on Arch-based system."
            ;;
        macos)
            if ! command -v brew &> /dev/null; then
                log "ERROR" "Homebrew is required for Docker installation on macOS."
                exit 1
            fi
            brew install --cask docker
            log "SUCCESS" "Docker installed successfully on macOS. Please start Docker from Applications."
            ;;
        *)
            log "ERROR" "Docker installation not supported for ${os}"
            exit 1
            ;;
    esac

    # Verify Docker Daemon
    if sudo systemctl is-active --quiet docker; then
        log "INFO" "Docker daemon is running."
    else
        log "ERROR" "Docker daemon is not running."
        exit 1
    fi
}

# =============================================================================
#                           GOLANG INSTALLATION
# =============================================================================

install_golang() {
    if ! command -v go &> /dev/null; then
        log "INFO" "Installing Go..."
        os=$(detect_os)
        case "${os}" in
            debian|redhat)
                wget -q "https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz"
                sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
                rm "go${GO_VERSION}.linux-amd64.tar.gz"
                ;;
            arch)
                sudo pacman -Syu --noconfirm go
                ;;
            macos)
                if ! command -v brew &> /dev/null; then
                    log "ERROR" "Homebrew is required for Go installation on macOS."
                    exit 1
                fi
                brew install "go@${GO_VERSION}"
                ;;
            *)
                log "ERROR" "Unsupported OS for installing Go."
                exit 1
                ;;
        esac

        # Add Go to PATH
        if ! grep -q "/usr/local/go/bin" <<< "$PATH"; then
            echo "export PATH=\$PATH:/usr/local/go/bin" | sudo tee -a /etc/profile
            # shellcheck source=/etc/profile
            source /etc/profile
        fi
        log "SUCCESS" "Go ${GO_VERSION} installed successfully."
    else
        log "INFO" "Go is already installed."
    fi

    # Verify installation
    if ! command -v go &> /dev/null; then
        log "ERROR" "Go is not available after installation."
        exit 1
    else
        log "INFO" "Verified: Go is installed."
    fi
}

# =============================================================================
#                           TERRAFORM INSTALLATION
# =============================================================================

install_terraform() {
    if ! command -v terraform &> /dev/null; then
        log "INFO" "Installing Terraform..."
        wget -q "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
        unzip -qq "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
        sudo mv terraform /usr/local/bin/
        rm "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
        log "SUCCESS" "Terraform ${TERRAFORM_VERSION} installed successfully."
    else
        log "INFO" "Terraform is already installed."
    fi

    # Verify installation
    if ! command -v terraform &> /dev/null; then
        log "ERROR" "Terraform is not available after installation."
        exit 1
    else
        log "INFO" "Verified: Terraform is installed."
    fi
}

# =============================================================================
#                           ARGOCd INSTALLATION
# =============================================================================

install_argocd() {
    if ! command -v argocd &> /dev/null; then
        log "INFO" "Installing ArgoCD CLI..."
        wget -q "https://github.com/argoproj/argo-cd/releases/download/v${ARGOCD_VERSION}/argocd-linux-amd64"
        sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
        rm argocd-linux-amd64
        log "SUCCESS" "ArgoCD CLI installed successfully."
    else
        log "INFO" "ArgoCD CLI is already installed."
    fi

    # Verify installation
    if ! command -v argocd &> /dev/null; then
        log "ERROR" "ArgoCD CLI is not available after installation."
        exit 1
    else
        log "INFO" "Verified: ArgoCD CLI is installed."
    fi
}

# =============================================================================
#                           HELM INSTALLATION
# =============================================================================

install_helm() {
    if ! command -v helm &> /dev/null; then
        log "INFO" "Installing Helm..."
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
        log "SUCCESS" "Helm installed successfully."
    else
        log "INFO" "Helm is already installed."
    fi

    # Verify installation
    if ! command -v helm &> /dev/null; then
        log "ERROR" "Helm is not available after installation."
        exit 1
    else
        log "INFO" "Verified: Helm is installed."
    fi
}

# =============================================================================
#                           CREATE PROJECT STRUCTURE
# =============================================================================

create_project_structure() {
    log "INFO" "Creating project directory structure..."

    local dirs=(
        "src/ai_chatbot"
        "src/predictive_analytics"
        "src/personalization_engine"
        "src/cybersecurity_ai"
        "src/content_creation_ai"
        "src/healthcare_ai"
        "src/ai_consulting"
        "src/vr_ar_ai"
        "src/supply_chain_ai"
        "src/automl"
        "src/common/utils"
        "deployment/docker"
        "deployment/k8s"
        "deployment/terraform"
        "scripts"
        "tests/unit"
        "tests/integration"
        "tests/e2e"
        "docs/api"
        "docs/user"
        "monitoring/grafana/dashboards"
        "monitoring/prometheus"
        "${BACKUP_DIR}"
    )

    for dir in "${dirs[@]}"; do
        mkdir -p "${PROJECT_ROOT}/${dir}"
        log "INFO" "Created directory: ${dir}"
    done
}

# =============================================================================
#                           GIT INITIALIZATION
# =============================================================================

init_git_repo() {
    log "INFO" "Initializing Git repository..."

    if [ ! -d "${PROJECT_ROOT}/.git" ]; then
        git init "${PROJECT_ROOT}"

        # Configure .gitignore
        cat > "${PROJECT_ROOT}/.gitignore" <<EOF
# Environment variables
.env
.env.*
!.env.example

# Dependencies
node_modules/
vendor/
__pycache__/
*.pyc

# Build output
dist/
build/
*.egg-info/

# Logs
logs/
*.log

# IDE files
.idea/
.vscode/
*.swp
*.swo

# System files
.DS_Store
Thumbs.db

# Temporary files
*.tmp
*.temp
*.bak

# Sensitive data
*.pem
*.key
*.cert
secrets/
EOF

        # Configure .gitattributes
        cat > "${PROJECT_ROOT}/.gitattributes" <<EOF
# Auto detect text files and perform LF normalization
* text=auto

# Docker
*.dockerfile text
Dockerfile text

# Shell scripts
*.sh text eol=lf
*.bash text eol=lf

# Python
*.py text diff=python

# JavaScript
*.js text
*.jsx text
*.ts text
*.tsx text

# Documentation
*.md text diff=markdown
*.txt text
*.json text

# Configs
*.yml text
*.yaml text
*.toml text
*.conf text

# Binary files
*.png binary
*.jpg binary
*.gif binary
*.ico binary
*.zip binary
*.tar binary
*.gz binary
*.db binary
EOF

        git add .
        git commit -m "Initial commit"
        log "SUCCESS" "Git repository initialized with .gitignore and .gitattributes."
    else
        log "INFO" "Git repository already exists."
    fi
}

# =============================================================================
#                           CONFIGURATION FILES
# =============================================================================

create_config_files() {
    log "INFO" "Creating configuration files..."

    # Create .env.example
    cat > "${PROJECT_ROOT}/.env.example" <<EOF
# Application
APP_ENV=development
DEBUG=true
LOG_LEVEL=debug

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=ai_platform
DB_USER=postgres
DB_PASSWORD=

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# API Keys
OPENAI_API_KEY=
HUGGINGFACE_API_KEY=

# Security
JWT_SECRET=
ENCRYPTION_KEY=

# Services
AI_CHATBOT_PORT=8000
PREDICTIVE_ANALYTICS_PORT=8001
PERSONALIZATION_ENGINE_PORT=8002

# Monitoring
PROMETHEUS_PORT=9090
GRAFANA_PORT=3000
EOF

    # Create docker-compose.yml
    cat > "${PROJECT_ROOT}/docker-compose.yml" <<EOF
version: '3.8'

services:
  ai_chatbot:
    build:
      context: .
      dockerfile: deployment/docker/ai_chatbot.Dockerfile
    ports:
      - "\${AI_CHATBOT_PORT:-8000}:8000"
    environment:
      - APP_ENV=\${APP_ENV}
      - DB_HOST=\${DB_HOST}
    depends_on:
      - db
      - redis
    networks:
      - ai_platform_net
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  db:
    image: postgres:13-alpine
    environment:
      - POSTGRES_DB=\${DB_NAME}
      - POSTGRES_USER=\${DB_USER}
      - POSTGRES_PASSWORD=\${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - ai_platform_net
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U \${DB_USER} -d \${DB_NAME}"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:6-alpine
    command: redis-server --requirepass \${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    networks:
      - ai_platform_net
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 3

networks:
  ai_platform_net:
    driver: bridge

volumes:
  postgres_data:
  redis_data:
EOF

    # Create Prometheus configuration
    cat > "${PROJECT_ROOT}/monitoring/prometheus/prometheus.yml" <<EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - 'alert.rules'

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'ai_chatbot'
    static_configs:
      - targets: ['ai_chatbot:8000']

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['node_exporter:9100']
EOF

    # Create Grafana dashboard configuration
    cat > "${PROJECT_ROOT}/monitoring/grafana/dashboards/ai_platform.json" <<EOF
{
  "annotations": {
    "list": []
  },
  "editable": true,
  "fiscalYearStartMonth": 0,
  "graphTooltip": 0,
  "hideControls": false,
  "links": [],
  "liveNow": false,
  "panels": [
    {
      "datasource": {
        "type": "prometheus",
        "uid": "prometheus"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "percent"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 0
      },
      "id": 1,
      "options": {
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "mode": "single",
          "sort": "none"
        }
      },
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "prometheus"
          },
          "expr": "rate(process_cpu_seconds_total{job=\"ai_chatbot\"}[5m]) * 100",
          "interval": "",
          "legendFormat": "CPU Usage",
          "refId": "A"
        }
      ],
      "title": "CPU Usage",
      "type": "timeseries"
    }
  ],
  "refresh": "5s",
  "schemaVersion": 38,
  "style": "dark",
  "tags": [],
  "templating": {
    "list": []
  },
  "time": {
    "from": "now-6h",
    "to": "now"
  },
  "timepicker": {},
  "timezone": "",
  "title": "AI Platform Dashboard",
  "uid": "ai_platform",
  "version": 1,
  "weekStart": ""
}
EOF

    log "SUCCESS" "Configuration files created successfully."
}

# =============================================================================
#                           KUBERNETES MANIFESTS
# =============================================================================

create_kubernetes_manifests() {
    log "INFO" "Creating Kubernetes manifests..."

    # Create base namespace
    cat > "${PROJECT_ROOT}/deployment/k8s/00-namespace.yaml" <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: ai-platform
EOF
    kubectl apply -f "${PROJECT_ROOT}/deployment/k8s/00-namespace.yaml"

    # Create network policies
    cat > "${PROJECT_ROOT}/deployment/k8s/01-network-policies.yaml" <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-internal
  namespace: ai-platform
spec:
  podSelector: {}
  ingress:
  - from:
    - podSelector: {}
  egress:
  - to:
    - podSelector: {}
EOF
    kubectl apply -f "${PROJECT_ROOT}/deployment/k8s/01-network-policies.yaml"

    # Create resource quotas
    cat > "${PROJECT_ROOT}/deployment/k8s/02-resource-quota.yaml" <<EOF
apiVersion: v1
kind: ResourceQuota
metadata:
  name: ai-platform-quota
  namespace: ai-platform
spec:
  hard:
    pods: "20"
    requests.cpu: "10"
    requests.memory: "20Gi"
    limits.cpu: "20"
    limits.memory: "40Gi"
EOF
    kubectl apply -f "${PROJECT_ROOT}/deployment/k8s/02-resource-quota.yaml"

    # Create AI Chatbot deployment
    cat > "${PROJECT_ROOT}/deployment/k8s/03-ai-chatbot-deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ai-chatbot
  namespace: ai-platform
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ai-chatbot
  template:
    metadata:
      labels:
        app: ai-chatbot
    spec:
      containers:
      - name: ai-chatbot
        image: your-docker-registry/ai-chatbot:latest
        ports:
        - containerPort: 8000
        env:
        - name: OPENAI_API_KEY
          valueFrom:
            secretKeyRef:
              name: ai-secrets
              key: openai_api_key
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1"
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8000
          initialDelaySeconds: 15
          periodSeconds: 20
        readinessProbe:
          httpGet:
            path: /readyz
            port: 8000
          initialDelaySeconds: 15
          periodSeconds: 20
EOF
    kubectl apply -f "${PROJECT_ROOT}/deployment/k8s/03-ai-chatbot-deployment.yaml"

    # Create service
    cat > "${PROJECT_ROOT}/deployment/k8s/04-ai-chatbot-service.yaml" <<EOF
apiVersion: v1
kind: Service
metadata:
  name: ai-chatbot-service
  namespace: ai-platform
spec:
  selector:
    app: ai-chatbot
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8000
  type: ClusterIP
EOF
    kubectl apply -f "${PROJECT_ROOT}/deployment/k8s/04-ai-chatbot-service.yaml"

    # Create ConfigMap
    cat > "${PROJECT_ROOT}/deployment/k8s/05-configmap.yaml" <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: ai-chatbot-config
  namespace: ai-platform
data:
  CONFIG_FILE: "config.yaml"
EOF
    kubectl apply -f "${PROJECT_ROOT}/deployment/k8s/05-configmap.yaml"

    # Create Secrets
    cat > "${PROJECT_ROOT}/deployment/k8s/06-secrets.yaml" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ai-secrets
  namespace: ai-platform
type: Opaque
data:
  openai_api_key: $(echo -n "${OPENAI_API_KEY}" | base64)
EOF
    kubectl apply -f "${PROJECT_ROOT}/deployment/k8s/06-secrets.yaml"

    # Create monitoring resources
    cat > "${PROJECT_ROOT}/deployment/k8s/07-monitoring.yaml" <<EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: ai-chatbot-servicemonitor
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: ai-chatbot
  endpoints:
  - port: 8000
    path: /metrics
    interval: 15s
EOF
    kubectl apply -f "${PROJECT_ROOT}/deployment/k8s/07-monitoring.yaml"

    log "SUCCESS" "Kubernetes manifests applied successfully."
}

# =============================================================================
#                           MONITORING CONFIGURATIONS
# =============================================================================

create_monitoring_configurations() {
    log "INFO" "Creating monitoring configurations..."

    # Additional monitoring configurations can be added here if needed

    log "SUCCESS" "Monitoring configurations created successfully."
}

# =============================================================================
#                           JENKINS INSTALLATION
# =============================================================================

install_jenkins() {
    log "INFO" "Installing Jenkins..."

    local os
    os=$(detect_os)

    case "${os}" in
        debian)
            # Install Java if not present
            if ! command -v java &> /dev/null; then
                log "INFO" "Installing OpenJDK 11 for Jenkins..."
                install_package "openjdk-11-jdk" "java"
                log "SUCCESS" "OpenJDK 11 installed successfully."
            else
                log "INFO" "Java is already installed."
            fi

            # Add Jenkins repository and key
            if [ ! -f /usr/share/keyrings/jenkins-keyring.asc ]; then
                curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee \
                    /usr/share/keyrings/jenkins-keyring.asc > /dev/null
            fi

            if [ ! -f /etc/apt/sources.list.d/jenkins.list ]; then
                echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
            fi

            # Update and install Jenkins
            sudo apt-get update -qq
            if ! dpkg -l jenkins &> /dev/null; then
                sudo apt-get install -y -qq jenkins="${JENKINS_VERSION:-${JENKINS_VERSION_DEFAULT}}"
                log "SUCCESS" "Jenkins installed successfully."
            else
                log "INFO" "Jenkins is already installed."
            fi

            # Start and enable Jenkins service
            sudo systemctl enable --now jenkins

            # Allow Jenkins through firewall (if ufw is enabled)
            if sudo ufw status | grep -q "active"; then
                sudo ufw allow 8080
                log "INFO" "Allowed port 8080 through UFW."
            fi

            # Verify Jenkins Daemon
            if sudo systemctl is-active --quiet jenkins; then
                log "INFO" "Jenkins daemon is running."
            else
                log "ERROR" "Jenkins daemon is not running."
                exit 1
            fi
            ;;
        *)
            log "ERROR" "Jenkins installation not supported for ${os}"
            exit 1
            ;;
    esac
}

# =============================================================================
#                           JENKINS PLUGIN INSTALLATION
# =============================================================================

install_jenkins_plugins() {
    log "INFO" "Installing necessary Jenkins plugins..."

    # Define the list of plugins to install
    local plugins=(
        "git"
        "github"
        "pipeline-utility-steps"
        "credentials-binding"
        "docker-workflow"
        "job-dsl"
        "blueocean"
        "slack"
        "htmlpublisher"
        "prometheus"
        "kubernetes"               # Kubernetes plugin
        "configuration-as-code"    # Jenkins Configuration as Code plugin
        "pipeline-stage-view"
        "role-strategy"
    )

    # Install plugins using Jenkins CLI
    if ! command -v java &> /dev/null; then
        log "ERROR" "Java is required to install Jenkins plugins."
        exit 1
    fi

    # Download Jenkins CLI
    if [ ! -f /tmp/jenkins-cli.jar ]; then
        wget -q "${JENKINS_URL}/jnlpJars/jenkins-cli.jar" -O /tmp/jenkins-cli.jar
    fi

    for plugin in "${plugins[@]}"; do
        if ! java -jar /tmp/jenkins-cli.jar -s "${JENKINS_URL}" -auth "${JENKINS_USER}:${JENKINS_API_TOKEN}" list-plugins | grep -qw "^${plugin}[[:space:]]"; then
            log "INFO" "Installing Jenkins plugin: ${plugin}"
            java -jar /tmp/jenkins-cli.jar -s "${JENKINS_URL}" -auth "${JENKINS_USER}:${JENKINS_API_TOKEN}" install-plugin "${plugin}" --noRestart
            log "INFO" "Installed Jenkins plugin: ${plugin}"
        else
            log "INFO" "Jenkins plugin already installed: ${plugin}"
        fi
    done

    # Restart Jenkins to apply plugin changes
    java -jar /tmp/jenkins-cli.jar -s "${JENKINS_URL}" -auth "${JENKINS_USER}:${JENKINS_API_TOKEN}" safe-restart
    log "INFO" "Jenkins restarted to apply plugins."

    # Cleanup
    rm -f /tmp/jenkins-cli.jar
}

# =============================================================================
#                           CONFIGURE JENKINS CREDENTIALS
# =============================================================================

configure_jenkins_credentials() {
    log "INFO" "Configuring Jenkins credentials..."

    # Check if required environment variables are set
    if [[ -z "${GITHUB_PAT}" || -z "${DOCKER_USERNAME}" || -z "${DOCKER_PASSWORD}" || -z "${KUBECONFIG_CONTENT}" || -z "${SLACK_TOKEN}" ]]; then
        log "ERROR" "One or more required environment variables are not set. Please export GITHUB_PAT, DOCKER_USERNAME, DOCKER_PASSWORD, KUBECONFIG_CONTENT, SLACK_TOKEN."
        exit 1
    fi

    # Download Jenkins CLI
    if [ ! -f /tmp/jenkins-cli.jar ]; then
        wget -q "${JENKINS_URL}/jnlpJars/jenkins-cli.jar" -O /tmp/jenkins-cli.jar
    fi

    # Add GitHub PAT as a secret text credential
    cat <<EOF > /tmp/github-pat.xml
<com.cloudbees.plugins.credentials.impl.StringCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>github-pat</id>
  <description>GitHub Personal Access Token</description>
  <secret>${GITHUB_PAT}</secret>
</com.cloudbees.plugins.credentials.impl.StringCredentialsImpl>
EOF

    java -jar /tmp/jenkins-cli.jar -s "${JENKINS_URL}" -auth "${JENKINS_USER}:${JENKINS_API_TOKEN}" create-credentials-by-xml system::system::jenkins "(global)" < /tmp/github-pat.xml
    log "INFO" "Added GitHub PAT as Jenkins credential (ID: github-pat)."

    # Add Docker credentials (username/password)
    cat <<EOF > /tmp/docker-credentials.xml
<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>${DOCKER_CREDENTIALS_ID}</id>
  <description>Docker Registry Credentials</description>
  <username>${DOCKER_USERNAME}</username>
  <password>${DOCKER_PASSWORD}</password>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
EOF

    java -jar /tmp/jenkins-cli.jar -s "${JENKINS_URL}" -auth "${JENKINS_USER}:${JENKINS_API_TOKEN}" create-credentials-by-xml system::system::jenkins "(global)" < /tmp/docker-credentials.xml
    log "INFO" "Added Docker credentials as Jenkins credential (ID: ${DOCKER_CREDENTIALS_ID})."

    # Add Kubeconfig credentials
    cat <<EOF > /tmp/kubeconfig-credentials.xml
<com.cloudbees.plugins.credentials.impl.StringCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>${KUBECONFIG_CREDENTIALS_ID}</id>
  <description>Kubeconfig Content</description>
  <secret>${KUBECONFIG_CONTENT}</secret>
</com.cloudbees.plugins.credentials.impl.StringCredentialsImpl>
EOF

    java -jar /tmp/jenkins-cli.jar -s "${JENKINS_URL}" -auth "${JENKINS_USER}:${JENKINS_API_TOKEN}" create-credentials-by-xml system::system::jenkins "(global)" < /tmp/kubeconfig-credentials.xml
    log "INFO" "Added Kubeconfig as Jenkins credential (ID: ${KUBECONFIG_CREDENTIALS_ID})."

    # Add Slack token as secret text credential
    cat <<EOF > /tmp/slack-credentials.xml
<com.cloudbees.plugins.credentials.impl.StringCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>${SLACK_CREDENTIALS_ID}</id>
  <description>Slack Token</description>
  <secret>${SLACK_TOKEN}</secret>
</com.cloudbees.plugins.credentials.impl.StringCredentialsImpl>
EOF

    java -jar /tmp/jenkins-cli.jar -s "${JENKINS_URL}" -auth "${JENKINS_USER}:${JENKINS_API_TOKEN}" create-credentials-by-xml system::system::jenkins "(global)" < /tmp/slack-credentials.xml
    log "INFO" "Added Slack token as Jenkins credential (ID: ${SLACK_CREDENTIALS_ID})."

    # Cleanup
    rm -f /tmp/github-pat.xml /tmp/docker-credentials.xml /tmp/kubeconfig-credentials.xml /tmp/slack-credentials.xml /tmp/jenkins-cli.jar
}

# =============================================================================
#                           CONFIGURE JENKINS WITH JCasC
# =============================================================================

configure_jenkins_jcasc() {
    log "INFO" "Configuring Jenkins with Configuration as Code (JCasC)..."

    # Ensure JCasC plugin is installed
    if ! java -jar /tmp/jenkins-cli.jar -s "${JENKINS_URL}" -auth "${JENKINS_USER}:${JENKINS_API_TOKEN}" list-plugins | grep -qw "^configuration-as-code[[:space:]]"; then
        log "ERROR" "Jenkins Configuration as Code plugin is not installed."
        exit 1
    fi

    # Create jenkins.yaml configuration file
    cat <<EOF > "${PROJECT_ROOT}/jenkins.yaml"
jenkins:
  systemMessage: "Configured by Jenkins Configuration as Code (JCasC)"
  clouds:
    - kubernetes:
        name: "kubernetes"
        serverUrl: "https://kubernetes.default.svc.cluster.local"
        skipTlsVerify: true
        namespace: "jenkins"
        jenkinsUrl: "http://jenkins.jenkins.svc.cluster.local:8080"
        jenkinsTunnel: "jenkins:50000"
        containerCapStr: "10"
        credentialsId: "${KUBECONFIG_CREDENTIALS_ID}"
        podRetention: "Always"
        templates:
          - name: "jenkins-agent"
            label: "kubernetes-agent"
            nodeUsageMode: "NORMAL"
            yaml: |
              kind: Pod
              apiVersion: v1
              metadata:
                labels:
                  jenkins: "slave"
              spec:
                serviceAccountName: jenkins
                containers:
                  - name: jnlp
                    image: jenkins/inbound-agent:4.10-3
                    args: ['\$(JENKINS_SECRET)', '\$(JENKINS_NAME)']
                    resources:
                      requests:
                        cpu: "500m"
                        memory: "512Mi"
                      limits:
                        cpu: "1"
                        memory: "1Gi"
EOF

    # Copy jenkins.yaml to Jenkins home
    sudo cp "${PROJECT_ROOT}/jenkins.yaml" /var/lib/jenkins/jenkins.yaml
    sudo chown jenkins:jenkins /var/lib/jenkins/jenkins.yaml

    # Set JCasC configuration path in Jenkins arguments
    if ! grep -q "CASC_JENKINS_CONFIG" /etc/default/jenkins; then
        echo 'JAVA_ARGS="$JAVA_ARGS -Dcasc.jenkins.config=/var/lib/jenkins/jenkins.yaml"' | sudo tee -a /etc/default/jenkins
    fi

    # Restart Jenkins
    sudo systemctl restart jenkins
    log "SUCCESS" "Jenkins configured with JCasC."
}

# =============================================================================
#                           CREATE JENKINSFILE
# =============================================================================

create_jenkinsfile() {
    log "INFO" "Creating Jenkinsfile..."

    local JENKINSFILE_PATH="${PROJECT_ROOT}/Jenkinsfile"

    if [[ ! -f "${JENKINSFILE_PATH}" ]]; then
        cat <<EOF > "${JENKINSFILE_PATH}"
pipeline {
    agent {
        kubernetes {
            label 'kubernetes-agent'
            defaultContainer 'jnlp'
        }
    }
    environment {
        DOCKER_REGISTRY = 'your-docker-registry.com'
        DOCKER_CREDENTIALS = credentials('docker-credentials-id')
        GITHUB_PAT = credentials('github-pat') // Jenkins credential ID for GitHub PAT
        SLACK_CHANNEL = '${SLACK_CHANNEL}'
        SLACK_CREDENTIALS = credentials('slack-credentials-id') // Slack Token
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    githubNotify context: 'CI', status: 'PENDING', description: 'Build started', token: "${GITHUB_PAT}"
                }
            }
            post {
                failure {
                    slackSend(channel: "${SLACK_CHANNEL}", color: 'danger', message: "Checkout failed: \${env.JOB_NAME} #\${env.BUILD_NUMBER}")
                    githubNotify context: 'CI', status: 'FAILURE', description: 'Checkout failed', token: "${GITHUB_PAT}"
                }
            }
        }

        stage('Build') {
            parallel {
                stage('Build AI Chatbot') {
                    steps {
                        script {
                            try {
                                docker.build("\${DOCKER_REGISTRY}/ai-platform/ai-chatbot:latest", "-f deployment/docker/ai_chatbot.Dockerfile .")
                            } catch (Exception e) {
                                slackSend(channel: "${SLACK_CHANNEL}", color: 'danger', message: "Build AI Chatbot failed: \${e.getMessage()}")
                                throw e
                            }
                        }
                    }
                    post {
                        failure {
                            githubNotify context: 'CI', status: 'FAILURE', description: 'Build AI Chatbot failed', token: "${GITHUB_PAT}"
                        }
                    }
                }

                stage('Build Go Recommender Service') {
                    steps {
                        script {
                            try {
                                docker.build("\${DOCKER_REGISTRY}/ai-platform/go-recommender-service:latest", "-f deployment/docker/go_recommender_service.Dockerfile .")
                            } catch (Exception e) {
                                slackSend(channel: "${SLACK_CHANNEL}", color: 'danger', message: "Build Go Recommender Service failed: \${e.getMessage()}")
                                throw e
                            }
                        }
                    }
                    post {
                        failure {
                            githubNotify context: 'CI', status: 'FAILURE', description: 'Build Go Recommender Service failed', token: "${GITHUB_PAT}"
                        }
                    }
                }

                stage('Build Python Chatbot') {
                    steps {
                        script {
                            try {
                                docker.build("\${DOCKER_REGISTRY}/ai-platform/python-chatbot:latest", "-f deployment/docker/python_chatbot.Dockerfile .")
                            } catch (Exception e) {
                                slackSend(channel: "${SLACK_CHANNEL}", color: 'danger', message: "Build Python Chatbot failed: \${e.getMessage()}")
                                throw e
                            }
                        }
                    }
                    post {
                        failure {
                            githubNotify context: 'CI', status: 'FAILURE', description: 'Build Python Chatbot failed', token: "${GITHUB_PAT}"
                        }
                    }
                }
                // Add additional parallel build stages as needed
            }
        }

        stage('Push Images') {
            parallel {
                stage('Push AI Chatbot') {
                    steps {
                        retry(3) {
                            script {
                                docker.withRegistry("https://\${DOCKER_REGISTRY}", 'docker-credentials-id') {
                                    sh 'docker push \${DOCKER_REGISTRY}/ai-platform/ai-chatbot:latest'
                                }
                            }
                        }
                    }
                    post {
                        failure {
                            slackSend(channel: "${SLACK_CHANNEL}", color: 'danger', message: "Push AI Chatbot failed after retries: \${env.JOB_NAME} #\${env.BUILD_NUMBER}")
                            githubNotify context: 'CI', status: 'FAILURE', description: 'Push AI Chatbot failed', token: "${GITHUB_PAT}"
                        }
                    }
                }

                stage('Push Go Recommender Service') {
                    steps {
                        retry(3) {
                            script {
                                docker.withRegistry("https://\${DOCKER_REGISTRY}", 'docker-credentials-id') {
                                    sh 'docker push \${DOCKER_REGISTRY}/ai-platform/go-recommender-service:latest'
                                }
                            }
                        }
                    }
                    post {
                        failure {
                            slackSend(channel: "${SLACK_CHANNEL}", color: 'danger', message: "Push Go Recommender Service failed after retries: \${env.JOB_NAME} #\${env.BUILD_NUMBER}")
                            githubNotify context: 'CI', status: 'FAILURE', description: 'Push Go Recommender Service failed', token: "${GITHUB_PAT}"
                        }
                    }
                }

                stage('Push Python Chatbot') {
                    steps {
                        retry(3) {
                            script {
                                docker.withRegistry("https://\${DOCKER_REGISTRY}", 'docker-credentials-id') {
                                    sh 'docker push \${DOCKER_REGISTRY}/ai-platform/python-chatbot:latest'
                                }
                            }
                        }
                    }
                    post {
                        failure {
                            slackSend(channel: "${SLACK_CHANNEL}", color: 'danger', message: "Push Python Chatbot failed after retries: \${env.JOB_NAME} #\${env.BUILD_NUMBER}")
                            githubNotify context: 'CI', status: 'FAILURE', description: 'Push Python Chatbot failed', token: "${GITHUB_PAT}"
                        }
                    }
                }
                // Add additional parallel push stages as needed
            }
        }

        stage('Deploy') {
            steps {
                script {
                    withKubeConfig([credentialsId: 'kubeconfig-credentials-id']) {
                        sh 'kubectl apply -f deployment/k8s/'
                    }
                }
            }
            post {
                success {
                    slackSend(channel: "${SLACK_CHANNEL}", color: 'good', message: "Deployment succeeded: \${env.JOB_NAME} #\${env.BUILD_NUMBER}")
                }
                failure {
                    slackSend(channel: "${SLACK_CHANNEL}", color: 'danger', message: "Deployment failed: \${env.JOB_NAME} #\${env.BUILD_NUMBER}")
                    githubNotify context: 'CI', status: 'FAILURE', description: 'Deployment failed', token: "${GITHUB_PAT}"
                }
            }
        }

        stage('Test') {
            steps {
                script {
                    # Example: Run tests and generate coverage report
                    sh 'npm test -- --coverage'
                }
            }
            post {
                always {
                    publishHTML(target: [
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'coverage',
                        reportFiles: 'index.html',
                        reportName: "Test Coverage Report"
                    ])
                }
                failure {
                    slackSend(channel: "${SLACK_CHANNEL}", color: 'danger', message: "Tests failed: \${env.JOB_NAME} #\${env.BUILD_NUMBER}")
                }
            }
        }
    }

    post {
        failure {
            slackSend(channel: "${SLACK_CHANNEL}", color: 'danger', message: "Build failed: \${env.JOB_NAME} #\${env.BUILD_NUMBER}")
            githubNotify context: 'CI', status: 'FAILURE', description: 'Build failed', token: "${GITHUB_PAT}"
        }
        success {
            slackSend(channel: "${SLACK_CHANNEL}", color: 'good', message: "Build succeeded: \${env.JOB_NAME} #\${env.BUILD_NUMBER}")
            githubNotify context: 'CI', status: 'SUCCESS', description: 'Build succeeded', token: "${GITHUB_PAT}"
        }
        always {
            cleanWs()
        }
    }
}
EOF
        log "SUCCESS" "Jenkinsfile created at ${JENKINSFILE_PATH}."
    fi
}

# =============================================================================
#                           CREATE JOB DSL SCRIPT
# =============================================================================

create_job_dsl_script() {
    log "INFO" "Creating Job DSL script..."

    local JOB_DSL_SCRIPT="${PROJECT_ROOT}/jenkins_job_dsl.groovy"

    if [[ ! -f "${JOB_DSL_SCRIPT}" ]]; then
        cat <<EOF > "${JOB_DSL_SCRIPT}"
pipelineJob('AI_Platform_CI_CD') {
    description('CI/CD Pipeline for AI Platform')
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url("https://github.com/${REPO_OWNER}/${REPO_NAME}.git")
                        credentials('github-pat') // Jenkins credential ID for GitHub PAT
                    }
                    branches('*/main')
                }
            }
            scriptPath('Jenkinsfile') // Path to your Jenkinsfile in the repository
        }
    }
    triggers {
        githubPush()
    }
    parameters {
        stringParam('ENVIRONMENT', 'production', 'Deployment environment')
    }
}
EOF
        log "SUCCESS" "Job DSL script created at ${JOB_DSL_SCRIPT}."
    else
        log "INFO" "Job DSL script already exists at ${JOB_DSL_SCRIPT}."
    fi
}

# =============================================================================
#                           CREATE JENKINS JOB USING JOB DSL
# =============================================================================

create_jenkins_job() {
    log "INFO" "Creating Jenkins job using Job DSL..."

    local JOB_DSL_SCRIPT="${PROJECT_ROOT}/jenkins_job_dsl.groovy"

    if [[ ! -f "${JOB_DSL_SCRIPT}" ]]; then
        log "ERROR" "Job DSL script not found at ${JOB_DSL_SCRIPT}. Please create it before proceeding."
        exit 1
    fi

    # Download Jenkins CLI
    if [ ! -f /tmp/jenkins-cli.jar ]; then
        wget -q "${JENKINS_URL}/jnlpJars/jenkins-cli.jar" -O /tmp/jenkins-cli.jar
    fi

    # Execute Job DSL script
    java -jar /tmp/jenkins-cli.jar -s "${JENKINS_URL}" -auth "${JENKINS_USER}:${JENKINS_API_TOKEN}" groovy = < "${JOB_DSL_SCRIPT}"
    log "SUCCESS" "Jenkins job created successfully using Job DSL."

    # Cleanup
    rm -f /tmp/jenkins-cli.jar
}

# =============================================================================
#                           CONFIGURE GITHUB WEBHOOK
# =============================================================================

configure_github_webhook() {
    log "INFO" "Configuring GitHub Webhook via API..."

    # Validate environment variables
    if [[ -z "${GITHUB_PAT}" || -z "${REPO_OWNER}" || -z "${REPO_NAME}" ]]; then
        log "ERROR" "GITHUB_PAT, REPO_OWNER, and REPO_NAME must be set."
        exit 1
    fi

    # Create Webhook payload
    read -r -d '' PAYLOAD <<EOF
{
  "name": "web",
  "active": true,
  "events": [
    "push",
    "pull_request"
  ],
  "config": {
    "url": "${JENKINS_URL}/github-webhook/",
    "content_type": "json",
    "secret": "${WEBHOOK_SECRET}",
    "insecure_ssl": "0"
  }
}
EOF

    # Check if webhook already exists
    EXISTING_WEBHOOK=$(curl -s -H "Authorization: token ${GITHUB_PAT}" \
        "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/hooks" | grep -c "${JENKINS_URL}/github-webhook/")

    if [[ "${EXISTING_WEBHOOK}" -eq 0 ]]; then
        # Create Webhook via GitHub API
        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
            -H "Authorization: token ${GITHUB_PAT}" \
            -H "Accept: application/vnd.github.v3+json" \
            "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/hooks" \
            -d "${PAYLOAD}")

        if [[ "${RESPONSE}" == "201" ]]; then
            log "SUCCESS" "Webhook created successfully."
        else
            log "ERROR" "Failed to create webhook. HTTP Status: ${RESPONSE}"
            exit 1
        fi
    else
        log "INFO" "Webhook already exists. Skipping creation."
    fi
}

# =============================================================================
#                           INSTALL MONITORING TOOLS
# =============================================================================

install_monitoring_tools() {
    log "INFO" "Installing Prometheus and Grafana via Helm..."

    # Add Helm repositories
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update

    # Create monitoring namespace
    kubectl create namespace monitoring || log "INFO" "Namespace 'monitoring' already exists."

    # Install or upgrade Prometheus
    helm upgrade --install prometheus prometheus-community/prometheus --namespace monitoring --version "${PROMETHEUS_VERSION}" --wait
    log "SUCCESS" "Prometheus installed/upgraded successfully."

    # Install or upgrade Grafana
    ADMIN_PASSWORD=$(generate_secure_password 16)
    helm upgrade --install grafana grafana/grafana --namespace monitoring --version "${GRAFANA_VERSION}" --set admin.password="${ADMIN_PASSWORD}" --wait
    log "SUCCESS" "Grafana installed/upgraded successfully."

    # Provide instructions to retrieve Grafana admin password securely
    log "INFO" "Retrieve Grafana admin password using the following command:"
    log "INFO" "kubectl get secret --namespace monitoring grafana -o jsonpath=\"{.data.admin-password}\" | base64 --decode ; echo"
}

# =============================================================================
#                           CREATE JENKINS RBAC AND NAMESPACE
# =============================================================================

create_jenkins_rbac_and_namespace() {
    log "INFO" "Creating Jenkins namespace and RBAC..."

    # Create Jenkins namespace
    kubectl create namespace jenkins || log "INFO" "Namespace 'jenkins' already exists."

    # Create Jenkins ServiceAccount and RBAC
    cat > "${PROJECT_ROOT}/deployment/k8s/jenkins-rbac.yaml" <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins
  namespace: jenkins

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: jenkins-clusterrole
rules:
  - apiGroups: ["", "apps", "extensions", "batch"]
    resources: ["pods", "pods/exec", "pods/log", "services", "deployments", "replicasets", "jobs"]
    verbs: ["get", "watch", "list", "create", "delete", "patch", "update"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: jenkins-clusterrolebinding
subjects:
  - kind: ServiceAccount
    name: jenkins
    namespace: jenkins
roleRef:
  kind: ClusterRole
  name: jenkins-clusterrole
  apiGroup: rbac.authorization.k8s.io
EOF

    # Apply RBAC configuration
    kubectl apply -f "${PROJECT_ROOT}/deployment/k8s/jenkins-rbac.yaml"
    log "SUCCESS" "Jenkins namespace and RBAC configured."
}

# =============================================================================
#                           BACKUP AND RECOVERY
# =============================================================================

backup_files() {
    local backup_dir=$1
    shift
    local files_to_backup=("$@")

    if [ ! -d "${backup_dir}" ]; then
        mkdir -p "${backup_dir}"
    fi

    for file in "${files_to_backup[@]}"; do
        if [ -f "${file}" ]; then
            cp "${file}" "${backup_dir}/${file##*/}.$(date +%Y%m%d%H%M%S)"
            log "INFO" "Backed up ${file} to ${backup_dir}/${file##*/}.$(date +%Y%m%d%H%M%S)"
        fi
    done
}

# =============================================================================
#                           TESTING AND VALIDATION
# =============================================================================

# Unit Test for install_package function
unit_test_install_package() {
    local package_name="curl"
    local package_manager="apt-get"

    if ! install_package "${package_name}" "${package_manager}"; then
        log "ERROR" "Test failed: Failed to install ${package_name} using ${package_manager}"
        exit 1
    fi
    log "SUCCESS" "Test passed: Successfully installed ${package_name} using ${package_manager}"
}

# =============================================================================
#                           FINALIZATION
# =============================================================================

finalize_setup() {
    log "SUCCESS" "===== AI Platform Setup Completed Successfully ====="
    log "INFO" "Project root: ${PROJECT_ROOT}"
    log "INFO" "Please log out and log back in to apply Docker, Go environment variables."
    log "INFO" "You can now start building Docker images and deploy the platform."
    log "INFO" "Please ensure to configure your environment variables in the .env file."
    log "INFO" "Access Jenkins at ${JENKINS_URL}."
    log "INFO" "Retrieve the initial Jenkins admin password from /var/lib/jenkins/secrets/initialAdminPassword if not already done."
    log "INFO" "Configure Grafana dashboards as needed."
    log "INFO" "Ensure that Jenkins is connected to Kubernetes and functioning properly."
}

# =============================================================================
#                           MAIN EXECUTION
# =============================================================================

main() {
    # Parse command-line arguments
    parse_args "$@"

    # Start logging
    init_logging

    # Validate environment variables
    validate_env_vars

    # Install dependencies
    install_dependencies

    # Create project structure
    create_project_structure
    init_git_repo

    # Create configurations
    create_config_files
    create_kubernetes_manifests
    create_monitoring_configurations

    # Install Docker if not present
    if ! command -v docker &> /dev/null; then
        install_docker
    else
        log "INFO" "Docker is already installed."
    fi

    # Install Jenkins
    install_jenkins

    # Install Jenkins plugins
    install_jenkins_plugins

    # Configure Jenkins credentials
    configure_jenkins_credentials

    # Configure Jenkins with JCasC
    configure_jenkins_jcasc

    # Create Jenkins RBAC and namespace
    create_jenkins_rbac_and_namespace

    # Create Jenkinsfile
    create_jenkinsfile

    # Create Job DSL script
    create_job_dsl_script

    # Create Jenkins job using Job DSL
    create_jenkins_job

    # Configure GitHub webhook
    configure_github_webhook

    # Install monitoring tools
    install_monitoring_tools

    # Backup critical files
    backup_files "${BACKUP_DIR}" \
        "${PROJECT_ROOT}/.gitignore" \
        "${PROJECT_ROOT}/.gitattributes" \
        "${PROJECT_ROOT}/.env.example" \
        "${PROJECT_ROOT}/docker-compose.yml" \
        "${PROJECT_ROOT}/Jenkinsfile"

    # Run unit tests
    unit_test_install_package

    # Finalize setup
    finalize_setup
}

# Execute main function with all passed arguments
main "$@"
