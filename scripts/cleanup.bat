@echo off
REM OpenSearch Kubernetes Cleanup Script for Windows
REM This script removes all OpenSearch resources from the cluster

echo ========================================
echo OpenSearch K8s Cleanup for Windows
echo ========================================
echo.

echo WARNING: This will delete all OpenSearch resources and data!
echo.
set /p confirm="Are you sure you want to continue? (yes/no): "

if /i not "%confirm%"=="yes" (
    echo Cleanup cancelled.
    exit /b 0
)

echo.
echo [1/6] Deleting Services...
kubectl delete -f ..\k8s-manifests\05-services.yaml --ignore-not-found=true
echo.

echo [2/6] Deleting OpenSearch Dashboards Deployment...
kubectl delete -f ..\k8s-manifests\04-deployment-dashboards.yaml --ignore-not-found=true
echo.

echo [3/6] Deleting OpenSearch StatefulSet...
kubectl delete -f ..\k8s-manifests\03-statefulset.yaml --ignore-not-found=true
echo.

echo [4/6] Deleting PersistentVolumeClaim...
kubectl delete -f ..\k8s-manifests\02-pvc.yaml --ignore-not-found=true
echo.

echo [5/6] Deleting ConfigMaps...
kubectl delete -f ..\k8s-manifests\01-configmap.yaml --ignore-not-found=true
echo.

echo [6/6] Deleting Namespace...
kubectl delete -f ..\k8s-manifests\00-namespace.yaml --ignore-not-found=true
echo.

echo Waiting for resources to be fully deleted...
timeout /t 5 /nobreak >nul

echo.
echo ========================================
echo Cleanup Complete!
echo ========================================
echo.
echo All OpenSearch resources have been removed.
echo.

pause

@REM Made with Bob
