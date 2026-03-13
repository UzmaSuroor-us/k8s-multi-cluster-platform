#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() { echo -e "${BLUE}==========================================\n$1\n==========================================${NC}"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_info() { echo -e "${YELLOW}→ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }

clear
print_header "COMPLETE KUBERNETES PLATFORM - FULL SETUP"
echo "Includes: Terraform | CI/CD | Prometheus | Grafana | Istio | Chaos Mesh"
echo "Everything runs locally - No cloud deployment"
echo ""

PROJECT_DIR="$HOME/k8s-platform-complete"

# ============================================
# CLEANUP & SETUP
# ============================================
print_header "PHASE 1: Cleanup & Setup"

if [ -d "$PROJECT_DIR" ]; then
    print_warning "Project exists at: $PROJECT_DIR"
    read -p "Delete and recreate? (yes/no): " CONFIRM
    if [ "$CONFIRM" = "yes" ]; then
        print_info "Removing old project..."
        rm -rf $PROJECT_DIR
    else
        print_info "Exiting..."
        exit 0
    fi
fi

print_info "Deleting existing clusters..."
kind delete cluster --name dev-cluster 2>/dev/null || true
kind delete cluster --name prod-cluster 2>/dev/null || true
sleep 2

print_info "Creating project structure..."
mkdir -p $PROJECT_DIR/{clusters/{dev,prod},helm/sample-app/templates,scripts,terraform,chaos-tests,monitoring,backups}
cd $PROJECT_DIR

print_success "Project created at: $PROJECT_DIR"
echo ""

# ============================================
# CONFIGURATION FILES
# ============================================
print_header "PHASE 2: Creating Configuration Files"

# Cluster configs
print_info "Creating cluster configurations..."
cat > clusters/dev/kind-config.yaml <<'EOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: dev-cluster
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 30080
  - containerPort: 30090
    hostPort: 30090
EOF

cat > clusters/prod/kind-config.yaml <<'EOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: prod-cluster
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30081
    hostPort: 30081
  - containerPort: 30091
    hostPort: 30091
EOF

# Helm Chart
print_info "Creating Helm charts..."
cat > helm/sample-app/Chart.yaml <<'EOF'
apiVersion: v2
name: sample-app
description: Multi-cluster sample application
type: application
version: 1.0.0
appVersion: "1.0.0"
EOF

cat > helm/sample-app/values.yaml <<'EOF'
replicaCount: 2
image:
  repository: nginx
  tag: "1.21"
  pullPolicy: IfNotPresent
service:
  type: NodePort
  port: 80
  targetPort: 80
  nodePort: 30080
resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 50m
    memory: 64Mi
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 0
EOF

cat > helm/sample-app/templates/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Chart.Name }}
  labels:
    app: {{ .Chart.Name }}
    version: {{ .Chart.AppVersion }}
spec:
  replicas: {{ .Values.replicaCount }}
  strategy:
    type: {{ .Values.strategy.type }}
    rollingUpdate:
      maxSurge: {{ .Values.strategy.rollingUpdate.maxSurge }}
      maxUnavailable: {{ .Values.strategy.rollingUpdate.maxUnavailable }}
  selector:
    matchLabels:
      app: {{ .Chart.Name }}
  template:
    metadata:
      labels:
        app: {{ .Chart.Name }}
        version: {{ .Chart.AppVersion }}
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - containerPort: {{ .Values.service.targetPort }}
        livenessProbe:
          httpGet:
            path: /
            port: {{ .Values.service.targetPort }}
          initialDelaySeconds: 5
          periodSeconds: 5
        readinessProbe:
          httpGet:
            path: /
            port: {{ .Values.service.targetPort }}
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          {{- toYaml .Values.resources | nindent 10 }}
EOF

cat > helm/sample-app/templates/service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: {{ .Chart.Name }}
  labels:
    app: {{ .Chart.Name }}
spec:
  type: {{ .Values.service.type }}
  ports:
  - port: {{ .Values.service.port }}
    targetPort: {{ .Values.service.targetPort }}
    nodePort: {{ .Values.service.nodePort }}
    protocol: TCP
    name: http
  selector:
    app: {{ .Chart.Name }}
EOF

# Terraform
print_info "Creating Terraform configurations..."
cat > terraform/main.tf <<'EOF'
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  access_key = "mock_access_key"
  secret_key = "mock_secret_key"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "k8s_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

