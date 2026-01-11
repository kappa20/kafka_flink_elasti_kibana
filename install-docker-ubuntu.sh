#!/bin/bash

# Docker Installation Script for Ubuntu
# This script automates the installation of Docker Engine on Ubuntu systems

set -e

echo "============================================"
echo "Docker Installation Script for Ubuntu"
echo "============================================"
echo ""

# Check if running on Ubuntu
if [ ! -f /etc/os-release ]; then
    echo "Error: Cannot detect OS. This script is for Ubuntu only."
    exit 1
fi

. /etc/os-release
if [[ "$ID" != "ubuntu" ]]; then
    echo "Error: This script is designed for Ubuntu. Detected: $ID"
    exit 1
fi

echo "Detected: $PRETTY_NAME"
echo ""

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo "This script requires sudo privileges."
    echo "Please run with: sudo ./install-docker-ubuntu.sh"
    exit 1
fi

# Get the actual user (not root) for docker group assignment
ACTUAL_USER="${SUDO_USER:-$USER}"

echo "Step 1: Removing old Docker versions (if any)..."
apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
echo "✓ Old versions removed"
echo ""

echo "Step 2: Updating package index..."
apt-get update
echo "✓ Package index updated"
echo ""

echo "Step 3: Installing prerequisites..."
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
echo "✓ Prerequisites installed"
echo ""

echo "Step 4: Adding Docker's official GPG key..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "✓ GPG key added"
echo ""

echo "Step 5: Setting up Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
echo "✓ Repository configured"
echo ""

echo "Step 6: Updating package index with Docker repository..."
apt-get update
echo "✓ Package index updated"
echo ""

echo "Step 7: Installing Docker Engine..."
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
echo "✓ Docker Engine installed"
echo ""

echo "Step 8: Starting Docker service..."
systemctl start docker
systemctl enable docker
echo "✓ Docker service started and enabled"
echo ""

echo "Step 9: Adding user '$ACTUAL_USER' to docker group..."
groupadd docker 2>/dev/null || true
usermod -aG docker "$ACTUAL_USER"
echo "✓ User added to docker group"
echo ""

echo "Step 10: Verifying Docker installation..."
docker --version
docker compose version
echo "✓ Docker installed successfully"
echo ""

echo "Step 11: Testing Docker with hello-world..."
docker run hello-world
echo ""

echo "============================================"
echo "Docker Installation Complete!"
echo "============================================"
echo ""
echo "Installed versions:"
docker --version
docker compose version
echo ""
echo "IMPORTANT: To run Docker without sudo, you need to:"
echo "1. Log out and log back in, OR"
echo "2. Run: newgrp docker"
echo ""
echo "You can now use Docker commands!"
echo "Try: docker ps"
echo "============================================"
