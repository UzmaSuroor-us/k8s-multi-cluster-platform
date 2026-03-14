# 🚀 Multi-Cluster Kubernetes Platform

[![CI - Build and Test](https://github.com/UzmaSuroor-us/k8s-multi-cluster-platform/workflows/CI%20-%20Build%20and%20Test/badge.svg)](https://github.com/UzmaSuroor-us/k8s-multi-cluster-platform/actions)
[![Deploy to Dev](https://github.com/UzmaSuroor-us/k8s-multi-cluster-platform/workflows/Deploy%20to%20Dev%20(Local)/badge.svg)](https://github.com/UzmaSuroor-us/k8s-multi-cluster-platform/actions)

A complete, production-ready Kubernetes platform that runs entirely on your local machine. Perfect for learning DevOps, testing deployments, and demonstrating enterprise Kubernetes patterns without cloud costs.

## 🎯 Overview

This project demonstrates a full-stack Kubernetes platform with:
- **Multi-cluster architecture** (dev/prod separation)
- **Complete CI/CD pipeline** with GitHub Actions
- **Production-grade monitoring** with Prometheus and Grafana
- **Service mesh** with Istio for advanced traffic management
- **Zero-downtime deployments** with automated rollbacks
- **Infrastructure as Code** with Terraform validation

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    GitHub Actions CI/CD                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   Build &   │  │   Deploy    │  │      Rollback           │  │ 
│  │    Test     │  │   to Dev    │  │    Deployment           │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Local Machine                            │
│                                                                 │
│  ┌─────────────────────┐           ┌─────────────────────────┐  │
│  │   Dev Cluster       │           │   Prod Cluster          │  │
│  │   (kind)            │           │   (kind)                │  │
│  │                     │           │                         │  │
│  │  ┌─────────────┐    │           │  ┌─────────────────┐    │  │
│  │  │ Sample App  │    │           │  │   Sample App    │    │  │
│  │  │ (2 replicas)│    │           │  │   (3 replicas)  │    │  │
│  │  └─────────────┘    │           │  └─────────────────┘    │  │
│  │  ┌─────────────┐    │           │                         │  │
│  │  │   Istio     │    │           │  ┌─────────────────┐    │  │
│  │  │ Service Mesh│    │           │  │   Prometheus    │    │  │
│  │  └─────────────┘    │           │  │   + Grafana     │    │  │
│  │                     │           │  │   Monitoring    │    │  │
│  │  Port: 30080        │           │  └─────────────────┘    │  │
│  └─────────────────────┘           │                         │  │
│                                    │  ┌─────────────────┐    │  │
│                                    │  │     Istio       │    │  │
│                                    │  │  Service Mesh   │    │  │
│                                    │  └─────────────────┘    │  │
│                                    │                         │  │
│                                    │  Port Forward: 8081     │  │
│                                    │  Grafana: 3000          │  │
│                                    │  Prometheus: 9090       │  │
│                                    └─────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## 🛠 Technology Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Container Orchestration** | Kubernetes (kind) | Multi-cluster container management |
| **CI/CD** | GitHub Actions | Automated testing and deployment |
| **Infrastructure** | Terraform | Infrastructure as Code validation |
| **Package Management** | Helm | Application deployment and management |
| **Monitoring** | Prometheus + Grafana | Metrics collection and visualization |
| **Service Mesh** | Istio | Traffic management and security |
| **Chaos Engineering** | Chaos Mesh | Resilience and fault injection testing |
| **Container Runtime** | Docker | Container execution environment |

## 🚀 Quick Start

### Prerequisites
- Docker Desktop or Docker Engine
- 8GB+ RAM recommended
- WSL2 (Windows) or Linux/macOS
- kubectl, helm, kind installed

### One-Command Setup
```bash
git clone https://github.com/UzmaSuroor-us/k8s-multi-cluster-platform.git
cd k8s-multi-cluster-platform
bash final-complete-setup.sh
```

### Access Services
- **Dev App**: http://localhost:30080
- **Prod App**: http://localhost:8081 (via port-forward)
- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090

## 📊 Features Demonstrated

### ✅ **Multi-Cluster Management**
- Separate dev and prod Kubernetes clusters
- Environment-specific configurations
- Cross-cluster service discovery

### ✅ **CI/CD Pipeline**
- Automated testing on pull requests
- Environment promotion (dev → prod)
- Manual approval gates for production
- Automated rollbacks on failure

### ✅ **Monitoring & Observability**
- Real-time metrics collection with Prometheus
- Pre-configured Grafana dashboards
- Application and infrastructure monitoring
- Custom alerting rules

### ✅ **Service Mesh**
- Istio for traffic management
- mTLS encryption between services
- Advanced routing and load balancing
- Security policies

### ✅ **Zero-Downtime Deployments**
- Rolling updates with health checks
- Automatic rollback on failure
- Blue-green deployment capability
- Canary release patterns

## 🔧 Usage Examples

### Deploy New Version
```bash
# Via GitHub Actions (generates instructions)
# Go to Actions → Deploy to Dev → Run workflow

# Or manually
kubectl config use-context kind-dev-cluster
helm upgrade --install sample-app helm/sample-app \
  --namespace sample-app --create-namespace \
  --set image.tag=1.22 \
  --wait --timeout 5m
```

### Monitor Applications
```bash
# Check application status
kubectl get pods -n sample-app --context kind-prod-cluster

# View metrics in Prometheus
curl 'http://localhost:9090/api/v1/query?query=up'

# Access Grafana dashboards
open http://localhost:3000
```

### Rollback Deployment
```bash
# Via GitHub Actions
# Go to Actions → Rollback → Select environment → Run workflow

# Or manually
kubectl rollout undo deployment/sample-app -n sample-app
```

## 📈 GitHub Actions Workflows

### 🔄 **CI - Build and Test**
- **Triggers**: Pull requests, pushes to develop
- **Actions**: Lint Helm charts, validate manifests, run tests
- **Purpose**: Ensure code quality before merging

### 🚀 **Deploy to Dev (Local)**
- **Triggers**: Push to main, manual trigger
- **Actions**: Generate deployment instructions for dev cluster
- **Purpose**: Automated dev environment updates

### 🎯 **Deploy to Production (Local)**
- **Triggers**: GitHub releases, manual trigger with confirmation
- **Actions**: Generate production deployment instructions
- **Purpose**: Controlled production deployments

### 🔄 **Rollback Deployment (Local)**
- **Triggers**: Manual only
- **Actions**: Generate rollback instructions
- **Purpose**: Quick recovery from bad deployments

## 🎓 Learning Outcomes

After working with this project, you'll understand:

- **Kubernetes Architecture**: Multi-cluster setup, networking, storage
- **CI/CD Best Practices**: Automated testing, deployment pipelines, GitOps
- **Monitoring & Observability**: Metrics collection, alerting, dashboards
- **Service Mesh**: Traffic management, security, observability
- **Infrastructure as Code**: Terraform, Helm, declarative configurations
- **DevOps Practices**: Zero-downtime deployments, rollback strategies
- **Container Orchestration**: Pod management, services, ingress

## 🔍 Project Structure

```
k8s-multi-cluster-platform/
├── .github/workflows/          # GitHub Actions CI/CD pipelines
├── clusters/                   # Kubernetes cluster configurations
│   ├── dev/                   # Development cluster config
│   └── prod/                  # Production cluster config
├── helm/                      # Helm charts
│   └── sample-app/           # Sample application chart
├── monitoring/               # Prometheus and Grafana configs
├── scripts/                  # Deployment and utility scripts
├── terraform/               # Infrastructure as Code
├── chaos-tests/            # Chaos engineering scenarios
└── README.md              # This file
```

## 🚨 Troubleshooting

### Common Issues

**Clusters not starting**
```bash
# Check Docker is running
docker ps

# Recreate clusters
kind delete cluster --name dev-cluster
kind delete cluster --name prod-cluster
bash final-complete-setup.sh
```

**Port conflicts**
```bash
# Check what's using ports
netstat -tulpn | grep :30080
netstat -tulpn | grep :3000

# Kill conflicting processes
sudo kill -9 <PID>
```

**Istio issues**
```bash
# Disable Istio injection if causing problems
kubectl label namespace sample-app istio-injection=disabled --overwrite
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Kubernetes community for excellent documentation
- Prometheus and Grafana teams for monitoring tools
- Istio project for service mesh capabilities
- GitHub Actions for CI/CD automation

## 📞 Contact

- **GitHub**: [@UzmaSuroor-us](https://github.com/UzmaSuroor-us)
- **Project Link**: [https://github.com/UzmaSuroor-us/k8s-multi-cluster-platform](https://github.com/UzmaSuroor-us/k8s-multi-cluster-platform)

---

⭐ **Star this repository if it helped you learn Kubernetes and DevOps!** ⭐
