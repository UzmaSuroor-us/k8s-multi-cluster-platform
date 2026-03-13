#!/bin/bash
set -e

echo "Creating multi-cluster Kubernetes environment..."

# Get the script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

echo "Project root: $PROJECT_ROOT"

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    echo "kind not found. Please install kind first."
    exit 1
fi

# Check if config files exist
if [ ! -f "$PROJECT_ROOT/clusters/dev/kind-config.yaml" ]; then
    echo "ERROR: Dev cluster config not found at $PROJECT_ROOT/clusters/dev/kind-config.yaml"
    echo "Please run this script from the project root or scripts directory"
    exit 1
fi

if [ ! -f "$PROJECT_ROOT/clusters/prod/kind-config.yaml" ]; then
    echo "ERROR: Prod cluster config not found at $PROJECT_ROOT/clusters/prod/kind-config.yaml"
    exit 1
fi

# Create dev cluster
echo "Creating dev cluster..."
kind create cluster --config "$PROJECT_ROOT/clusters/dev/kind-config.yaml" --name dev-cluster

# Create prod cluster
echo "Creating prod cluster..."
kind create cluster --config "$PROJECT_ROOT/clusters/prod/kind-config.yaml" --name prod-cluster

# Set up contexts
kubectl config rename-context kind-dev-cluster dev 2>/dev/null || true
kubectl config rename-context kind-prod-cluster prod 2>/dev/null || true

echo ""
echo "Clusters created successfully!"
echo "Switch contexts with:"
echo "  kubectl config use-context dev"
echo "  kubectl config use-context prod"
echo ""
echo "Verify clusters:"
kubectl config get-contexts
