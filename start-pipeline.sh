#!/bin/bash

# Kafka-Flink-Elasticsearch Pipeline - Automated Installer
# This script provides an interactive setup with optional Hadoop/HDFS support

set -e  # Exit on any error

# Color codes for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored messages
print_header() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

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
    echo -e "${BLUE}[STEP $1]${NC} $2"
}

# Check if Docker is installed
print_info "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed!"
    echo ""
    echo "Docker is required to run this pipeline."
    echo ""
    read -p "Would you like to install Docker now? [Y/n]: " INSTALL_DOCKER
    INSTALL_DOCKER=${INSTALL_DOCKER:-Y}

    if [[ "$INSTALL_DOCKER" =~ ^[Yy]$ ]]; then
        print_info "Running Docker installation script..."
        echo ""

        # Check if installation script exists
        if [ -f "install-docker-ubuntu.sh" ]; then
            chmod +x install-docker-ubuntu.sh
            sudo ./install-docker-ubuntu.sh

            print_info "Docker installation completed!"
            echo ""
            print_warn "Please log out and log back in, or run: newgrp docker"
            print_warn "Then re-run this script: ./start-pipeline.sh"
            exit 0
        else
            print_error "Installation script 'install-docker-ubuntu.sh' not found!"
            echo ""
            echo "Please install Docker manually:"
            echo "  • Ubuntu/Debian: https://docs.docker.com/engine/install/ubuntu/"
            echo "  • Or see DOCKER_INSTALLATION_GUIDE.md for detailed instructions"
            exit 1
        fi
    else
        print_error "Docker is required. Installation cancelled."
        echo ""
        echo "Please install Docker manually and re-run this script."
        echo "See DOCKER_INSTALLATION_GUIDE.md for instructions."
        exit 1
    fi
else
    print_info "Docker is installed ($(docker --version))"
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    print_error "Docker daemon is not running!"
    echo ""
    echo "Please start Docker service:"
    echo "  sudo systemctl start docker"
    exit 1
else
    print_info "Docker daemon is running"
fi

# Check if user can run Docker without sudo
if ! docker ps &> /dev/null; then
    print_warn "Cannot run Docker without sudo"
    print_warn "You may need to add your user to the docker group:"
    echo "  sudo usermod -aG docker \$USER"
    echo "  newgrp docker"
    echo ""
    print_warn "Attempting to continue with sudo..."
    # Check if sudo works
    if ! sudo docker ps &> /dev/null; then
        print_error "Cannot run Docker even with sudo!"
        exit 1
    fi
else
    print_info "Docker permissions configured correctly"
fi
echo ""

# Welcome banner
clear
print_header "Kafka-Flink-Elasticsearch Pipeline Installer"
echo ""
echo "This installer will set up the complete real-time data pipeline:"
echo "  • Apache Kafka (message streaming)"
echo "  • Apache Flink (stream processing)"
echo "  • Elasticsearch (data storage & search)"
echo "  • Kibana (data visualization)"
echo ""
echo "Optional: Apache Hadoop HDFS (long-term archival storage)"
echo ""

# Ask user for installation type
echo -e "${YELLOW}Choose installation type:${NC}"
echo "  1) Basic Pipeline (Kafka → Flink → Elasticsearch → Kibana)"
echo "  2) Full Stack with Hadoop (includes HDFS for long-term storage)"
echo ""
read -p "Enter your choice [1-2] (default: 1): " INSTALL_CHOICE
INSTALL_CHOICE=${INSTALL_CHOICE:-1}

# Set installation flags
INSTALL_HADOOP=false
if [ "$INSTALL_CHOICE" == "2" ]; then
    INSTALL_HADOOP=true
    print_info "Full Stack installation selected (with Hadoop HDFS)"
else
    print_info "Basic Pipeline installation selected (without Hadoop)"
fi
echo ""

# Detect Python version
print_info "Detecting Python installation..."
PYTHON_CMD=""
for cmd in python3.10 python3.9 python3.8 python3.11 python3.12 python3; do
    if command -v $cmd &> /dev/null; then
        VERSION=$($cmd --version 2>&1 | grep -oP '\d+\.\d+' | head -1)
        MAJOR=$(echo $VERSION | cut -d. -f1)
        MINOR=$(echo $VERSION | cut -d. -f2)
        if [ "$MAJOR" -eq 3 ] && [ "$MINOR" -ge 8 ]; then
            PYTHON_CMD=$cmd
            print_info "Found compatible Python: $cmd (version $VERSION)"
            break
        fi
    fi
done

if [ -z "$PYTHON_CMD" ]; then
    print_error "Python 3.8 or higher is required but not found!"
    echo ""
    echo "Please install Python 3.8+ using one of these methods:"
    echo "  sudo apt install python3.10 python3.10-venv"
    echo "  sudo apt install python3.8 python3.8-venv"
    echo ""
    echo "For detailed instructions, see install_python_venv.md"
    exit 1
