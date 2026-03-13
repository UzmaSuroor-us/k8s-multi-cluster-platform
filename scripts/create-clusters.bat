@echo off
echo Creating multi-cluster Kubernetes environment...

REM Check if kind is installed
where kind >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo kind not found. Install from: https://kind.sigs.k8s.io/docs/user/quick-start/#installation
    exit /b 1
)

REM Create dev cluster
echo Creating dev cluster...
kind create cluster --config clusters\dev\kind-config.yaml --name dev-cluster

REM Create prod cluster
echo Creating prod cluster...
kind create cluster --config clusters\prod\kind-config.yaml --name prod-cluster

REM Set up contexts
kubectl config rename-context kind-dev-cluster dev
kubectl config rename-context kind-prod-cluster prod

echo.
echo Clusters created successfully!
echo Switch contexts with:
echo   kubectl config use-context dev
echo   kubectl config use-context prod
echo.
echo Verify clusters:
kubectl config get-contexts
