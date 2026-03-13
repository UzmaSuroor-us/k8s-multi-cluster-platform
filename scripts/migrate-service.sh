#!/bin/bash
set -e

SOURCE_CLUSTER=$1
TARGET_CLUSTER=$2
NAMESPACE="sample-app"

if [ -z "$SOURCE_CLUSTER" ] || [ -z "$TARGET_CLUSTER" ]; then
    echo "Usage: ./migrate-service.sh <source-cluster> <target-cluster>"
    echo "Example: ./migrate-service.sh dev prod"
    exit 1
fi

echo "=========================================="
echo "Migrating service: $SOURCE_CLUSTER -> $TARGET_CLUSTER"
echo "=========================================="

# Step 1: Export from source
echo ""
echo "[1/5] Exporting configuration from $SOURCE_CLUSTER..."
kubectl config use-context $SOURCE_CLUSTER
helm get values sample-app -n $NAMESPACE > /tmp/migration-values.yaml

# Step 2: Deploy to target
echo ""
echo "[2/5] Deploying to $TARGET_CLUSTER..."
kubectl config use-context $TARGET_CLUSTER
helm upgrade --install sample-app ./helm/sample-app \
    -n $NAMESPACE \
    -f /tmp/migration-values.yaml \
    --create-namespace \
    --wait \
    --timeout 5m

# Step 3: Validate target
echo ""
echo "[3/5] Validating target deployment..."
kubectl rollout status deployment/sample-app -n $NAMESPACE
kubectl get pods -n $NAMESPACE

# Step 4: DNS/Traffic cutover (manual step)
echo ""
echo "[4/5] Traffic cutover..."
echo "Update your load balancer or DNS to point to $TARGET_CLUSTER"
echo "Target cluster service:"
kubectl get svc sample-app -n $NAMESPACE

read -p "Press enter when traffic cutover is complete..."

# Step 5: Cleanup source (optional)
echo ""
echo "[5/5] Cleanup source cluster..."
read -p "Remove service from $SOURCE_CLUSTER? (yes/no): " CLEANUP
if [ "$CLEANUP" = "yes" ]; then
    kubectl config use-context $SOURCE_CLUSTER
    helm uninstall sample-app -n $NAMESPACE
    echo "Source cluster cleaned up"
fi

echo ""
echo "=========================================="
echo "Migration complete!"
echo "=========================================="

rm /tmp/migration-values.yaml