fi
echo ""

# Check if /etc/hosts needs configuration for Hadoop
if [ "$INSTALL_HADOOP" = true ]; then
    print_info "Checking /etc/hosts configuration..."
    if ! grep -q "namenode datanode kafka resourcemanager" /etc/hosts; then
        print_warn "/etc/hosts configuration needed for Hadoop"
        echo ""
        echo "The following line needs to be added to /etc/hosts:"
        echo "  127.0.0.1 namenode datanode kafka resourcemanager"
        echo ""
        read -p "Add this line automatically? [Y/n]: " ADD_HOSTS
        ADD_HOSTS=${ADD_HOSTS:-Y}
        if [[ "$ADD_HOSTS" =~ ^[Yy]$ ]]; then
            echo "127.0.0.1 namenode datanode kafka resourcemanager" | sudo tee -a /etc/hosts > /dev/null
            print_info "/etc/hosts updated successfully"
        else
            print_warn "Please add the line manually to /etc/hosts and re-run this script"
            exit 1
        fi
    else
        print_info "/etc/hosts already configured for Hadoop"
    fi
    echo ""
fi

# Confirmation before proceeding
echo -e "${YELLOW}Ready to install:${NC}"
if [ "$INSTALL_HADOOP" = true ]; then
    echo "  ✓ Docker network (bigdata-network)"
    echo "  ✓ Flink image with Python support"
    echo "  ✓ Hadoop services (NameNode, DataNode, YARN)"
    echo "  ✓ Kafka, Flink, Elasticsearch, Kibana"
    echo "  ✓ Python virtual environment with dependencies"
    echo ""
    echo "System requirements: 16GB RAM, 8+ CPU cores"
else
    echo "  ✓ Docker network (bigdata-network)"
    echo "  ✓ Flink image with Python support"
    echo "  ✓ Kafka, Flink, Elasticsearch, Kibana"
    echo "  ✓ Python virtual environment with dependencies"
    echo ""
    echo "System requirements: 6GB RAM, 4+ CPU cores"
fi
echo ""
read -p "Continue with installation? [Y/n]: " CONFIRM
CONFIRM=${CONFIRM:-Y}
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    print_warn "Installation cancelled by user"
    exit 0
fi

echo ""
print_header "Starting Installation"
echo ""

# Step 1: Create Docker network
print_step "1/8" "Creating Docker network..."
if ! docker network inspect bigdata-network >/dev/null 2>&1; then
    docker network create bigdata-network
    print_info "Network 'bigdata-network' created successfully"
else
    print_warn "Network 'bigdata-network' already exists (skipping)"
fi
echo ""

# Step 2: Build custom Flink image
print_step "2/8" "Building custom Flink image with Python support..."
if docker images | grep -q "flink-python.*1.18"; then
    print_warn "Flink image already exists (skipping build)"
else
    docker build -t flink-python:1.18 -f Dockerfile.flink .
    print_info "Flink image built successfully"
fi
echo ""

# Step 3: Start Hadoop services (if selected)
if [ "$INSTALL_HADOOP" = true ]; then
    print_step "3/8" "Starting Hadoop services (HDFS, YARN)..."
    cd docker-hadoop

    # Clean up any existing containers to avoid conflicts
    print_info "Cleaning up existing Hadoop containers..."
    docker-compose down 2>/dev/null || true

    # Start Hadoop services
    print_info "Starting Hadoop containers..."
    docker-compose up -d
    cd ..
    print_info "Hadoop services started"
    print_info "Waiting 30 seconds for Hadoop to initialize..."
    sleep 30
    echo ""
else
    print_step "3/8" "Skipping Hadoop installation (basic pipeline mode)"
    echo ""
fi

# Step 4: Start main pipeline services
print_step "4/8" "Starting Kafka, Flink, Elasticsearch, and Kibana..."
docker-compose up -d
print_info "All services started"
print_info "Waiting 20 seconds for services to initialize..."
sleep 20
echo ""

# Step 5: Initialize HDFS (if Hadoop installed)
if [ "$INSTALL_HADOOP" = true ]; then
    print_step "5/8" "Initializing HDFS directory for Kafka data..."
    bash init_hdfs.sh
    print_info "HDFS directory initialized"
    echo ""
else
    print_step "5/8" "Skipping HDFS initialization (basic pipeline mode)"
    echo ""
fi

# Step 6: Setup Python virtual environment
print_step "6/8" "Setting up Python virtual environment..."
if [ ! -d "venv" ]; then
    print_info "Creating virtual environment with $PYTHON_CMD..."
    $PYTHON_CMD -m venv venv
    print_info "Virtual environment created"
