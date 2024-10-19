# shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
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
