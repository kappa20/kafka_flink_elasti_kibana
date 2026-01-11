#!/bin/bash

# Initialize HDFS directory for Kafka data
# This avoids WebHDFS redirect issues by using docker exec

echo "Initializing HDFS for Kafka data..."

# Create directory
docker exec namenode hdfs dfs -mkdir -p /kafka_demo

# Create empty file
docker exec namenode hdfs dfs -touchz /kafka_demo/tweets_data.json

# Set permissions
docker exec namenode hdfs dfs -chmod -R 777 /kafka_demo

echo "✓ HDFS initialized successfully"
echo ""
echo "Directory contents:"
docker exec namenode hdfs dfs -ls /kafka_demo

echo ""
echo "You can now run: python hdfs_web_consumer.py"
