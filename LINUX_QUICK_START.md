# Complete Linux Setup - Quick Reference

## One-Command Full Setup

```bash
# Download and run the complete setup script
curl -fsSL https://raw.githubusercontent.com/YOUR_REPO/k8s-multi-cluster/main/full-setup-linux.sh | bash

# OR if you have the project locally:
cd ~/Desktop/k8s-multi-cluster
chmod +x full-setup-linux.sh
./full-setup-linux.sh
```

## Manual Step-by-Step Setup

### Step 1: Install Prerequisites (5 minutes)

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify installations
docker --version
kubectl version --client
kind version
helm version
```

### Step 2: Setup Project (2 minutes)

```bash
# Create project directory
mkdir -p ~/k8s-multi-cluster
cd ~/k8s-multi-cluster

# Copy all files from the Windows project
# OR download from repository
# OR use the full-setup-linux.sh script

# Make scripts executable
chmod +x scripts/*.sh
```

### Step 3: Create Clusters (3 minutes)

```bash
cd ~/k8s-multi-cluster

# Create both clusters
./scripts/create-clusters.sh

# Verify
kind get clusters
kubectl config get-contexts
kubectl get nodes --context dev
kubectl get nodes --context prod
```

### Step 4: Deploy Applications (5 minutes)

```bash
# Deploy to dev
./scripts/deploy-app.sh dev 1.21

# Deploy to prod
./scripts/deploy-app.sh prod 1.21

# Verify deployments
kubectl get all -n sample-app --context dev
kubectl get all -n sample-app --context prod
```

### Step 5: Test Features (15 minutes)

```bash
# Test 1: Zero-downtime upgrade
./scripts/upgrade-cluster.sh prod 1.22

# Test 2: Chaos engineering
./scripts/chaos-test.sh prod

# Test 3: Rollback
BACKUP_DIR=$(ls -t backups/ | head -1)
./scripts/rollback-cluster.sh prod backups/$BACKUP_DIR

# Test 4: Service migration
./scripts/migrate-service.sh dev prod
```

## Using the Automated Setup Script

The `full-setup-linux.sh` script does everything automatically:

```bash
cd ~/Desktop/k8s-multi-cluster
chmod +x full-setup-linux.sh
./full-setup-linux.sh
```

**What it does:**
1. ✅ Installs Docker, kubectl, kind, Helm
2. ✅ Creates project structure
3. ✅ Generates all configuration files
4. ✅ Creates dev and prod clusters
5. ✅ Deploys applications to both clusters
6. ✅ Verifies everything is working

**Time: ~10-15 minutes**

## Post-Setup Testing

### Quick Health Check
```bash
cd ~/k8s-multi-cluster

# Check clusters
kubectl get nodes --context dev
kubectl get nodes --context prod

# Check applications
kubectl get pods -n sample-app --context dev
kubectl get pods -n sample-app --context prod

# Check services
kubectl get svc -n sample-app --context dev
kubectl get svc -n sample-app --context prod
```

### Test Application Access
```bash
# Port forward to access the app
kubectl port-forward -n sample-app --context prod svc/sample-app 8080:80 &

# Test it
curl http://localhost:8080

# Stop port forward
pkill -f "port-forward"
```

### Monitor Resources
```bash
# Watch pods
kubectl get pods -n sample-app --context prod -w

# Check HPA
kubectl get hpa -n sample-app --context prod

# Check PDB
kubectl get pdb -n sample-app --context prod

# View events
kubectl get events -n sample-app --context prod --sort-by='.lastTimestamp'
```

## Common Commands

### Cluster Management
```bash
# List clusters
kind get clusters

# Switch context
kubectl config use-context dev
kubectl config use-context prod

# View current context
kubectl config current-context

# Delete clusters
kind delete cluster --name dev-cluster
kind delete cluster --name prod-cluster
```

### Application Management
```bash
# View all resources
kubectl get all -n sample-app --context prod

# View logs
kubectl logs -n sample-app -l app=sample-app --context prod

# Describe deployment
kubectl describe deployment sample-app -n sample-app --context prod

# Scale manually
kubectl scale deployment sample-app -n sample-app --replicas=5 --context prod

# Restart deployment
kubectl rollout restart deployment/sample-app -n sample-app --context prod
```

### Debugging
```bash
# Check pod details
kubectl describe pod <pod-name> -n sample-app --context prod

# Get pod logs
kubectl logs <pod-name> -n sample-app --context prod

# Execute command in pod
kubectl exec -it <pod-name> -n sample-app --context prod -- /bin/bash

# Check events
kubectl get events -n sample-app --context prod --sort-by='.lastTimestamp'
```

## Load Testing

```bash
# Install Apache Bench
sudo apt install apache2-utils -y

# Port forward
kubectl port-forward -n sample-app --context prod svc/sample-app 8080:80 &

# Run load test
ab -n 10000 -c 100 http://localhost:8080/

# Watch HPA scale
kubectl get hpa -n sample-app --context prod -w

# Watch pods scale
kubectl get pods -n sample-app --context prod -w
```

## Cleanup

```bash
# Delete applications
kubectl delete namespace sample-app --context dev
kubectl delete namespace sample-app --context prod

# Delete clusters
kind delete cluster --name dev-cluster
kind delete cluster --name prod-cluster

# Verify cleanup
kind get clusters
docker ps
```

## Troubleshooting

### Docker permission denied
```bash
sudo usermod -aG docker $USER
newgrp docker
# OR logout and login again
```

### Clusters won't create
```bash
# Check Docker is running
sudo systemctl status docker
sudo systemctl start docker

# Delete existing clusters
kind delete cluster --name dev-cluster
kind delete cluster --name prod-cluster

# Try again
./scripts/create-clusters.sh
```

### Pods stuck in Pending
```bash
# Check node resources
kubectl describe nodes --context prod

# Check events
kubectl get events -n sample-app --context prod

# Check pod details
kubectl describe pod <pod-name> -n sample-app --context prod
```

### Script permission denied
```bash
chmod +x scripts/*.sh
chmod +x full-setup-linux.sh
```

## System Requirements

- **OS**: Ubuntu 20.04+, Debian 10+, or similar
- **RAM**: 8GB minimum (16GB recommended)
- **CPU**: 4 cores minimum
- **Disk**: 20GB free space
- **Network**: Internet connection for downloads

## What Gets Installed

- Docker (container runtime)
- kubectl (Kubernetes CLI)
- kind (Kubernetes in Docker)
- Helm (package manager)
- 2 Kubernetes clusters (dev, prod)
- Sample application (nginx)
- All automation scripts

## Project Structure After Setup

```
~/k8s-multi-cluster/
├── clusters/
│   ├── dev/kind-config.yaml
│   └── prod/kind-config.yaml
├── helm/sample-app/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
├── scripts/
│   ├── create-clusters.sh
│   ├── deploy-app.sh
│   ├── upgrade-cluster.sh
│   ├── rollback-cluster.sh
│   ├── chaos-test.sh
│   ├── migrate-service.sh
│   └── validate-cluster.sh
├── backups/
├── terraform/
├── chaos-tests/
└── full-setup-linux.sh
```

## Next Steps After Setup

1. **Test zero-downtime upgrade**
   ```bash
   ./scripts/upgrade-cluster.sh prod 1.22
   ```

2. **Run chaos tests**
   ```bash
   ./scripts/chaos-test.sh prod
   ```

3. **Test rollback**
   ```bash
   BACKUP_DIR=$(ls -t backups/ | head -1)
   ./scripts/rollback-cluster.sh prod backups/$BACKUP_DIR
   ```

4. **Install monitoring (optional)**
   ```bash
   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
   ```

5. **Install Istio (optional)**
   ```bash
   curl -L https://istio.io/downloadIstio | sh -
   cd istio-*
   export PATH=$PWD/bin:$PATH
   istioctl install --set profile=demo -y
   ```

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review logs: `kubectl logs -n sample-app <pod-name>`
3. Check events: `kubectl get events -n sample-app`
4. Verify prerequisites are installed correctly

## Time Estimates

- Full automated setup: **10-15 minutes**
- Manual setup: **20-30 minutes**
- Testing all features: **15-20 minutes**
- Total: **30-45 minutes** for complete setup and testing
