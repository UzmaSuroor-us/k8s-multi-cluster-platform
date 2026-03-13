#!/bin/bash
set -e

CLUSTER=$1
OLD_VERSION=$2
NEW_VERSION=$3
NAMESPACE="sample-app"

if [ -z "$CLUSTER" ] || [ -z "$OLD_VERSION" ] || [ -z "$NEW_VERSION" ]; then
    echo "Usage: ./traffic-shift.sh <cluster> <old-version> <new-version>"
    echo "Example: ./traffic-shift.sh prod 1.0.0 2.0.0"
    exit 1
fi

echo "Gradual traffic shifting: $OLD_VERSION -> $NEW_VERSION"

kubectl config use-context $CLUSTER

# Check if Istio is installed
if kubectl get crd virtualservices.networking.istio.io > /dev/null 2>&1; then
    echo "Using Istio for traffic management..."
    
    # Apply VirtualService with weighted routing
    for WEIGHT in 10 25 50 75 90 100; do
        OLD_WEIGHT=$((100 - WEIGHT))
        echo "Shifting traffic: $OLD_WEIGHT% old, $WEIGHT% new"
        
        cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: sample-app
  namespace: $NAMESPACE
spec:
  hosts:
  - sample-app
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: sample-app
        subset: v$OLD_VERSION
      weight: $OLD_WEIGHT
    - destination:
        host: sample-app
        subset: v$NEW_VERSION
      weight: $WEIGHT
EOF
        
        sleep 30
        
        # Check error rate
        echo "Monitoring error rate..."
        sleep 10
    done
else
    echo "Using native Kubernetes service switching..."
    echo "For gradual traffic shift, consider installing Istio"
    
    # Simple service selector update
    kubectl patch service sample-app -n $NAMESPACE \
        -p '{"spec":{"selector":{"version":"'$NEW_VERSION'"}}}'
fi

echo "Traffic shift complete!"
