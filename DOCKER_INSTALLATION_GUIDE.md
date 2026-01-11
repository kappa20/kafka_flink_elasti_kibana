# Docker Installation Guide for Linux

This guide provides step-by-step instructions for installing Docker on Linux distributions.

## Table of Contents
- [Ubuntu/Debian](#ubuntudebian)
- [CentOS/RHEL](#centosrhel)
- [Fedora](#fedora)
- [Arch Linux](#arch-linux)
- [Verify Installation](#verify-installation)
- [Post-Installation Steps](#post-installation-steps)
- [Troubleshooting](#troubleshooting)

---

## Ubuntu/Debian

### Uninstall Old Versions (if any)
```bash
sudo apt-get remove docker docker-engine docker.io containerd runc
```

### Installation Steps

1. **Update package index**
   ```bash
   sudo apt-get update
   ```

2. **Install prerequisites**
   ```bash
   sudo apt-get install -y \
       ca-certificates \
       curl \
       gnupg \
       lsb-release
   ```

3. **Add Docker's official GPG key**
   ```bash
   sudo mkdir -p /etc/apt/keyrings
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
   ```

4. **Set up the repository**
   ```bash
   echo \
     "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
     $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   ```

5. **Update package index again**
   ```bash
   sudo apt-get update
   ```

6. **Install Docker Engine**
   ```bash
   sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
   ```

---

## CentOS/RHEL

### Uninstall Old Versions (if any)
```bash
sudo yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
```

### Installation Steps

1. **Install prerequisites**
   ```bash
   sudo yum install -y yum-utils
   ```

2. **Set up the repository**
   ```bash
   sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
   ```

3. **Install Docker Engine**
   ```bash
   sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
   ```

4. **Start Docker service**
   ```bash
   sudo systemctl start docker
   ```

5. **Enable Docker to start on boot**
   ```bash
   sudo systemctl enable docker
   ```

---

## Fedora

### Uninstall Old Versions (if any)
```bash
sudo dnf remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine
```

### Installation Steps

1. **Install prerequisites**
   ```bash
   sudo dnf install -y dnf-plugins-core
   ```

2. **Set up the repository**
   ```bash
   sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
   ```

3. **Install Docker Engine**
   ```bash
   sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
   ```

4. **Start Docker service**
   ```bash
   sudo systemctl start docker
   ```

5. **Enable Docker to start on boot**
   ```bash
   sudo systemctl enable docker
   ```

---

## Arch Linux

### Installation Steps

1. **Install Docker from official repositories**
   ```bash
   sudo pacman -S docker docker-compose
   ```

2. **Start Docker service**
   ```bash
   sudo systemctl start docker.service
   ```

3. **Enable Docker to start on boot**
   ```bash
   sudo systemctl enable docker.service
   ```

---

## Verify Installation

After installation, verify Docker is working correctly:

### Check Docker version
```bash
docker --version
```

### Check Docker Compose version
```bash
docker compose version
```

### Run the hello-world container
```bash
sudo docker run hello-world
```

### Check Docker service status
```bash
sudo systemctl status docker
```

---

## Post-Installation Steps

### Run Docker without sudo (Recommended)

1. **Create the docker group** (if it doesn't exist)
   ```bash
   sudo groupadd docker
   ```

2. **Add your user to the docker group**
   ```bash
   sudo usermod -aG docker $USER
   ```

3. **Apply the new group membership**
   ```bash
   newgrp docker
   ```
   Or log out and log back in.

4. **Verify you can run docker without sudo**
   ```bash
   docker run hello-world
   ```

### Configure Docker to start on boot

```bash
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
```

### Configure Docker daemon (Optional)

Create or edit `/etc/docker/daemon.json`:

```bash
sudo mkdir -p /etc/docker
sudo nano /etc/docker/daemon.json
```

Example configuration:
```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "default-address-pools": [
    {
      "base": "172.17.0.0/16",
      "size": 24
    }
  ]
}
```

Restart Docker after changes:
```bash
sudo systemctl restart docker
```

---

## Troubleshooting

### Permission denied errors
If you get permission denied when running docker commands:
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Docker daemon not starting
Check the logs:
```bash
sudo journalctl -u docker.service
```

Restart the service:
```bash
sudo systemctl restart docker
```

### Check Docker daemon status
```bash
sudo systemctl status docker
```

### Docker network issues
Reset Docker network:
```bash
sudo systemctl restart docker
```

### Firewall issues
If using firewalld (CentOS/RHEL/Fedora):
```bash
sudo firewall-cmd --permanent --zone=trusted --add-interface=docker0
sudo firewall-cmd --reload
```

---

## Uninstall Docker

### Ubuntu/Debian
```bash
sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
```

### CentOS/RHEL/Fedora
```bash
sudo yum remove docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
```

### Arch Linux
```bash
sudo pacman -R docker docker-compose
sudo rm -rf /var/lib/docker
```

---

## Additional Resources

- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Engine on Linux](https://docs.docker.com/engine/install/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Docker Post-installation steps](https://docs.docker.com/engine/install/linux-postinstall/)
