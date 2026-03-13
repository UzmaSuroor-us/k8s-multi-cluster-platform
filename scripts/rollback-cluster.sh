#!/bin/bash
set -e

CLUSTER=$1
BACKUP_DIR=$2
NAMESPACE="sample-app"

if [ -z "$CLUSTER" ] || [ -z "$BACKUP_DIR" ]; then
    echo "Usage: ./rollback-cluster.sh <cluster> <backup-dir>"
    echo "Example: ./rollback-cluster.sh prod backups/20240115-143022"
    exit 1
fi

echo "=========================================="
echo "Rolling back cluster: $CLUSTER"
echo "Using backup: $BACKUP_DIR"
echo "=========================================="

# Switch context
kubectl config use-context $CLUSTER

# Confirm rollback
read -p "Are you sure you want to rollback? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Rollback cancelled"
    exit 0
fi

echo ""
echo "[1/3] Restoring from backup..."
if [ -f "$BACKUP_DIR/helm-values.yaml" ]; then
    helm upgrade --install sample-app ./helm/sample-app \
        -n $NAMESPACE \
        -f $BACKUP_DIR/helm-values.yaml \
        --wait \
        --timeout 5m
else
    echo "ERROR: Backup not found at $BACKUP_DIR"
    exit 1
fi

echo ""
echo "[2/3] Verifying rollback..."
kubectl rollout status deployment/sample-app -n $NAMESPACE

echo ""
echo "[3/3] Cleanup blue environment..."
helm uninstall sample-app-blue -n $NAMESPACE 2>/dev/null || true

echo ""
echo "=========================================="
echo "Rollback completed successfully!"
echo "=========================================="
