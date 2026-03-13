# Linux Testing Guide - Multi-Cluster Kubernetes Platform

## Prerequisites Installation (Ubuntu/Debian)

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

## Step-by-Step Testing

### Step 1: Create Clusters (5 minutes)

```bash
cd ~/Desktop/k8s-multi-cluster

# Make scripts executable
chmod +x scripts/*.sh

# Create both clusters
./scripts/create-clusters.sh

# Expected output:
# Creating dev cluster...
# Creating prod cluster...
# Clusters created successfully!

# Verify clusters are running
kind get clusters
# Output: dev-cluster, prod-cluster

# Check contexts
kubectl config get-contexts
# Should show: dev, prod

# Verify nodes
kubectl get nodes --context dev
kubectl get nodes --context prod
```

### Step 2: Deploy to Dev Cluster (3 minutes)

```bash
# Deploy version 1.21 to dev
./scripts/deploy-app.sh dev 1.21

# Watch deployment
kubectl get pods -n sample-app --context dev -w
# Press Ctrl+C to stop watching

# Check all resources
kubectl get all -n sample-app --context dev

# Expected output:
# - 3 pods running
# - 1 service (LoadBalancer)
# - 1 deployment
# - 1 HPA
```

### Step 3: Test Dev Application (2 minutes)

```bash
# Get service details
kubectl get svc -n sample-app --context dev

# Port forward to access the app
kubectl port-forward -n sample-app --context dev svc/sample-app 8080:80 &

# Test the application
curl http://localhost:8080
# Should return nginx welcome page

# Check HPA
kubectl get hpa -n sample-app --context dev

# Check PDB
kubectl get pdb -n sample-app --context dev

# Kill port-forward
pkill -f "port-forward"
```

### Step 4: Deploy to Prod Cluster (3 minutes)

```bash
# Deploy same version to prod
./scripts/deploy-app.sh prod 1.21

# Verify deployment
kubectl get all -n sample-app --context prod

# Check pod distribution across nodes
kubectl get pods -n sample-app --context prod -o wide
```

### Step 5: Zero-Downtime Upgrade Test (10 minutes)

```bash
# This is the main feature - upgrade prod to new version
./scripts/upgrade-cluster.sh prod 1.22

# The script will:
# [1/7] Pre-upgrade validation...
# [2/7] Backing up current state...
# [3/7] Deploying new version to blue environment...
# [4/7] Running smoke tests on blue environment...
# [5/7] Shifting traffic to blue environment...
# [6/7] Monitoring new deployment...
# [7/7] Cleaning up old green environment...

# Verify upgrade
kubectl get pods -n sample-app --context prod
kubectl get deployments -n sample-app --context prod

# Check backup was created
ls -la backups/
```

### Step 6: Test Rollback (5 minutes)

```bash
# List available backups
ls -la backups/

# Rollback to previous version
BACKUP_DIR=$(ls -t backups/ | head -1)
./scripts/rollback-cluster.sh prod backups/$BACKUP_DIR

# Type 'yes' when prompted

# Verify rollback
kubectl get pods -n sample-app --context prod
kubectl describe deployment sample-app -n sample-app --context prod | grep Image
```

### Step 7: Chaos Engineering Tests (5 minutes)

```bash
# Run chaos tests on prod
./scripts/chaos-test.sh prod

# Tests will run:
# [Test 1/4] Pod Deletion Test - Deletes a pod, watches recovery
# [Test 2/4] Resource Stress Test - CPU stress + HPA check
# [Test 3/4] Network Latency Test - Requires Chaos Mesh
# [Test 4/4] Rolling Restart Test - Zero-downtime restart

# Watch pods recover in real-time
kubectl get pods -n sample-app --context prod -w
```

### Step 8: Service Migration Test (5 minutes)

```bash
# Migrate service from dev to prod
./scripts/migrate-service.sh dev prod

# Follow prompts:
# - Press enter when traffic cutover is complete
# - Type 'yes' or 'no' to cleanup source

# Verify migration
kubectl get all -n sample-app --context dev
kubectl get all -n sample-app --context prod
```

### Step 9: Advanced - Install Chaos Mesh (Optional, 10 minutes)

```bash
# Switch to prod cluster
kubectl config use-context prod

# Install Chaos Mesh
curl -sSL https://mirrors.chaos-mesh.org/latest/install.sh | bash

# Wait for pods to be ready
kubectl get pods -n chaos-mesh

# Apply chaos experiments
kubectl apply -f chaos-tests/chaos-experiments.yaml

# Watch chaos in action
kubectl get podchaos -n sample-app
kubectl get networkchaos -n sample-app
kubectl get stresschaos -n sample-app

# Check pod events
kubectl get events -n sample-app --sort-by='.lastTimestamp'

# Cleanup chaos experiments
kubectl delete -f chaos-tests/chaos-experiments.yaml
```

### Step 10: Advanced - Traffic Shifting with Istio (Optional, 15 minutes)

