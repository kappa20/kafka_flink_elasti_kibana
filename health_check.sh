#!/bin/bash

# Health Check Script for Kafka Pipeline
# Checks if all services are running and accessible

echo "=== Service Health Check ==="
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

check_service() {
    if $2 >/dev/null 2>&1; then
        echo -e "$1: ${GREEN}✓ OK${NC}"
        return 0
    else
        echo -e "$1: ${RED}✗ FAILED${NC}"
        return 1
    fi
}

# Zookeeper
echo -n "Zookeeper: "
if docker exec zookeeper zkServer.sh status 2>/dev/null | grep -q "Mode:"; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FAILED${NC}"
fi

# Kafka
echo -n "Kafka: "
if docker exec kafka kafka-broker-api-versions --bootstrap-server localhost:9092 2>/dev/null | grep -q "ApiVersion"; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FAILED${NC}"
fi

# HDFS NameNode
echo -n "HDFS NameNode: "
if curl -sf http://localhost:9870 >/dev/null 2>&1; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FAILED${NC}"
fi

# Flink JobManager
echo -n "Flink JobManager: "
if curl -sf http://localhost:8081 >/dev/null 2>&1; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FAILED${NC}"
fi

# Elasticsearch
echo -n "Elasticsearch: "
if curl -sf http://localhost:9200 >/dev/null 2>&1; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FAILED${NC}"
fi

# Kibana
echo -n "Kibana: "
if curl -sf http://localhost:5601/api/status >/dev/null 2>&1; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FAILED${NC}"
fi

echo ""
echo "=== Container Status ==="
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "kafka|flink|elastic|kibana|zookeeper|namenode|datanode|resourcemanager"