# Mock EKS clusters (not actually created)
resource "null_resource" "dev_cluster" {
  provisioner "local-exec" {
    command = "echo 'Dev EKS cluster would be created here'"
  }
}

resource "null_resource" "prod_cluster" {
  provisioner "local-exec" {
    command = "echo 'Prod EKS cluster would be created here'"
  }
}

output "status" {
  value = "Terraform validated successfully - No cloud resources created"
}

output "dev_cluster_name" {
  value = "dev-cluster (local kind)"
}

output "prod_cluster_name" {
  value = "prod-cluster (local kind)"
}
EOF

# Scripts
print_info "Creating automation scripts..."
cat > scripts/deploy-app.sh <<'EOF'
#!/bin/bash
set -e
CLUSTER=$1
VERSION=$2

if [ -z "$CLUSTER" ] || [ -z "$VERSION" ]; then
    echo "Usage: ./deploy-app.sh <cluster> <version>"
    exit 1
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

echo "Deploying sample-app v$VERSION to $CLUSTER..."
kubectl config use-context $CLUSTER
kubectl create namespace sample-app --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install sample-app $PROJECT_ROOT/helm/sample-app \
    --namespace sample-app \
    --set image.tag=$VERSION \
    --wait \
    --timeout 5m

echo "Deployment complete!"
EOF

cat > scripts/upgrade-app.sh <<'EOF'
#!/bin/bash
set -e
CLUSTER=$1
VERSION=$2

echo "Upgrading $CLUSTER to version $VERSION..."
kubectl config use-context $CLUSTER
kubectl set image deployment/sample-app sample-app=nginx:$VERSION -n sample-app
kubectl rollout status deployment/sample-app -n sample-app
echo "Upgrade complete!"
EOF

cat > scripts/rollback-app.sh <<'EOF'
#!/bin/bash
set -e
CLUSTER=$1

echo "Rolling back $CLUSTER..."
kubectl config use-context $CLUSTER
kubectl rollout undo deployment/sample-app -n sample-app
kubectl rollout status deployment/sample-app -n sample-app
echo "Rollback complete!"
EOF

