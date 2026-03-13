#!/bin/bash
set -e

echo "=========================================="
echo "Prod Cluster Creation - Advanced Fix"
echo "=========================================="
echo ""

# Check environment
echo "Checking environment..."
uname -a
echo ""

# Check Docker
echo "Checking Docker..."
docker info | grep -i "cgroup\|storage"
echo ""

# Method 1: Simplest possible config
echo "Method 1: Creating prod cluster with minimal config..."
cat > /tmp/prod-simple.yaml <<'EOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: prod-cluster
nodes:
- role: control-plane
- role: worker
EOF

kind delete cluster --name prod-cluster 2>/dev/null || true
sleep 2

if kind create cluster --config /tmp/prod-simple.yaml --wait 5m; then
    echo "✓ Method 1 succeeded!"
    kubectl config rename-context kind-prod-cluster prod 2>/dev/null || true
    exit 0
fi

echo "Method 1 failed, trying Method 2..."
echo ""

# Method 2: No config file at all
echo "Method 2: Creating prod cluster without config file..."
kind delete cluster --name prod-cluster 2>/dev/null || true
sleep 2

if kind create cluster --name prod-cluster --wait 5m; then
    echo "✓ Method 2 succeeded!"
    kubectl config rename-context kind-prod-cluster prod 2>/dev/null || true
    exit 0
fi

echo "Method 2 failed, trying Method 3..."
echo ""

# Method 3: With explicit image version
echo "Method 3: Using older Kubernetes version..."
cat > /tmp/prod-old.yaml <<'EOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: prod-cluster
nodes:
- role: control-plane
  image: kindest/node:v1.27.3
- role: worker
  image: kindest/node:v1.27.3
EOF

kind delete cluster --name prod-cluster 2>/dev/null || true
sleep 2

if kind create cluster --config /tmp/prod-old.yaml --wait 5m; then
    echo "✓ Method 3 succeeded!"
    kubectl config rename-context kind-prod-cluster prod 2>/dev/null || true
    exit 0
fi

echo "Method 3 failed, trying Method 4..."
echo ""

# Method 4: Restart Docker and retry
echo "Method 4: Restarting Docker daemon..."
sudo systemctl restart docker 2>/dev/null || sudo service docker restart
sleep 5

kind delete cluster --name prod-cluster 2>/dev/null || true
sleep 2

if kind create cluster --name prod-cluster --wait 5m; then
    echo "✓ Method 4 succeeded!"
    kubectl config rename-context kind-prod-cluster prod 2>/dev/null || true
    exit 0
fi

echo ""
echo "=========================================="
echo "All methods failed. Diagnostics:"
echo "=========================================="
echo ""
echo "This is likely a WSL2/systemd issue."
echo "Workaround: Use dev cluster with separate namespaces"
echo ""
echo "Run this to simulate multi-cluster:"
echo "  kubectl create namespace prod-env --context dev"
echo "  kubectl config set-context prod --cluster=kind-dev-cluster --user=kind-dev-cluster --namespace=prod-env"
echo ""
exit 1
