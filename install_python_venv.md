# Python Virtual Environment Setup for Kafka-Flink Pipeline

This guide shows how to set up a Python virtual environment on Linux for the Kafka-Flink-Elasticsearch project.

## Minimum Requirements

- **Python 3.8 or higher** (Python 3.8, 3.9, 3.10, 3.11, or 3.12 all work)
- pip package manager
- venv module (usually included with Python)

## Quick Setup (Using System Python)

If you already have Python 3.8+ installed on your system:

```bash
# Check your Python version
python3 --version

# If >= 3.8, create virtual environment directly
python3 -m venv kafka_3_10

# Activate the virtual environment
source kafka_3_10/bin/activate

# Upgrade pip inside the venv
pip install --upgrade pip

# Install project requirements
pip install -r requirements.txt
```

## Installing Python 3.10 (If Needed)

If your system Python is older than 3.8, you can install Python 3.10 from the deadsnakes PPA:

```bash
# Add deadsnakes PPA for latest Python versions
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa

# Install Python 3.10 and required build tools
sudo apt update
sudo apt install build-essential python3-dev
sudo apt install python3.10 python3.10-venv

# Create virtual environment with Python 3.10
python3.10 -m venv kafka_3_10

# Activate the virtual environment
source kafka_3_10/bin/activate

# Upgrade pip inside the venv
pip install --upgrade pip

# Install project requirements
pip install -r requirements.txt
```

## Alternative: Using Python 3.8 or 3.9

You can use any Python version >= 3.8:

```bash
# For Python 3.8
sudo apt install python3.8 python3.8-venv
python3.8 -m venv kafka_3_10

# For Python 3.9
sudo apt install python3.9 python3.9-venv
python3.9 -m venv kafka_3_10

# For Python 3.11
sudo apt install python3.11 python3.11-venv
python3.11 -m venv kafka_3_10

# Then activate and install requirements (same for all versions)
source kafka_3_10/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

## Verifying the Installation

After installing the requirements, verify everything is set up correctly:

```bash
# Check installed packages
pip list

# You should see:
# - kafka-python (2.0.2)
# - apache-flink (1.18.0)
# - hdfs (2.7.3)
# - rich (13.7.0)

# Test import (should not show errors)
python -c "from kafka import KafkaProducer; from pyflink.datastream import StreamExecutionEnvironment; print('All imports successful!')"
```

## Deactivating the Virtual Environment

When you're done working:

```bash
deactivate
```

## Reactivating Later

To use the environment again in a new terminal session:

```bash
cd /path/to/kafka_flink_elasti_kibana
source kafka_3_10/bin/activate
```

## Troubleshooting

### Issue: "python3-venv not found"

```bash
# Install venv package for your Python version
sudo apt install python3.10-venv  # or python3.8-venv, python3.9-venv, etc.
```

### Issue: "build-essential required" during pip install

```bash
# Install compilation tools needed for some Python packages
sudo apt install build-essential python3-dev
```

### Issue: pip install fails with SSL errors

```bash
# Update CA certificates
sudo apt update
sudo apt install --reinstall ca-certificates

# Retry installation
pip install --upgrade pip
pip install -r requirements.txt
```

## Notes

- The virtual environment name `kafka_3_10` is just a convention - you can name it anything
- **Minimum Python version: 3.8** - older versions will not work with apache-flink 1.18.0
- The virtual environment is portable within the same system architecture
- Always activate the venv before running any Python scripts in this project
