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

### Basic Pipeline (Kafka → Flink → Elasticsearch → Kibana)
- Docker and Docker Compose installed
- Python 3.8 or higher
- At least 8GB RAM available for Docker
- Ports available: 9092 (Kafka), 8081 (Flink), 9200 (Elasticsearch), 5601 (Kibana)

### With Hadoop/HDFS (Optional - Advanced Setup)
- All basic prerequisites above
- At least 16GB RAM available for Docker (Hadoop requires additional 8GB)
- 8+ CPU cores recommended
- Additional ports: 9870 (HDFS NameNode), 9000 (HDFS), 8088 (YARN), 9864 (DataNode)
- Linux system recommended (instructions focus on Linux commands)

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

**Note**: This step is completely optional and NOT required for the pipeline to work. It's only useful for debugging.

To monitor Kafka messages in real-time and verify the producer is working:

```bash
# In a terminal with virtual environment activated
python word_count/Kafka_tweets_consumer.py
```

This will display formatted tweets as they arrive in Kafka. The actual data processing is handled by the Flink job, not this consumer.

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
├── init_hdfs.sh                    # HDFS initialization script (Hadoop)
├── hdfs_web_consumer_v4.py         # HDFS consumer for archiving (Hadoop)
├── flink-sql-connector-kafka-3.0.1-1.18.jar
├── flink-sql-connector-elasticsearch7-3.0.1-1.17.jar
├── flink-python-1.18.0.jar
├── word_count/
│   ├── mock_word_count_tweets_producer.py   # Generates mock tweets
│   ├── Kafka_tweets_consumer.py             # Debug consumer (optional)
│   └── kafka_flink_wordcount_v3.py          # Flink processing job
├── docker-hadoop/                  # Optional Hadoop/HDFS setup
│   ├── docker-compose.yml          # Hadoop services configuration
│   ├── hadoop.env                  # Hadoop environment variables
│   └── ...                         # Hadoop Docker build files
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

## Advanced: Running with Hadoop HDFS Storage (Optional)

### Overview

This section covers how to extend the basic pipeline with Apache Hadoop HDFS for persistent, distributed storage. While Elasticsearch provides excellent real-time search and visualization capabilities, HDFS offers long-term archival storage with scalability and fault tolerance.

**Extended Architecture**:
```
┌─────────────────┐
│ Python Producer │ → Generates mock tweets every 5 seconds
└────────┬────────┘
         ↓
┌─────────────────┐
│  Apache Kafka   │ → Streams tweet messages
└────────┬────────┘
         ↓
    ┌────┴─────────────────┐
    ↓                      ↓
┌─────────────┐    ┌──────────────┐
│Apache Flink │    │HDFS Consumer │ → Batches messages
│             │    │              │    and writes to HDFS
└──────┬──────┘    └──────┬───────┘
       ↓                  ↓
┌──────────────┐   ┌─────────────┐
│Elasticsearch │   │    HDFS     │ → Long-term storage
└──────┬───────┘   │  (Hadoop)   │
       ↓           └─────────────┘
┌─────────────┐
│   Kibana    │ → Real-time visualization
└─────────────┘
```

### Why Use HDFS?

- **Persistent Storage**: Archive historical data beyond Elasticsearch retention
- **Distributed Storage**: Data is replicated across multiple nodes for fault tolerance
- **Scalability**: Easily scale to petabytes of data
- **Batch Processing**: Integrate with Hadoop MapReduce, Spark, or Hive for historical analysis
- **Data Lake**: Store raw data for future analytics and machine learning

### Additional Hadoop Services

The Hadoop stack ([docker-hadoop/docker-compose.yml](docker-hadoop/docker-compose.yml)) includes:

| Service | Purpose | Port |
|---------|---------|------|
| **NameNode** | HDFS master node managing metadata | 9870 (Web UI), 9000 (RPC) |
| **DataNode** | HDFS worker storing data blocks | 9864 (Web UI) |
| **ResourceManager** | YARN cluster resource manager | 8088 (Web UI) |
| **NodeManager** | YARN worker running containers | 8042 (Web UI) |
| **HistoryServer** | MapReduce job history tracker | 8188 (Web UI) |

All services use **Hadoop 3.2.1** with Java 8.

### Prerequisites for Hadoop