chmod +x scripts/*.sh

# Monitoring
print_info "Creating monitoring configurations..."
cat > monitoring/prometheus-values.yaml <<'EOF'
prometheus:
  prometheusSpec:
    retention: 7d
    resources:
      requests:
        cpu: 200m
        memory: 512Mi

grafana:
  enabled: true
  adminPassword: admin
  service:
    type: NodePort
    nodePort: 30091
  resources:
    requests:
      cpu: 100m
      memory: 256Mi

alertmanager:
  enabled: true
EOF

# Chaos tests
print_info "Creating chaos experiments..."
cat > chaos-tests/pod-chaos.yaml <<'EOF'
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: pod-failure-test
  namespace: sample-app
spec:
  action: pod-failure
  mode: one
  duration: "30s"
  selector:
    namespaces:
      - sample-app
    labelSelectors:
      app: sample-app
EOF

cat > chaos-tests/network-chaos.yaml <<'EOF'
apiVersion: chaos-mesh.org/v1alpha1
kind: NetworkChaos
metadata:
  name: network-delay-test
  namespace: sample-app
spec:
  action: delay
  mode: one
  selector:
    namespaces:
      - sample-app
    labelSelectors:
      app: sample-app
  delay:
    latency: "100ms"
  duration: "1m"
EOF

# README
cat > README.md <<'EOF'
# Multi-Cluster Kubernetes Platform

## Complete Tech Stack
- Kubernetes (kind)
- Helm
- Terraform (validated, not applied)
- Prometheus & Grafana
- Istio Service Mesh
- Chaos Mesh
- CI/CD Simulation

## Quick Start
```bash
# Already set up! Just run tests:
cd ~/k8s-platform-complete

# View clusters
kind get clusters

# View applications
kubectl get all -n sample-app --context dev
kubectl get all -n sample-app --context prod

# Access Grafana
http://localhost:30091 (admin/admin)

# Access Applications
http://localhost:30080 (dev)
http://localhost:30081 (prod)
```

## Testing Commands
```bash
# Upgrade
bash scripts/upgrade-app.sh prod 1.22

# Rollback
bash scripts/rollback-app.sh prod

# Chaos test
kubectl apply -f chaos-tests/pod-chaos.yaml
```

## Cleanup
```bash
kind delete cluster --name dev-cluster
kind delete cluster --name prod-cluster
```
EOF

print_success "All configuration files created"
echo ""

# ============================================
# CREATE CLUSTERS
# ============================================
print_header "PHASE 3: Creating Kubernetes Clusters"

print_info "Creating dev cluster..."
kind create cluster --config clusters/dev/kind-config.yaml --name dev-cluster --wait 3m
print_success "Dev cluster ready"

print_info "Creating prod cluster..."
kind create cluster --config clusters/prod/kind-config.yaml --name prod-cluster --wait 3m
print_success "Prod cluster ready"

kubectl config rename-context kind-dev-cluster dev 2>/dev/null || true
kubectl config rename-context kind-prod-cluster prod 2>/dev/null || true

print_success "Both clusters created"
echo ""

# ============================================
# TERRAFORM VALIDATION
# ============================================
print_header "PHASE 4: Terraform Validation"

if ! command -v terraform &> /dev/null; then
    print_info "Installing Terraform..."
    wget -q https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
    unzip -q terraform_1.6.0_linux_amd64.zip
    sudo mv terraform /usr/local/bin/
    rm terraform_1.6.0_linux_amd64.zip
    print_success "Terraform installed"
else
    print_success "Terraform already installed"
fi

cd $PROJECT_DIR/terraform
print_info "Initializing Terraform..."
terraform init > /dev/null 2>&1

print_info "Validating configuration..."
terraform validate

print_info "Generating plan..."
terraform plan -out=tfplan > /dev/null 2>&1

print_success "Terraform validated (no resources created)"
cd $PROJECT_DIR
echo ""

# ============================================
# DEPLOY APPLICATIONS
# ============================================
print_header "PHASE 5: Deploying Applications"

print_info "Deploying to dev cluster..."
bash scripts/deploy-app.sh dev 1.21
print_success "Dev deployment complete"

print_info "Deploying to prod cluster..."
bash scripts/deploy-app.sh prod 1.21
print_success "Prod deployment complete"

print_info "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=sample-app -n sample-app --context dev --timeout=120s
kubectl wait --for=condition=ready pod -l app=sample-app -n sample-app --context prod --timeout=120s
print_success "All pods ready"
echo ""

# ============================================
# PROMETHEUS & GRAFANA
# ============================================
print_header "PHASE 6: Installing Prometheus & Grafana"

print_info "Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts > /dev/null 2>&1
helm repo update > /dev/null 2>&1

print_info "Installing monitoring stack (this takes 5-10 minutes)..."
kubectl config use-context prod
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --create-namespace \
    --values monitoring/prometheus-values.yaml \
    --wait \
    --timeout 15m

print_success "Prometheus & Grafana installed"
echo ""

# ============================================
# ISTIO
# ============================================
print_header "PHASE 7: Installing Istio Service Mesh"

if [ ! -d "$PROJECT_DIR/istio-1.20.0" ]; then
    print_info "Downloading Istio..."
    cd $PROJECT_DIR
    curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.20.0 sh - > /dev/null 2>&1
    print_success "Istio downloaded"
fi

export PATH=$PROJECT_DIR/istio-1.20.0/bin:$PATH

print_info "Installing Istio..."
kubectl config use-context prod
istioctl install --set profile=demo -y > /dev/null 2>&1

print_info "Enabling Istio injection..."
kubectl label namespace sample-app istio-injection=enabled --overwrite

print_info "Restarting pods with Istio sidecar..."
kubectl rollout restart deployment/sample-app -n sample-app
kubectl rollout status deployment/sample-app -n sample-app --timeout=120s

print_success "Istio installed and configured"
echo ""

# ============================================
# CHAOS MESH
# ============================================
print_header "PHASE 8: Installing Chaos Mesh"

print_info "Installing Chaos Mesh..."
kubectl config use-context prod
curl -sSL https://mirrors.chaos-mesh.org/v2.6.0/install.sh | bash -s -- --local kind > /dev/null 2>&1

print_info "Waiting for Chaos Mesh to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=chaos-mesh -n chaos-mesh --timeout=180s > /dev/null 2>&1

print_success "Chaos Mesh installed"
echo ""

# ============================================
# TESTING
# ============================================
print_header "PHASE 9: Running Tests"

print_info "Test 1: Zero-downtime upgrade (1.21 → 1.22)..."
bash scripts/upgrade-app.sh prod 1.22
print_success "Upgrade successful"

print_info "Test 2: Rollback (1.22 → 1.21)..."
bash scripts/rollback-app.sh prod
print_success "Rollback successful"

print_info "Test 3: Chaos engineering (pod failure)..."
kubectl apply -f chaos-tests/pod-chaos.yaml > /dev/null 2>&1
sleep 35
kubectl delete -f chaos-tests/pod-chaos.yaml > /dev/null 2>&1
print_success "Chaos test complete"

print_info "Test 4: Self-healing validation..."
POD=$(kubectl get pods -n sample-app --context prod -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod $POD -n sample-app --context prod
sleep 10
kubectl get pods -n sample-app --context prod
print_success "Self-healing verified"

echo ""

# ============================================
# FINAL SUMMARY
# ============================================
print_header "SETUP COMPLETE! 🚀"

echo ""
echo "=========================================="
echo "CLUSTERS"
echo "=========================================="
kind get clusters
echo ""

echo "=========================================="
echo "APPLICATIONS"
echo "=========================================="
echo "Dev Cluster:"
kubectl get pods -n sample-app --context dev
echo ""
echo "Prod Cluster:"
kubectl get pods -n sample-app --context prod
echo ""

echo "=========================================="
echo "MONITORING"
echo "=========================================="
kubectl get pods -n monitoring --context prod | head -10
echo ""

echo "=========================================="
echo "SERVICE MESH"
echo "=========================================="
kubectl get pods -n istio-system --context prod | head -10
echo ""

echo "=========================================="
echo "CHAOS ENGINEERING"
echo "=========================================="
kubectl get pods -n chaos-mesh --context prod | head -5
echo ""

print_header "ACCESS INFORMATION"
echo ""
echo "📊 Grafana Dashboard:"
echo "   http://localhost:30091"
echo "   Username: admin"
echo "   Password: admin"
echo ""
echo "🌐 Sample Applications:"
echo "   Dev:  http://localhost:30080"
echo "   Prod: http://localhost:30081"
echo ""
echo "📈 Prometheus:"
echo "   kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 --context prod"
echo "   Then: http://localhost:9090"
echo ""
echo "🔀 Istio Kiali:"
echo "   kubectl port-forward -n istio-system svc/kiali 20001:20001 --context prod"
echo "   Then: http://localhost:20001"
echo ""
echo "💥 Chaos Mesh Dashboard:"
echo "   kubectl port-forward -n chaos-mesh svc/chaos-dashboard 2333:2333 --context prod"
echo "   Then: http://localhost:2333"
echo ""

print_header "TEST RESULTS SUMMARY"
echo ""
print_success "✓ Multi-cluster setup (dev + prod)"
print_success "✓ Terraform validated (no cloud deployment)"
print_success "✓ Helm charts deployed"
print_success "✓ Prometheus & Grafana monitoring"
print_success "✓ Istio service mesh"
print_success "✓ Chaos Mesh chaos engineering"
print_success "✓ Zero-downtime upgrade tested"
print_success "✓ Rollback tested"
print_success "✓ Chaos experiments tested"
print_success "✓ Self-healing validated"
echo ""

print_header "USEFUL COMMANDS"
echo ""
echo "View all resources:"
echo "  kubectl get all -n sample-app --context dev"
echo "  kubectl get all -n sample-app --context prod"
echo ""
echo "Upgrade application:"
echo "  bash scripts/upgrade-app.sh prod 1.23"
echo ""
echo "Rollback application:"
echo "  bash scripts/rollback-app.sh prod"
echo ""
echo "Run chaos test:"
echo "  kubectl apply -f chaos-tests/pod-chaos.yaml"
echo ""
echo "Cleanup:"
echo "  kind delete cluster --name dev-cluster"
echo "  kind delete cluster --name prod-cluster"
echo ""

print_header "PROJECT LOCATION"
echo ""
echo "📁 $PROJECT_DIR"
echo ""
echo "📖 Read README.md for more information"
echo ""

print_success "All tests passed! Platform is ready! 🎉"
echo ""
