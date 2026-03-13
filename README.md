# Multi-Cluster Kubernetes Platform with Zero-Downtime Upgrades

## Architecture Overview
- **Dev Cluster**: Testing and validation
- **Prod Cluster**: Production workloads with blue-green upgrade strategy
- **Traffic Management**: Gradual traffic shifting during upgrades
- **Automated Rollback**: Health checks with automatic rollback

## Prerequisites
- Docker Desktop with Kubernetes enabled OR kind installed
- kubectl, helm, kubectx
- (Optional) Istio for advanced traffic management

## Quick Start

### 1. Create Clusters
```bash
# Using kind
./scripts/create-clusters.sh

# Or manually with Docker Desktop - enable Kubernetes in settings
```

### 2. Deploy Application
```bash
./scripts/deploy-app.sh dev v1.0.0
./scripts/deploy-app.sh prod v1.0.0
```

### 3. Perform Zero-Downtime Upgrade
```bash
./scripts/upgrade-cluster.sh prod v2.0.0
```

### 4. Run Chaos Tests
```bash
./scripts/chaos-test.sh prod
```

## Project Structure
```
├── clusters/          # Cluster configs
├── helm/             # Helm charts
├── scripts/          # Automation scripts
├── terraform/        # IaC (optional)
└── chaos-tests/      # Failure simulation
```
