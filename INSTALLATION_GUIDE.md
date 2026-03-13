# Complete Installation Guide - All Methods

## Method 1: Using Package Managers (RECOMMENDED)

### Ubuntu/Debian

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
newgrp docker

# Install kubectl
sudo apt install -y apt-transport-https ca-certificates curl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubectl

# Install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Install Helm (using snap - most reliable)
sudo snap install helm --classic

# OR Install Helm from binary
wget https://get.helm.sh/helm-v3.13.0-linux-amd64.tar.gz
tar -zxvf helm-v3.13.0-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm
rm -rf linux-amd64 helm-v3.13.0-linux-amd64.tar.gz
```

### Fedora/RHEL/CentOS

```bash
# Install Docker
sudo dnf install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
newgrp docker

# Install kubectl
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/repodata/repomd.xml.key
EOF
sudo dnf install -y kubectl

# Install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Install Helm
sudo dnf install -y helm

# OR from binary
wget https://get.helm.sh/helm-v3.13.0-linux-amd64.tar.gz
tar -zxvf helm-v3.13.0-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm
rm -rf linux-amd64 helm-v3.13.0-linux-amd64.tar.gz
```

### Arch Linux

```bash
# Install Docker
sudo pacman -S docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
newgrp docker

# Install kubectl
sudo pacman -S kubectl

# Install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Install Helm
sudo pacman -S helm
```

## Method 2: Direct Binary Installation (Works on All Linux)

```bash
# Create bin directory
mkdir -p ~/bin
export PATH=$HOME/bin:$PATH
echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc

# Install Docker (use get.docker.com script)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker
rm get-docker.sh

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl
# OR move to ~/bin/kubectl if no sudo

# Install kind
curl -Lo kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x kind
sudo mv kind /usr/local/bin/kind
# OR move to ~/bin/kind if no sudo

# Install Helm (direct download)
wget https://get.helm.sh/helm-v3.13.0-linux-amd64.tar.gz
tar -zxvf helm-v3.13.0-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm
# OR move to ~/bin/helm if no sudo
rm -rf linux-amd64 helm-v3.13.0-linux-amd64.tar.gz

# Verify installations
docker --version
kubectl version --client
kind version
helm version
```

## Method 3: Using Homebrew (Linux)

```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add to PATH
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Install tools
brew install docker
brew install kubectl
brew install kind
brew install helm

# Start Docker
sudo systemctl start docker
sudo usermod -aG docker $USER
newgrp docker
```

## Method 4: Offline Installation (No Internet)

```bash
# Download these files on a machine with internet:
# 1. Docker: https://download.docker.com/linux/static/stable/x86_64/docker-24.0.7.tgz
# 2. kubectl: https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl
# 3. kind: https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
# 4. Helm: https://get.helm.sh/helm-v3.13.0-linux-amd64.tar.gz

# Transfer to target machine, then:

