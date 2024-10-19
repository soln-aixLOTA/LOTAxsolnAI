# shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
# docs/setup.md

# Setup Guide

## Prerequisites

- **Docker & Docker Compose:** Ensure Docker and Docker Compose are installed on your system.
- **Git:** To clone the repository.
- **Python 3.9+, pip3:** For local development (optional if using Docker).

## Steps

1. **Clone the Repository:**

    ```bash
    git clone "https://github.com/dislovemartin/gpt4o_finetuning_project.git"
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
