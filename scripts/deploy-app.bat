@echo off
set CLUSTER=%1
set VERSION=%2

if "%CLUSTER%"=="" (
    echo Usage: deploy-app.bat ^<cluster^> ^<version^>
    echo Example: deploy-app.bat prod 1.21
    exit /b 1
)

if "%VERSION%"=="" (
    echo Usage: deploy-app.bat ^<cluster^> ^<version^>
    echo Example: deploy-app.bat prod 1.21
    exit /b 1
)

echo Deploying sample-app version %VERSION% to %CLUSTER% cluster...

REM Switch context
kubectl config use-context %CLUSTER%

REM Create namespace if not exists
kubectl create namespace sample-app --dry-run=client -o yaml | kubectl apply -f -

REM Deploy with Helm
helm upgrade --install sample-app .\helm\sample-app --namespace sample-app --set image.tag=%VERSION% --wait --timeout 5m

echo.
echo Deployment complete!
echo Check status:
echo   kubectl get pods -n sample-app
echo   kubectl get svc -n sample-app