- All basic prerequisites (see Prerequisites section)
- Docker network `bigdata-network` (created in one-time setup)
- At least 16GB RAM total (8GB for Hadoop services)
- Linux system (all commands use bash syntax)
- No `/etc/hosts` modifications needed - Docker DNS handles hostname resolution

### Hadoop Quick Start

#### 1. Start Hadoop Services

Navigate to the docker-hadoop directory and start all Hadoop services:

```bash
cd docker-hadoop
docker-compose up -d
cd ..
```

This will start NameNode, DataNode, ResourceManager, NodeManager, and HistoryServer.

Wait 30-60 seconds for Hadoop services to initialize:

```bash
# Wait for services to be ready
sleep 30
```

#### 2. Verify Hadoop is Running

Check that all Hadoop containers are healthy:

```bash
# Check container status
docker-compose -f docker-hadoop/docker-compose.yml ps

# Verify NameNode web UI is accessible
curl -s http://localhost:9870 > /dev/null && echo "NameNode is running" || echo "NameNode not ready"

# Check HDFS health
docker exec namenode hdfs dfsadmin -report
```

You can also access the NameNode Web UI at http://localhost:9870 to browse HDFS files and check cluster health.

#### 3. Initialize HDFS Directory

Run the initialization script to create the directory structure for Kafka data:

```bash
bash init_hdfs.sh
```

This script ([init_hdfs.sh](init_hdfs.sh)):
- Creates `/kafka_demo` directory in HDFS
- Sets permissions to 777 for easy access
- Creates an initial empty file

Verify the directory was created:

```bash
docker exec namenode hdfs dfs -ls /
docker exec namenode hdfs dfs -ls /kafka_demo
```

#### 4. Start the Main Pipeline

If you haven't already, start the main pipeline services:

```bash
# Build Flink image (one-time setup)
docker build -t flink-python:1.18 -f Dockerfile.flink .

# Start Kafka, Flink, Elasticsearch, Kibana
docker-compose up -d

# Wait for services
sleep 20

# Set up Python environment
python3 -m venv kafka_3_10
source kafka_3_10/bin/activate
pip install -r requirements.txt
```

#### 5. Start the Tweet Producer

In a terminal with the virtual environment activated:

```bash
python word_count/mock_word_count_tweets_producer.py
```

Keep this running to generate tweets.

#### 6. Start the Flink Processing Job

In another terminal:

```bash
docker exec -it flink-jobmanager python /opt/flink/kafka_flink_wordcount_v3.py
```

This processes tweets and sends them to Elasticsearch for visualization.

#### 7. Start the HDFS Consumer

In a third terminal with the virtual environment activated, start the HDFS archiver:

```bash
python hdfs_web_consumer_v4.py
```

This script ([hdfs_web_consumer_v4.py](hdfs_web_consumer_v4.py)):
- Reads tweets from Kafka topic `my-topic-test`
- Batches tweets (10 tweets or 30 seconds, whichever comes first)
- Writes batched tweets to HDFS with timestamped filenames
- Avoids file lease conflicts by creating new files for each batch

You should see output like:
```
Initializing HDFS directory...
✓ HDFS directory initialized
HDFS Consumer V4 is live! Listening for Kafka messages...

→ Buffered tweet from LofiGirl (1/10)
→ Buffered tweet from TokyoBeats (2/10)
...
✔ Wrote 10 tweets to /kafka_demo/tweets_20260111_143052_1.json
```

#### 8. Verify Data in HDFS

Check that tweets are being written to HDFS:

```bash
# List all files in HDFS kafka_demo directory
docker exec namenode hdfs dfs -ls /kafka_demo

# View the content of a specific file
docker exec namenode hdfs dfs -cat /kafka_demo/tweets_*.json | head -20

# Count total lines across all files
docker exec namenode hdfs dfs -cat /kafka_demo/tweets_*.json | wc -l

# Check HDFS usage
docker exec namenode hdfs dfs -du -h /kafka_demo
```

### Complete Linux Workflow with Hadoop

Here's the complete step-by-step workflow for running the full pipeline with HDFS on Linux:

