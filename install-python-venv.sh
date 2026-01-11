#!/bin/bash

# Python Virtual Environment Installation Script
# Installs Python 3.8+ and sets up virtual environment for Kafka-Flink Pipeline

set -e

# Color codes for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

echo "============================================"
echo "Python Virtual Environment Setup"
echo "Kafka-Flink-Elasticsearch Pipeline"
echo "============================================"
echo ""

# Check if running on Linux
if [ ! -f /etc/os-release ]; then
    print_error "Cannot detect OS. This script is for Linux systems."
    exit 1
fi

# Check if running as root or with sudo
if [ "$EUID" -eq 0 ]; then
    print_error "Do not run this script as root or with sudo"
    print_info "The script will ask for sudo password when needed"
    exit 1
fi

# Detect existing Python installation
print_step "Detecting Python installation..."
echo ""

PYTHON_CMD=""
PYTHON_VERSION=""

# Check for Python 3.8 or higher
for cmd in python3.12 python3.11 python3.10 python3.9 python3.8 python3; do
    if command -v $cmd &> /dev/null; then
        VERSION=$($cmd --version 2>&1 | grep -oP '\d+\.\d+' | head -1)
        MAJOR=$(echo $VERSION | cut -d. -f1)
        MINOR=$(echo $VERSION | cut -d. -f2)

        if [ "$MAJOR" -eq 3 ] && [ "$MINOR" -ge 8 ]; then
            PYTHON_CMD=$cmd
            PYTHON_VERSION=$VERSION
            print_info "Found compatible Python: $cmd (version $VERSION)"
            break
        fi
    fi
done

# If no compatible Python found, offer to install
if [ -z "$PYTHON_CMD" ]; then
    print_warn "Python 3.8 or higher not found!"
    echo ""
    echo "Available Python versions to install:"
    echo "  1) Python 3.8 (Recommended)"
    echo "  2) Python 3.9"
    echo "  3) Python 3.11"
    echo "  4) Python 3.12"
    echo ""
    read -p "Select version to install [1-4] (default: 1): " PYTHON_CHOICE
    PYTHON_CHOICE=${PYTHON_CHOICE:-1}

    case $PYTHON_CHOICE in
        1)
            INSTALL_VERSION="3.8"
            ;;
        2)
            INSTALL_VERSION="3.9"
            ;;
        3)
            INSTALL_VERSION="3.11"
            ;;
        4)
            INSTALL_VERSION="3.12"
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac

    print_step "Installing Python $INSTALL_VERSION..."
    echo ""

    # Update package list
    print_info "Updating package list..."
    sudo apt update

    # Install software-properties-common for add-apt-repository
    print_info "Installing prerequisites..."
    sudo apt install -y software-properties-common

    # Add deadsnakes PPA
    print_info "Adding deadsnakes PPA..."
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt update

    # Install Python and required packages
    print_info "Installing Python $INSTALL_VERSION and development tools..."
    sudo apt install -y \
        python$INSTALL_VERSION \
        python$INSTALL_VERSION-venv \
        python$INSTALL_VERSION-dev \
        build-essential

    PYTHON_CMD="python$INSTALL_VERSION"
    PYTHON_VERSION=$INSTALL_VERSION

    print_info "Python $INSTALL_VERSION installed successfully"
    echo ""
else
    # Check if venv module is available
    if ! $PYTHON_CMD -m venv --help &> /dev/null; then
        print_warn "venv module not found for $PYTHON_CMD"
        print_step "Installing venv module..."

        # Extract version number for package name
        if [[ $PYTHON_CMD == python3 ]]; then
            sudo apt install -y python3-venv build-essential python3-dev
        else
            VERSION_NUM=$(echo $PYTHON_CMD | grep -oP '\d+\.\d+')
            sudo apt install -y python${VERSION_NUM}-venv build-essential python${VERSION_NUM}-dev
        fi

        print_info "venv module installed"
        echo ""
    fi
fi

# Check if virtual environment already exists
VENV_DIR="venv"

if [ -d "$VENV_DIR" ]; then
    print_warn "Virtual environment '$VENV_DIR' already exists"
    echo ""
    read -p "Do you want to recreate it? [y/N]: " RECREATE
    RECREATE=${RECREATE:-N}

    if [[ "$RECREATE" =~ ^[Yy]$ ]]; then
        print_info "Removing existing virtual environment..."
        rm -rf "$VENV_DIR"
    else
        print_info "Using existing virtual environment"
        echo ""
        print_step "Activating virtual environment..."
        source "$VENV_DIR/bin/activate"

        print_step "Upgrading pip..."
        pip install --upgrade pip --quiet

        if [ -f "requirements.txt" ]; then
            print_step "Installing/updating requirements..."
            pip install -r requirements.txt --quiet
            print_info "Requirements installed successfully"
        else
            print_warn "requirements.txt not found in current directory"
        fi

        echo ""
        print_info "Virtual environment is ready!"
        print_info "To activate it in the future, run:"
        echo "  source $VENV_DIR/bin/activate"
        echo ""
        exit 0
    fi
fi

# Create virtual environment
print_step "Creating virtual environment with $PYTHON_CMD..."
$PYTHON_CMD -m venv "$VENV_DIR"
print_info "Virtual environment '$VENV_DIR' created"
echo ""

# Activate virtual environment
print_step "Activating virtual environment..."
source "$VENV_DIR/bin/activate"
print_info "Virtual environment activated"
echo ""

# Upgrade pip
print_step "Upgrading pip..."
pip install --upgrade pip --quiet
print_info "pip upgraded to latest version"
echo ""

# Install requirements if requirements.txt exists
if [ -f "requirements.txt" ]; then
    print_step "Installing project requirements..."
    echo ""
    print_info "This may take a few minutes..."

    if pip install -r requirements.txt; then
        print_info "All requirements installed successfully"
    else
        print_error "Failed to install some requirements"
        print_warn "You may need to install additional system packages"
        exit 1
    fi
else
    print_warn "requirements.txt not found in current directory"
    print_info "You can install requirements later with:"
    echo "  pip install -r requirements.txt"
fi

echo ""

# Verify installation
print_step "Verifying installation..."
echo ""

# Check installed packages
print_info "Installed packages:"
pip list | grep -E "kafka-python|apache-flink|hdfs|rich" || true
echo ""

# Test imports
print_info "Testing imports..."
if python -c "from kafka import KafkaProducer; from pyflink.datastream import StreamExecutionEnvironment; print('✓ All imports successful!')" 2>/dev/null; then
    print_info "All required modules are working correctly"
else
    print_warn "Some imports failed. This may be expected if requirements.txt wasn't found."
fi

echo ""
echo "============================================"
echo "Installation Complete!"
echo "============================================"
echo ""
print_info "Python version: $PYTHON_VERSION"
print_info "Virtual environment: $VENV_DIR"
echo ""
print_info "The virtual environment is currently active."
echo ""
echo "Usage:"
echo "  • Deactivate: ${GREEN}deactivate${NC}"
echo "  • Reactivate: ${GREEN}source $VENV_DIR/bin/activate${NC}"
echo ""
echo "Next steps:"
echo "  1. Make sure Docker is running"
echo "  2. Start the pipeline: ${GREEN}./start-pipeline.sh${NC}"
echo ""
