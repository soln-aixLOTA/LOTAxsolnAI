# shellcheck disable=SC2006
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
