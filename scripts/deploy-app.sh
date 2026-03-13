#!/bin/bash
set -e

CLUSTER=$1
VERSION=$2

if [ -z "$CLUSTER" ] || [ -z "$VERSION" ]; then
    echo "Usage: ./deploy-app.sh <cluster> <version>"
    echo "Example: ./deploy-app.sh prod 1.0.0"
    exit 1
fi

echo "Deploying sample-app version $VERSION to $CLUSTER cluster..."

# Switch context
kubectl config use-context $CLUSTER

# Create namespace if not exists
kubectl create namespace sample-app --dry-run=client -o yaml | kubectl apply -f -

# Deploy with Helm
helm upgrade --install sample-app ./helm/sample-app \
    --namespace sample-app \
    --set image.tag=$VERSION \
    --wait \
    --timeout 5m

echo ""
echo "Deployment complete!"
echo "Check status:"
echo "  kubectl get pods -n sample-app"
echo "  kubectl get svc -n sample-app"
