# Quick Start Guide

## Initial Setup (One Time)

```bash
# 1. Create Docker network
docker network create bigdata-network

# 2. Build custom Flink image
docker build -t flink-python:1.18 -f Dockerfile.flink .

# 3. Start all services (automated)
./start-pipeline.sh
```

**OR** use the automated startup script:
```bash
./start-pipeline.sh
```

## Starting the Pipeline

### Step 1: Start Services (if not already running)

```bash
# Start Hadoop not necessary 
cd docker-hadoop && docker-compose up -d && cd ..

# Start main services
docker-compose up -d

# Wait 30 seconds for initialization
```

### Step 2: Verify Services

```bash
./health_check.sh
```

### Step 3: Activate Python Environment

```bash
source kafka_3_10/bin/activate
```

### Step 4: Start Producer

```bash
python word_count/mock_word_count_tweets_producer.py
```

Keep this running in Terminal 1.

### Step 5: Start Consumers (Optional)

**Terminal 2 - Basic Consumer:**
```bash
source kafka_3_10/bin/activate
python word_count/Kafka_tweets_consumer.py
```

**Terminal 3(optional) - HDFS Consumer [Not required]:**
```bash
source kafka_3_10/bin/activate
python hdfs_web_consumer.py
```

### Step 6: Run Flink Streaming Job

**Terminal 4:**
```bash
docker exec -it flink-jobmanager python /opt/flink/kafka_flink_wordcount_v3.py
```

## Accessing Dashboards

| Service | URL |
|---------|-----|
| Hadoop NameNode | http://localhost:9870 | (not required)
| YARN ResourceManager | http://localhost:8088 |
| Flink Dashboard | http://localhost:8081 |
| Elasticsearch | http://localhost:9200 |
| Kibana | http://localhost:5601 |

## Quick Validation

```bash
# Check all services
./health_check.sh

# Validate data flow
./validate_pipeline.sh

# Run all tests
./run_all_tests.sh
```

## Common Commands

### View Kafka Messages
```bash
docker exec -it kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic my-topic-test \
  --from-beginning
```

### Check HDFS Data
```bash
docker exec -it namenode hdfs dfs -cat /kafka_demo/tweets_data.json | tail -20
```

### Query Elasticsearch
```bash
curl http://localhost:9200/tweets_live_stream/_search?pretty&size=5
```

### View Flink Jobs
```bash
curl http://localhost:8081/jobs/overview | python3 -m json.tool
```

## Stopping the Pipeline

```bash
./stop-pipeline.sh
```

**OR manually:**
```bash
docker-compose down
cd docker-hadoop && docker-compose down
```

## Troubleshooting

### Producer Can't Connect to Kafka
```bash
docker logs kafka
docker restart kafka
```

### Flink Job Fails
```bash
docker logs flink-jobmanager
docker exec -it flink-jobmanager ls /opt/flink/lib/
docker exec -it flink-jobmanager python --version
```

### No Data in Elasticsearch
```bash
curl http://localhost:9200/_cat/indices?v
docker logs elasticsearch
```

### HDFS Not Accessible
```bash
docker logs namenode
curl http://localhost:9870
```


## Next Steps

1. ✅ Start all services
2. ✅ Run health check
3. ✅ Start producer
4. ✅ Run Flink job
5. ✅ Validate data flow
6. 🎯 Configure Kibana dashboards
7. 🎯 Customize tweet data
8. 🎯 Add monitoring

For detailed information, see `README.md` and `TESTING.md`.
