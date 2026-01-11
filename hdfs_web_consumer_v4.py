from kafka import KafkaConsumer
from json import loads, dumps
from rich import print
import subprocess
import tempfile
import os
import time
from datetime import datetime
from collections import deque

# 1. Setup Kafka Consumer
# Changed to 'latest' to only process NEW messages (not old backlog)
consumer = KafkaConsumer(
    'my-topic-test',
    bootstrap_servers=['localhost:9092'],
    api_version=(0, 10),
    auto_offset_reset='latest',  # Only read new messages from now on
    enable_auto_commit=True,
    group_id='hdfs-consumer-group',  # Track position
    value_deserializer=lambda x: loads(x.decode('utf-8'))
)

hdfs_base_path = '/kafka_demo'

# Buffer for batching writes
tweet_buffer = deque()
BATCH_SIZE = 10  # Write to HDFS every 10 tweets
BATCH_TIMEOUT = 30  # Or every 30 seconds
last_write_time = time.time()
batch_counter = 0

# 2. Initialize HDFS directory
def init_hdfs():
    """Create HDFS directory if it doesn't exist"""
    try:
        subprocess.run(
            ['docker', 'exec', 'namenode', 'hdfs', 'dfs', '-mkdir', '-p', hdfs_base_path],
            capture_output=True,
            check=False
        )
        subprocess.run(
            ['docker', 'exec', 'namenode', 'hdfs', 'dfs', '-chmod', '-R', '777', hdfs_base_path],
            capture_output=True,
            check=False
        )
        print("[green]✓ HDFS directory initialized[/green]")
    except Exception as e:
        print(f"[red]Error initializing HDFS: {e}[/red]")

# 3. Function to flush buffer to HDFS
def flush_to_hdfs():
    """Write buffered tweets to HDFS using timestamped filename to avoid lease conflicts"""
    global tweet_buffer, last_write_time, batch_counter

    if not tweet_buffer:
        return True

    try:
        # Use timestamped filename to avoid lease conflicts
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        batch_counter += 1
        hdfs_file = f'{hdfs_base_path}/tweets_{timestamp}_{batch_counter}.json'

        # Create a temporary file with all buffered tweets
        with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.json') as tmp:
            for tweet in tweet_buffer:
                tmp.write(dumps(tweet) + "\n")
            tmp_path = tmp.name

        # Copy temp file into container
        subprocess.run(
            ['docker', 'cp', tmp_path, 'namenode:/tmp/tweet_batch.json'],
            capture_output=True,
            check=True,
            timeout=10
        )

        # Put file to HDFS (new unique file each time, no append needed)
        result = subprocess.run(
            ['docker', 'exec', 'namenode', 'hdfs', 'dfs', '-put', '/tmp/tweet_batch.json', hdfs_file],
            capture_output=True,
            check=True,
            timeout=10
        )

        # Clean up temp files
        os.remove(tmp_path)
        subprocess.run(
            ['docker', 'exec', 'namenode', 'rm', '-f', '/tmp/tweet_batch.json'],
            capture_output=True,
            check=False,
            timeout=5
        )

        count = len(tweet_buffer)
        tweet_buffer.clear()
        last_write_time = time.time()

        print(f"[green]✔ Wrote {count} tweets to {hdfs_file}[/green]")
        return True

    except subprocess.TimeoutExpired:
        print(f"[red]✗ Timeout writing to HDFS[/red]")
        return False
    except subprocess.CalledProcessError as e:
        error_msg = e.stderr.decode() if e.stderr else str(e)
        print(f"[red]✗ Error writing to HDFS: {error_msg}[/red]")
        return False
    except Exception as e:
        print(f"[red]✗ Error: {e}[/red]")
        return False

# Initialize HDFS
print("[yellow]Initializing HDFS directory...[/yellow]")
init_hdfs()

print("[bold cyan]HDFS Consumer V4 is live! Listening for Kafka messages...[/bold cyan]")
print(f"[dim]Writing batches of {BATCH_SIZE} tweets to timestamped files (no lease conflicts!)[/dim]")
print("")

# 4. Process messages
try:
    for message in consumer:
        tweet = message.value

        # Add to buffer
        tweet_buffer.append(tweet)
        print(f"[cyan]→ Buffered tweet from {tweet['username']} ({len(tweet_buffer)}/{BATCH_SIZE})[/cyan]")

        # Check if we should flush
        time_since_last_write = time.time() - last_write_time

        if len(tweet_buffer) >= BATCH_SIZE or time_since_last_write >= BATCH_TIMEOUT:
            flush_to_hdfs()

except KeyboardInterrupt:
    print("\n[yellow]Shutting down... flushing remaining tweets[/yellow]")
    if tweet_buffer:
        flush_to_hdfs()
    print("[green]✓ Gracefully shut down[/green]")
