# Use Ubuntu 20.04 as base
FROM ubuntu:20.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    python3-pip \
    python3-dev \
    wget \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install ROCm libraries
RUN apt-get update && apt-get install -y \
    rocm-dkms \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables for ROCm
ENV ROCM_HOME=/opt/rocm
ENV LD_LIBRARY_PATH=$ROCM_HOME/lib:$LD_LIBRARY_PATH
ENV PATH=$ROCM_HOME/bin:$PATH

# Install Python dependencies
COPY docker/inference_server/requirements.txt .
RUN pip3 install --upgrade pip
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy inference server script
COPY docker/inference_server/server.py .

# Expose port
EXPOSE 8000

# Start the inference server
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8000"]