else
    print_warn "Virtual environment 'venv' already exists"
fi

print_info "Installing Python dependencies..."
source venv/bin/activate
pip install --upgrade pip --quiet
pip install -r requirements.txt --quiet
deactivate
print_info "Python dependencies installed successfully"
echo ""

# Step 7: Verify all services
print_step "7/8" "Verifying services..."
echo ""
print_info "Container status:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "NAME|kafka|flink|elasticsearch|kibana|zookeeper|namenode|datanode|resourcemanager" || docker ps --format "table {{.Names}}\t{{.Status}}"
echo ""

# Step 8: Health checks
print_step "8/8" "Running health checks..."
HEALTH_OK=true

# Check Kafka
if docker exec kafka kafka-broker-api-versions --bootstrap-server localhost:9092 &>/dev/null; then
    print_info "✓ Kafka is healthy (port 9092)"
else
    print_warn "✗ Kafka may not be ready yet"
    HEALTH_OK=false
fi

# Check Flink
if curl -s http://localhost:8081 > /dev/null; then
    print_info "✓ Flink Dashboard is accessible (port 8081)"
else
    print_warn "✗ Flink Dashboard not accessible yet"
    HEALTH_OK=false
fi

# Check Elasticsearch
if curl -s http://localhost:9200 > /dev/null; then
    print_info "✓ Elasticsearch is accessible (port 9200)"
else
    print_warn "✗ Elasticsearch not accessible yet"
    HEALTH_OK=false
fi

# Check Kibana
if curl -s http://localhost:5601 > /dev/null; then
    print_info "✓ Kibana is accessible (port 5601)"
else
    print_warn "✗ Kibana not accessible yet (may need more time)"
    HEALTH_OK=false
fi

# Check Hadoop (if installed)
if [ "$INSTALL_HADOOP" = true ]; then
    if curl -s http://localhost:9870 > /dev/null; then
        print_info "✓ Hadoop NameNode is accessible (port 9870)"
    else
        print_warn "✗ Hadoop NameNode not accessible yet"
        HEALTH_OK=false
    fi
fi

echo ""

if [ "$HEALTH_OK" = false ]; then
    print_warn "Some services may need more time to initialize"
    print_info "You can check service logs with: docker-compose logs [service-name]"
    echo ""
fi

# Installation complete
print_header "Installation Complete!"
echo ""

# Display service URLs
print_info "Service Access Points:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Kafka:              localhost:9092"
echo "  Flink Dashboard:    http://localhost:8081"
echo "  Elasticsearch:      http://localhost:9200"
echo "  Kibana:             http://localhost:5601"
if [ "$INSTALL_HADOOP" = true ]; then
    echo "  HDFS NameNode UI:   http://localhost:9870"
    echo "  YARN ResourceMgr:   http://localhost:8088"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Next steps
print_info "Next Steps to Start Data Processing:"
echo ""
echo "1. Activate Python environment:"
echo "   ${GREEN}source venv/bin/activate${NC}"
echo ""
echo "2. Start the tweet producer (Terminal 1):"
echo "   ${GREEN}python word_count/mock_word_count_tweets_producer.py${NC}"
echo ""
echo "3. Start Flink processing job (Terminal 2):"
echo "   ${GREEN}docker exec -it flink-jobmanager python /opt/flink/kafka_flink_wordcount_v3.py${NC}"
echo ""

if [ "$INSTALL_HADOOP" = true ]; then
    echo "4. (Optional) Start HDFS consumer for archiving (Terminal 3):"
    echo "   ${GREEN}python hdfs_web_consumer_v4.py${NC}"
    echo ""
fi

echo "5. Access Kibana to create visualizations:"
echo "   ${GREEN}http://localhost:5601${NC}"
echo ""

# Optional debugging
print_info "Optional Debugging:"
echo "  • Monitor Kafka messages:"
echo "    ${GREEN}python word_count/Kafka_tweets_consumer.py${NC}"
echo ""
echo "  • View service logs:"
echo "    ${GREEN}docker-compose logs -f [kafka|flink-jobmanager|elasticsearch|kibana]${NC}"
echo ""

# Quick reference
print_info "Quick Reference:"
echo "  • Stop all services:     ${GREEN}docker-compose down${NC}"
if [ "$INSTALL_HADOOP" = true ]; then
    echo "  • Stop Hadoop:           ${GREEN}cd docker-hadoop && docker-compose down && cd ..${NC}"
fi
echo "  • Restart services:      ${GREEN}docker-compose restart${NC}"
echo "  • View container status: ${GREEN}docker ps${NC}"
echo "  • Health check script:   ${GREEN}bash health_check.sh${NC}"
echo ""

print_header "Happy Data Streaming!"
echo ""
echo "For detailed documentation, see README.md"
echo ""