```bash
# ===== ONE-TIME SETUP =====

# 1. Create Docker network
docker network create bigdata-network

# 2. Build Flink image
docker build -t flink-python:1.18 -f Dockerfile.flink .

# 3. Create Python virtual environment
python3 -m venv kafka_3_10
source kafka_3_10/bin/activate
pip install -r requirements.txt
deactivate

# ===== START SERVICES =====

# 4. Start Hadoop services
cd docker-hadoop
docker-compose up -d
cd ..
sleep 30

# 5. Initialize HDFS
bash init_hdfs.sh

# 6. Start main pipeline
docker-compose up -d
sleep 20

# ===== START DATA PROCESSING =====

# 7. Activate Python environment
source kafka_3_10/bin/activate

# 8. Start producer (Terminal 1)
python word_count/mock_word_count_tweets_producer.py &
PRODUCER_PID=$!

# 9. Start HDFS consumer (Terminal 2)
python hdfs_web_consumer_v4.py &
HDFS_PID=$!

# 10. Start Flink job (Terminal 3)
docker exec -it flink-jobmanager python /opt/flink/kafka_flink_wordcount_v3.py

# ===== VERIFICATION =====

# Check Elasticsearch data
curl "http://localhost:9200/demowordcloud/_search?pretty&size=5"

# Check HDFS data
docker exec namenode hdfs dfs -ls /kafka_demo
docker exec namenode hdfs dfs -cat /kafka_demo/tweets_*.json | head -10

# ===== MONITORING =====

# View web UIs
firefox http://localhost:9870  # HDFS NameNode
firefox http://localhost:8081  # Flink Dashboard
firefox http://localhost:5601  # Kibana

# ===== SHUTDOWN =====

# Stop Python processes
kill $PRODUCER_PID $HDFS_PID

# Stop main pipeline
docker-compose down

# Stop Hadoop
cd docker-hadoop
docker-compose down
cd ..
```

### Hadoop Web Interfaces

Access these URLs to monitor your Hadoop cluster:

| Service | URL | What You Can See |
|---------|-----|------------------|
| **NameNode** | http://localhost:9870 | HDFS file browser, cluster health, storage capacity |
| **ResourceManager** | http://localhost:8088 | YARN applications, cluster resources, job tracking |
| **DataNode** | http://localhost:9864 | DataNode information, data blocks, storage |
| **NodeManager** | http://localhost:8042 | Container logs, application progress |
| **HistoryServer** | http://localhost:8188 | MapReduce job history and statistics |

### Monitoring HDFS Data

#### List Files in HDFS

```bash
# List root directory
docker exec namenode hdfs dfs -ls /

# List kafka_demo directory
docker exec namenode hdfs dfs -ls /kafka_demo

# Recursive listing with file sizes
docker exec namenode hdfs dfs -ls -R -h /kafka_demo
```

#### Read Data from HDFS

```bash
# Read all content
docker exec namenode hdfs dfs -cat /kafka_demo/tweets_*.json

# Read first 10 lines
docker exec namenode hdfs dfs -cat /kafka_demo/tweets_*.json | head -10

# Read last 20 lines
docker exec namenode hdfs dfs -cat /kafka_demo/tweets_*.json | tail -20

# Count total tweets stored
docker exec namenode hdfs dfs -cat /kafka_demo/tweets_*.json | wc -l
```

#### Check HDFS Storage

```bash
# Disk usage for kafka_demo
docker exec namenode hdfs dfs -du -h /kafka_demo

# HDFS filesystem report
docker exec namenode hdfs dfsadmin -report

# Check replication status
docker exec namenode hdfs fsck /kafka_demo -files -blocks -locations
```

#### Using the NameNode Web UI

1. Navigate to http://localhost:9870
2. Click **Utilities** → **Browse the file system**
3. Navigate to `/kafka_demo`
4. Click on any file to download or view its content
5. Check **Datanodes** tab to see storage distribution

### HDFS Consumer Details

The [hdfs_web_consumer_v4.py](hdfs_web_consumer_v4.py) script implements intelligent batching:

**Batching Strategy**:
- Buffers incoming tweets in memory
- Flushes to HDFS when:
  - Buffer reaches 10 tweets, OR
  - 30 seconds have elapsed since last write

**File Naming**:
- Pattern: `tweets_YYYYMMDD_HHMMSS_N.json`
- Example: `tweets_20260111_143052_1.json`
- Timestamped filenames prevent lease conflicts
- Each batch creates a new file (no appending)

**Data Format**:
- One JSON object per line (JSONL format)
- Complete tweet records with all fields
- Easy to process with Hadoop tools

**Graceful Shutdown**:
- Press Ctrl+C to stop
- Automatically flushes remaining buffered tweets
- No data loss on shutdown