# Install Docker
tar -xzf docker-24.0.7.tgz
sudo cp docker/* /usr/local/bin/
sudo dockerd &

# Install kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install kind
chmod +x kind-linux-amd64
sudo mv kind-linux-amd64 /usr/local/bin/kind

# Install Helm
tar -xzf helm-v3.13.0-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/
```

## Troubleshooting Helm Installation

### Issue: curl script fails

**Solution 1: Use wget**
```bash
wget -O - https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

**Solution 2: Use snap (Ubuntu/Debian)**
```bash
sudo snap install helm --classic
```

**Solution 3: Direct binary download**
```bash
# Find latest version at: https://github.com/helm/helm/releases
wget https://get.helm.sh/helm-v3.13.0-linux-amd64.tar.gz
tar -zxvf helm-v3.13.0-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm
chmod +x /usr/local/bin/helm
rm -rf linux-amd64 helm-v3.13.0-linux-amd64.tar.gz

# Verify
helm version
```

**Solution 4: Use package manager**
```bash
# Ubuntu/Debian
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

# Fedora/RHEL
sudo dnf install helm
```

## Verification Commands

```bash
# Check Docker
docker --version
docker ps

# Check kubectl
kubectl version --client

# Check kind
kind version

# Check Helm
helm version

# Check all at once
echo "Docker: $(docker --version)"
echo "kubectl: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
echo "kind: $(kind version)"
echo "Helm: $(helm version --short)"
```

## Common Issues and Fixes

### Docker permission denied
```bash
sudo usermod -aG docker $USER
newgrp docker
# OR logout and login again
```

### kubectl not found
```bash
# Add to PATH
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
source ~/.bashrc
```

### kind not found
```bash
# Check if it's in the right location
which kind
ls -la /usr/local/bin/kind

# If not, reinstall
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

### Helm not found
```bash
# Check installation
which helm
ls -la /usr/local/bin/helm

# Reinstall using snap (easiest)
sudo snap install helm --classic

# OR download binary
wget https://get.helm.sh/helm-v3.13.0-linux-amd64.tar.gz
tar -zxvf helm-v3.13.0-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm
rm -rf linux-amd64 helm-v3.13.0-linux-amd64.tar.gz
```

## Complete Installation Script (All-in-One)

```bash
#!/bin/bash
set -e

echo "Installing Kubernetes tools..."

# Install Docker
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "Docker installed"
else
    echo "Docker already installed"
fi

# Install kubectl
if ! command -v kubectl &> /dev/null; then
    echo "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/kubectl
    echo "kubectl installed"
else
    echo "kubectl already installed"
fi

# Install kind
if ! command -v kind &> /dev/null; then
    echo "Installing kind..."
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
    echo "kind installed"
else
    echo "kind already installed"
fi

# Install Helm (try multiple methods)
if ! command -v helm &> /dev/null; then
    echo "Installing Helm..."
    
    # Try snap first (most reliable)
    if command -v snap &> /dev/null; then
        echo "Installing Helm via snap..."
        sudo snap install helm --classic
    else
        # Fall back to binary download
        echo "Installing Helm from binary..."
        wget https://get.helm.sh/helm-v3.13.0-linux-amd64.tar.gz
        tar -zxvf helm-v3.13.0-linux-amd64.tar.gz
        sudo mv linux-amd64/helm /usr/local/bin/helm
        rm -rf linux-amd64 helm-v3.13.0-linux-amd64.tar.gz
    fi
    echo "Helm installed"
else
    echo "Helm already installed"
fi

# Verify installations
echo ""
echo "Verifying installations..."
echo "Docker: $(docker --version)"
echo "kubectl: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
echo "kind: $(kind version)"
echo "Helm: $(helm version --short)"

echo ""
echo "All tools installed successfully!"
echo "Note: You may need to logout and login for docker group to take effect"
```

Save this as `install-tools.sh` and run:
```bash
chmod +x install-tools.sh
./install-tools.sh
```

## After Installation

```bash
# Activate docker group (or logout/login)
newgrp docker

# Verify everything works
docker ps
kubectl version --client
kind version
helm version

# Now proceed with cluster setup
cd ~/k8s-multi-cluster
./scripts/create-clusters.sh
```

## System Requirements

- **OS**: Linux (Ubuntu 20.04+, Debian 10+, Fedora 35+, RHEL 8+, Arch)
- **RAM**: 8GB minimum (16GB recommended)
- **CPU**: 4 cores minimum
- **Disk**: 20GB free space
- **Privileges**: sudo access required for installation
- **Network**: Internet connection for downloads

## Alternative: Use Docker Desktop for Linux

```bash
# Download from: https://docs.docker.com/desktop/install/linux-install/
# Includes kubectl and kind built-in

# Ubuntu/Debian
wget https://desktop.docker.com/linux/main/amd64/docker-desktop-4.25.0-amd64.deb
sudo apt install ./docker-desktop-4.25.0-amd64.deb

# Then just install Helm
sudo snap install helm --classic
```
