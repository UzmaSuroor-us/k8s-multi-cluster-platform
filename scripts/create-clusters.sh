#!/bin/bash
set -e

echo "Creating multi-cluster Kubernetes environment..."

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    echo "kind not found. Install from: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
    exit 1
fi

# Create dev cluster
echo "Creating dev cluster..."
kind create cluster --config clusters/dev/kind-config.yaml --name dev-cluster

# Create prod cluster
echo "Creating prod cluster..."
kind create cluster --config clusters/prod/kind-config.yaml --name prod-cluster

# Set up contexts
kubectl config rename-context kind-dev-cluster dev
kubectl config rename-context kind-prod-cluster prod

echo ""
echo "Clusters created successfully!"
echo "Switch contexts with:"
echo "  kubectl config use-context dev"
echo "  kubectl config use-context prod"
echo ""
echo "Verify clusters:"
kubectl config get-contexts
