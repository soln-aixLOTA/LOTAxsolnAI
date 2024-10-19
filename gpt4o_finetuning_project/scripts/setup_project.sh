# shellcheck disable=SC2006,SC1009,SC1073,SC1065,SC2215,SC2211,SC2046,SC2296
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
if [[ "$(echo " < 3.9" | bc -l)" -eq 1 ]]; then
    error_exit "Python 3.9 or higher is required. Current version: "
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