**Error Handling**:
- Retries on transient errors
- Timeouts prevent hanging
- Continues processing even if individual writes fail

### Stopping Hadoop Services

#### Stop All Services

```bash
# Stop main pipeline
docker-compose down

# Stop Hadoop services
cd docker-hadoop
docker-compose down
cd ..
```

#### Stop and Remove All Data

To completely clean up including all stored data:

```bash
# Stop and remove main pipeline volumes
docker-compose down -v

# Stop and remove Hadoop volumes
cd docker-hadoop
docker-compose down -v
cd ..

# Remove Docker network (optional)
docker network rm bigdata-network
```

**Warning**: This will delete all data stored in HDFS and Elasticsearch!

### Troubleshooting Hadoop

#### Services Not Starting

```bash
# Check Docker resources (Hadoop needs significant RAM)
docker stats

# View NameNode logs
docker logs namenode

# View DataNode logs
docker logs datanode

# Check if services are listening on expected ports
netstat -tuln | grep -E '9870|9000|8088'
```

#### HDFS Connection Errors

```bash
# Test HDFS connectivity
docker exec namenode hdfs dfs -ls /

# Check NameNode status
curl http://localhost:9870/jmx | grep -i state

# Verify DataNode is registered
docker exec namenode hdfs dfsadmin -report
```

#### Permission Issues

```bash
# Check directory permissions
docker exec namenode hdfs dfs -ls -d /kafka_demo

# Fix permissions if needed
docker exec namenode hdfs dfs -chmod -R 777 /kafka_demo
```

#### HDFS Consumer Not Writing

```bash
# Verify Kafka messages are available
docker exec -it kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic my-topic-test \
  --max-messages 5

# Check if NameNode is accessible from host
curl http://localhost:9870

# Verify Docker network connectivity
docker exec namenode ping -c 3 kafka
```

#### Out of Memory Errors

Hadoop services are configured with generous memory allocations in [hadoop.env](docker-hadoop/hadoop.env):

```bash
# Check current memory usage
docker stats namenode datanode resourcemanager nodemanager

# Reduce YARN memory in hadoop.env if needed:
# YARN_CONF_yarn_nodemanager_resource_memory___mb=8192  # Reduce from 16384
```

#### Network Issues Between Services

```bash
# Verify all services are on the same network
docker network inspect bigdata-network

# Test connectivity from main pipeline to Hadoop
docker exec flink-jobmanager ping -c 3 namenode
docker exec kafka ping -c 3 namenode
```

### Data Storage Comparison

| Feature | Elasticsearch | HDFS |
|---------|---------------|------|
| **Purpose** | Real-time search & analytics | Long-term archival storage |
| **Access Pattern** | Random access, queries | Sequential read, batch processing |
| **Data Retention** | Hours to days (configurable) | Years (unlimited) |
| **Query Speed** | Milliseconds | Seconds to minutes |
| **Best For** | Live dashboards, alerts | Historical analysis, compliance |
| **Scalability** | Horizontal (add nodes) | Horizontal (add DataNodes) |
| **Cost** | Higher (memory intensive) | Lower (disk-based) |

**Recommendation**: Use both together:
- **Elasticsearch** for recent data and real-time visualization
- **HDFS** for complete historical archive and batch analytics

## Learning Resources

- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [Apache Flink Documentation](https://flink.apache.org/)
- [PyFlink Documentation](https://nightlies.apache.org/flink/flink-docs-release-1.18/docs/dev/python/overview/)
- [Elasticsearch Guide](https://www.elastic.co/guide/en/elasticsearch/reference/7.17/index.html)
- [Kibana Guide](https://www.elastic.co/guide/en/kibana/7.17/index.html)
- [Apache Hadoop Documentation](https://hadoop.apache.org/docs/r3.2.1/)
- [HDFS Architecture Guide](https://hadoop.apache.org/docs/r3.2.1/hadoop-project-dist/hadoop-hdfs/HdfsDesign.html)

## License

This project is for educational and demonstration purposes.

## Contributing

Feel free to submit issues and enhancement requests!

---

**Note**: This project provides two deployment options:
- **Basic Pipeline**: Use the main [docker-compose.yml](docker-compose.yml) for Kafka → Flink → Elasticsearch → Kibana (real-time visualization)
- **Full Stack with HDFS**: Add the [docker-hadoop/](docker-hadoop/) services for persistent distributed storage and historical analytics
