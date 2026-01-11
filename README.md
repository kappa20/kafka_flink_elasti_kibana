# Real-Time Tweet Word Count Pipeline

A complete real-time data processing and visualization pipeline that demonstrates streaming data analytics using Apache Kafka, Apache Flink, Elasticsearch, and Kibana. This project processes mock Twitter data to perform word count analysis and creates live visualizations.

## Architecture Overview

```
┌─────────────────┐
│ Python Producer │ → Generates mock tweets every 5 seconds
└────────┬────────┘
         ↓
┌─────────────────┐
│  Apache Kafka   │ → Streams tweet messages
└────────┬────────┘
         ↓
┌─────────────────┐
│  Apache Flink   │ → Processes and analyzes word frequency
└────────┬────────┘
         ↓
┌─────────────────┐
│ Elasticsearch   │ → Indexes processed data
└────────┬────────┘
         ↓
┌─────────────────┐
│     Kibana      │ → Visualizes insights
└─────────────────┘
```

## What This Project Does

This pipeline simulates a real-time Twitter analytics system that:
- **Ingests** streaming tweet data through Apache Kafka
- **Processes** the data using Apache Flink to:
  - Clean text (remove URLs, mentions)
  - Split tweets into individual words
  - Filter common stopwords
  - Count word frequencies in real-time
- **Stores** results in two Elasticsearch indices:
  - `demowordcloud` - Word count aggregations
  - `tweets_full_data` - Complete tweet records
- **Visualizes** the data through Kibana dashboards

## Technology Stack

- **Apache Kafka** (Confluent 7.5.0) - Message streaming
- **Apache Flink** (1.18) - Stream processing with Python support
- **Elasticsearch** (7.17.10) - Data indexing and search
- **Kibana** (7.17.10) - Data visualization
- **Zookeeper** (3.9.1) - Kafka coordination
- **Python 3** - Data generation and processing scripts
- **Docker & Docker Compose** - Container orchestration

## Prerequisites

- Docker and Docker Compose installed
- Python 3.8 or higher
- At least 8GB RAM available for Docker
- Ports available: 9092 (Kafka), 8081 (Flink), 9200 (Elasticsearch), 5601 (Kibana)

## Quick Start

### 1. One-Time Setup

First, create the Docker network and build the custom Flink image:

```bash
# Create Docker network
docker network create bigdata-network

# Build Flink image with Python support
docker build -t flink-python:1.18 -f Dockerfile.flink .
```

### 2. Start All Services

Start the entire pipeline using Docker Compose:

```bash
docker-compose up -d
```

This will start:
- Zookeeper (coordination)
- Kafka (message broker)
- Flink JobManager (job coordination)
- Flink TaskManager (task execution)
- Elasticsearch (data storage)
- Kibana (visualization)

### 3. Verify Services Are Running

Check that all services are healthy:

```bash
# Check container status
docker-compose ps

# Run the health check script (optional)
bash health_check.sh
```

Wait about 30-60 seconds for all services to fully initialize.

### 4. Set Up Python Environment

Create and activate a Python virtual environment:

```bash
# Create virtual environment
python -m venv kafka_3_10

# Activate it (Windows Git Bash)
source kafka_3_10/Scripts/activate

# Or on Linux/Mac
source kafka_3_10/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 5. Start the Data Producer

In a terminal with the virtual environment activated:

```bash
python word_count/mock_word_count_tweets_producer.py
```

You should see output like:
```
Sent: {"id_str": "...", "username": "LofiGirl", "tweet": "Chill beats to study...", ...}
```

The producer generates one mock tweet every 5 seconds.

### 6. Start the Flink Processing Job

In another terminal, submit the Flink job:

```bash
docker exec -it flink-jobmanager python /opt/flink/kafka_flink_wordcount_v3.py
```

The job will:
- Read tweets from Kafka
- Process and count words
- Send results to Elasticsearch

### 7. Access the Web Interfaces

Open your browser and navigate to:

- **Flink Dashboard**: http://localhost:8081
  - Monitor running jobs, task managers, and job metrics

- **Kibana**: http://localhost:5601
  - Create visualizations and dashboards
  - Query the `demowordcloud` and `tweets_full_data` indices

- **Elasticsearch**: http://localhost:9200
  - Direct API access for querying data

### 8. Verify Data Flow

Check that data is flowing through the pipeline:

```bash
# View Kafka messages
docker exec -it kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic my-topic-test \
  --from-beginning

# Query word counts from Elasticsearch
curl "http://localhost:9200/demowordcloud/_search?pretty&size=10"

# Query full tweet data
curl "http://localhost:9200/tweets_full_data/_search?pretty&size=5"

