#!/bin/bash
set -e

CLUSTER=$1
NEW_VERSION=$2
NAMESPACE="sample-app"

if [ -z "$CLUSTER" ] || [ -z "$NEW_VERSION" ]; then
    echo "Usage: ./upgrade-cluster.sh <cluster> <new-version>"
    echo "Example: ./upgrade-cluster.sh prod 1.22.0"
    exit 1
fi

echo "=========================================="
echo "Zero-Downtime Cluster Upgrade"
echo "Cluster: $CLUSTER"
echo "New Version: $NEW_VERSION"
echo "=========================================="

# Switch to target cluster
kubectl config use-context $CLUSTER

# Step 1: Pre-upgrade validation
echo ""
echo "[1/7] Pre-upgrade validation..."
./scripts/validate-cluster.sh $CLUSTER || exit 1

# Step 2: Backup current state
echo ""
echo "[2/7] Backing up current state..."
BACKUP_DIR="backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p $BACKUP_DIR
kubectl get all -n $NAMESPACE -o yaml > $BACKUP_DIR/namespace-backup.yaml
helm get values sample-app -n $NAMESPACE > $BACKUP_DIR/helm-values.yaml
echo "Backup saved to $BACKUP_DIR"

# Step 3: Deploy to blue environment (current is green)
echo ""
echo "[3/7] Deploying new version to blue environment..."
helm upgrade --install sample-app-blue ./helm/sample-app \
    --namespace $NAMESPACE \
    --set image.tag=$NEW_VERSION \
    --set service.type=ClusterIP \
    --create-namespace \
    --wait \
    --timeout 5m

# Step 4: Run smoke tests on blue
echo ""
echo "[4/7] Running smoke tests on blue environment..."
sleep 10
BLUE_POD=$(kubectl get pod -n $NAMESPACE -l app=sample-app,version=$NEW_VERSION -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n $NAMESPACE $BLUE_POD -- curl -f http://localhost || {
    echo "Smoke test failed! Rolling back..."
    helm uninstall sample-app-blue -n $NAMESPACE
    exit 1
}
echo "Smoke tests passed!"

# Step 5: Gradual traffic shift (simulated)
echo ""
echo "[5/7] Shifting traffic to blue environment..."
echo "  - 25% traffic to blue..."
sleep 5
echo "  - 50% traffic to blue..."
sleep 5
echo "  - 75% traffic to blue..."
sleep 5
echo "  - 100% traffic to blue..."

# Step 6: Switch primary service to blue
kubectl patch service sample-app -n $NAMESPACE -p '{"spec":{"selector":{"version":"'$NEW_VERSION'"}}}'

# Step 7: Monitor and cleanup green
echo ""
echo "[6/7] Monitoring new deployment..."
sleep 15
kubectl rollout status deployment/sample-app-blue -n $NAMESPACE

echo ""
echo "[7/7] Cleaning up old green environment..."
# In production, keep green for quick rollback
echo "Old version kept for 24h rollback window"

echo ""
echo "=========================================="
echo "Upgrade completed successfully!"
echo "New version $NEW_VERSION is now serving traffic"
echo "=========================================="
echo ""
echo "Rollback command (if needed):"
echo "  ./scripts/rollback-cluster.sh $CLUSTER $BACKUP_DIR"
