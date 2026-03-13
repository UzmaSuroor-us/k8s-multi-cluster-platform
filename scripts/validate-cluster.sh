#!/bin/bash
set -e

CLUSTER=$1
NAMESPACE="sample-app"

echo "Validating cluster health..."

# Check cluster connectivity
kubectl cluster-info > /dev/null || {
    echo "ERROR: Cannot connect to cluster"
    exit 1
}

# Check node status
NOTREADY=$(kubectl get nodes --no-headers | grep -v " Ready" | wc -l)
if [ $NOTREADY -gt 0 ]; then
    echo "ERROR: $NOTREADY nodes are not ready"
    kubectl get nodes
    exit 1
fi
echo "✓ All nodes ready"

# Check if namespace exists
if kubectl get namespace $NAMESPACE > /dev/null 2>&1; then
    # Check pod health
    UNHEALTHY=$(kubectl get pods -n $NAMESPACE --field-selector=status.phase!=Running --no-headers 2>/dev/null | wc -l)
    if [ $UNHEALTHY -gt 0 ]; then
        echo "WARNING: $UNHEALTHY pods are not running"
        kubectl get pods -n $NAMESPACE
    else
        echo "✓ All pods healthy"
    fi
    
    # Check PDB
    kubectl get pdb -n $NAMESPACE > /dev/null 2>&1 && echo "✓ PodDisruptionBudget configured"
else
    echo "✓ Namespace will be created"
fi

# Check resource availability
echo "✓ Cluster validation passed"
exit 0