# List all Elasticsearch indices
curl "http://localhost:9200/_cat/indices?v"
```

## Creating Visualizations in Kibana

1. Navigate to http://localhost:5601
2. Go to **Management** → **Stack Management** → **Index Patterns**
3. Create index patterns:
   - `demowordcloud*`
   - `tweets_full_data*`
4. Go to **Analytics** → **Visualize Library**
5. Create visualizations:
   - **Tag Cloud** for `demowordcloud` (word frequencies)
   - **Line Chart** for tweet volume over time
   - **Pie Chart** for language distribution
   - **Data Table** for top tweets by engagement
6. Combine visualizations into a **Dashboard**

## Optional: Debug Kafka Consumer

To monitor Kafka messages in real-time (useful for debugging):

```bash
# In a terminal with virtual environment activated
python word_count/Kafka_tweets_consumer.py
```

This will display formatted tweets as they arrive in Kafka.

## Stopping the Pipeline

Stop all services:

```bash
# Stop containers
docker-compose down

# Stop and remove volumes (deletes all data)
docker-compose down -v
```

## Project Structure

```
kafka_flink_elasti_kibana/
├── docker-compose.yml              # Main orchestration file
├── Dockerfile.flink                # Custom Flink+Python image
├── requirements.txt                # Python dependencies
├── start-pipeline.sh               # Automated startup script
├── health_check.sh                 # Service health verification
├── flink-sql-connector-kafka-3.0.1-1.18.jar
├── flink-sql-connector-elasticsearch7-3.0.1-1.17.jar
├── flink-python-1.18.0.jar
├── word_count/
│   ├── mock_word_count_tweets_producer.py   # Generates mock tweets
│   ├── Kafka_tweets_consumer.py             # Debug consumer
│   └── kafka_flink_wordcount_v3.py          # Flink processing job
└── README.md
```

## Data Flow Details

### 1. Data Generation
The Python producer ([mock_word_count_tweets_producer.py](word_count/mock_word_count_tweets_producer.py)) generates mock tweets with:
- `id_str` - Unique tweet ID
- `username` - Mock usernames (LofiGirl, TokyoBeats, etc.)
- `tweet` - Tweet text content
- `location` - Geographic location
- `retweet_count` - Engagement metric
- `followers_count` - User followers
- `lang` - Language code (en, fr, es, ar)

### 2. Message Streaming
Kafka receives tweets on the `my-topic-test` topic and maintains an ordered, distributed log accessible to downstream consumers.

### 3. Stream Processing
Flink ([kafka_flink_wordcount_v3.py](word_count/kafka_flink_wordcount_v3.py)) performs:
- **Text Preprocessing**: Removes URLs, mentions, converts to lowercase
- **Tokenization**: Splits tweets into words, removes punctuation
- **Filtering**: Removes short words (<3 chars) and stopwords
- **Aggregation**: Counts word frequencies
- **Dual Sink**: Sends both word counts and full tweets to Elasticsearch

### 4. Data Storage
Elasticsearch stores data in two indices:
- **demowordcloud**: Word counts with schema (word: STRING, number: BIGINT)
- **tweets_full_data**: Complete tweet records with all fields

### 5. Visualization
Kibana provides real-time dashboards for analyzing word trends, geographic distribution, language patterns, and user engagement.

## Troubleshooting

### Services Won't Start
```bash
# Check Docker resources (need 8GB+ RAM)
docker stats

# View logs for specific service
docker-compose logs kafka
docker-compose logs flink-jobmanager
docker-compose logs elasticsearch
```

### Kafka Connection Issues
```bash
# Verify Kafka is accepting connections
docker exec -it kafka kafka-broker-api-versions \
  --bootstrap-server localhost:9092
```

### Elasticsearch Not Receiving Data
```bash
# Check Flink job status
docker logs flink-jobmanager

# Verify Flink job is running
curl http://localhost:8081/jobs
```

### Port Already in Use
If you get port conflicts, modify the port mappings in [docker-compose.yml](docker-compose.yml).

## Performance Tuning

- **Kafka**: Adjust `KAFKA_NUM_PARTITIONS` for parallelism
- **Flink**: Increase TaskManager slots in [docker-compose.yml](docker-compose.yml)
- **Elasticsearch**: Increase JVM heap size via `ES_JAVA_OPTS`
- **Producer Rate**: Modify sleep time in [mock_word_count_tweets_producer.py](word_count/mock_word_count_tweets_producer.py)

## Common Commands

```bash
# View all running containers
docker-compose ps

# Follow logs for all services
docker-compose logs -f

# Restart a specific service
docker-compose restart kafka

# Scale Flink TaskManagers
docker-compose up -d --scale flink-taskmanager=3

# Clean everything and start fresh
docker-compose down -v
docker-compose up -d
```

## Learning Resources

- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [Apache Flink Documentation](https://flink.apache.org/)
- [PyFlink Documentation](https://nightlies.apache.org/flink/flink-docs-release-1.18/docs/dev/python/overview/)
- [Elasticsearch Guide](https://www.elastic.co/guide/en/elasticsearch/reference/7.17/index.html)
- [Kibana Guide](https://www.elastic.co/guide/en/kibana/7.17/index.html)

## License

This project is for educational and demonstration purposes.

## Contributing

Feel free to submit issues and enhancement requests!

---

**Note**: This project focuses on the main [docker-compose.yml](docker-compose.yml) in the root directory. The `docker-hadoop` folder contains optional Hadoop/HDFS components that are not required for the core real-time visualization pipeline.
