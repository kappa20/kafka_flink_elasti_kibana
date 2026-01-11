#!/bin/bash

# Kafka Tweets Processing Pipeline - Startup Script
# This script initializes and starts all services in the correct order

set -e  # Exit on any error

echo "================================"
echo "Kafka Tweets Processing Pipeline"
echo "================================"
echo ""

# Color codes for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

# Step 1: Create Docker network if it doesn't exist
print_info "Step 1: Creating Docker network..."
if ! docker network inspect bigdata-network >/dev/null 2>&1; then
    docker network create bigdata-network
    print_info "Network 'bigdata-network' created successfully"
else
    print_warn "Network 'bigdata-network' already exists"
fi
echo ""

# Step 2: Build custom Flink image
print_info "Step 2: Building custom Flink image with Python support..."
docker build -t flink-python:1.18 -f Dockerfile.flink .
print_info "Flink image built successfully"
echo ""

# Step 3: Start Hadoop services
print_info "Step 3: Starting Hadoop services (HDFS, YARN)..."
cd docker-hadoop

# Clean up any existing containers to avoid metadata issues
print_info "Cleaning up existing Hadoop containers..."
docker-compose down 2>/dev/null || true
docker rm -f namenode datanode resourcemanager nodemanager historyserver 2>/dev/null || true

# Start Hadoop services
print_info "Starting fresh Hadoop containers..."
docker-compose up -d
cd ..
print_info "Hadoop services started"
print_info "Waiting 30 seconds for Hadoop services to initialize..."
sleep 30
echo ""

# Step 4: Start Kafka, Flink, and Elasticsearch services
print_info "Step 4: Starting Kafka, Flink, Elasticsearch, and Kibana..."
docker-compose up -d
print_info "All services started"
print_info "Waiting 20 seconds for services to initialize..."
sleep 20
echo ""

# Step 5: Verify all services are running
print_info "Step 5: Verifying services..."
echo ""
print_info "Checking container status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# Step 6: Display service URLs
print_info "Step 6: Service URLs and Access Points"
echo "========================================"
echo "Hadoop NameNode UI:        http://localhost:9870"
echo "Hadoop ResourceManager UI: http://localhost:8088"
echo "Kafka:                     localhost:9092"
echo "Flink Dashboard:           http://localhost:8081"
echo "Elasticsearch:             http://localhost:9200"
echo "Kibana:                    http://localhost:5601"
echo ""

# Step 7: Initialize HDFS directory
print_info "Step 7: Initializing HDFS directory for Kafka data..."
docker exec namenode hdfs dfs -mkdir -p /kafka_demo 2>/dev/null || true
docker exec namenode hdfs dfs -chmod -R 777 /kafka_demo 2>/dev/null || true
print_info "HDFS directory initialized"
echo ""

# Step 8: Setup Python virtual environment if needed
print_info "Step 8: Setting up Python environment..."
if [ ! -d "kafka_3_10" ]; then
    print_warn "Virtual environment 'kafka_3_10' not found. Creating it..."
    python3 -m venv kafka_3_10
    print_info "Virtual environment created"
fi

print_info "Installing Python dependencies..."
source kafka_3_10/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
deactivate
print_info "Python dependencies installed"
echo ""

# Final message
echo "========================================"
print_info "Pipeline initialization complete!"
echo ""
echo "Next steps:"
echo "1. Activate Python environment: source kafka_3_10/bin/activate"
echo "2. Start producer: python mock_kafka_tweets_producer.py"
echo "3. Start consumer (in new terminal): python Kafka_tweets_consumer.py"
echo "4. Start HDFS consumer (in new terminal): python hdfs_web_consumer.py"
echo "5. Run Flink streaming job:"
echo "   docker exec -it flink-jobmanager python /opt/flink/kafka_flink_elasticsearch_streaming_v2.py"
echo ""
echo "For detailed instructions, see README.md"
echo "========================================"