```bash
# Install Istio
curl -L https://istio.io/downloadIstio | sh -
cd istio-*
export PATH=$PWD/bin:$PATH

# Install Istio on prod cluster
kubectl config use-context prod
istioctl install --set profile=demo -y

# Enable Istio injection
kubectl label namespace sample-app istio-injection=enabled

# Restart pods to inject sidecar
kubectl rollout restart deployment/sample-app -n sample-app

# Verify sidecars
kubectl get pods -n sample-app
# Should show 2/2 containers per pod

# Test gradual traffic shift
cd ~/Desktop/k8s-multi-cluster
./scripts/traffic-shift.sh prod 1.21 1.22

# Monitor traffic distribution
kubectl get virtualservice -n sample-app
```

## Validation Commands

### Check Cluster Health
```bash
# Node status
kubectl get nodes --context prod

# Pod status
kubectl get pods -n sample-app --context prod

# Service endpoints
kubectl get endpoints -n sample-app --context prod

# Events
kubectl get events -n sample-app --context prod --sort-by='.lastTimestamp' | tail -20
```

### Check High Availability Features
```bash
# HPA status
kubectl get hpa -n sample-app --context prod
kubectl describe hpa sample-app -n sample-app --context prod

# PDB status
kubectl get pdb -n sample-app --context prod
kubectl describe pdb sample-app -n sample-app --context prod

# Deployment strategy
kubectl get deployment sample-app -n sample-app --context prod -o yaml | grep -A 5 strategy
```

### Monitor Resources
```bash
# Pod resource usage
kubectl top pods -n sample-app --context prod

# Node resource usage
kubectl top nodes --context prod

# Describe deployment
kubectl describe deployment sample-app -n sample-app --context prod
```

## Load Testing (Optional)

```bash
# Install Apache Bench
sudo apt install apache2-utils -y

# Port forward the service
kubectl port-forward -n sample-app --context prod svc/sample-app 8080:80 &

# Run load test (1000 requests, 10 concurrent)
ab -n 1000 -c 10 http://localhost:8080/

# Watch HPA scale up
kubectl get hpa -n sample-app --context prod -w

# Watch pods scale
kubectl get pods -n sample-app --context prod -w

# Kill port-forward
pkill -f "port-forward"
```

## Troubleshooting

### Clusters won't create
```bash
# Check Docker is running
docker ps

# Delete existing clusters
kind delete cluster --name dev-cluster
kind delete cluster --name prod-cluster

# Recreate
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

### Deployment fails
```bash
# Check logs
kubectl logs -n sample-app --context prod -l app=sample-app

# Check deployment status
kubectl rollout status deployment/sample-app -n sample-app --context prod

# Rollback
kubectl rollout undo deployment/sample-app -n sample-app --context prod
```

### Script permission denied
```bash
# Make all scripts executable
chmod +x scripts/*.sh

# Or individually
chmod +x scripts/create-clusters.sh
chmod +x scripts/deploy-app.sh
```

## Cleanup

```bash
# Delete all resources from clusters
kubectl delete namespace sample-app --context dev
kubectl delete namespace sample-app --context prod

# Delete clusters
kind delete cluster --name dev-cluster
kind delete cluster --name prod-cluster

# Verify cleanup
kind get clusters
docker ps
```

## Complete Test Run (30 minutes)

```bash
# Full end-to-end test
cd ~/Desktop/k8s-multi-cluster

# 1. Setup
./scripts/create-clusters.sh

# 2. Deploy
./scripts/deploy-app.sh dev 1.21
./scripts/deploy-app.sh prod 1.21

# 3. Verify
kubectl get all -n sample-app --context dev
kubectl get all -n sample-app --context prod

# 4. Upgrade (zero-downtime)
./scripts/upgrade-cluster.sh prod 1.22

# 5. Chaos test
./scripts/chaos-test.sh prod

# 6. Rollback test
BACKUP_DIR=$(ls -t backups/ | head -1)
./scripts/rollback-cluster.sh prod backups/$BACKUP_DIR
# Type 'yes' when prompted

# 7. Migration test
./scripts/migrate-service.sh dev prod
# Press enter, type 'no' for cleanup

# 8. Cleanup
kind delete cluster --name dev-cluster
kind delete cluster --name prod-cluster

echo "All tests completed successfully!"
```

## Expected Results

✅ **Clusters**: 2 clusters (dev, prod) with multiple nodes
✅ **Deployments**: 3 replicas per cluster, all running
✅ **Zero-Downtime**: Upgrade completes without pod unavailability
✅ **Rollback**: Instant recovery to previous version
✅ **Chaos**: Pods self-heal after deletion
✅ **HPA**: Auto-scales under load
✅ **PDB**: Maintains minimum availability during disruptions

## Performance Benchmarks

- Cluster creation: ~2 minutes
- Application deployment: ~1 minute
- Zero-downtime upgrade: ~3-5 minutes
- Rollback: ~30 seconds
- Pod recovery after deletion: ~10 seconds
- HPA scale-up: ~30-60 seconds

## Next Steps

1. Add monitoring with Prometheus/Grafana
2. Implement GitOps with ArgoCD
3. Deploy to cloud (AWS EKS) using Terraform
4. Add service mesh (Istio/Linkerd)
5. Implement multi-region setup
