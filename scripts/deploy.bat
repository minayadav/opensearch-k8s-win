@echo off
REM OpenSearch Kubernetes Deployment Script for Windows
REM This script deploys OpenSearch and Dashboards to local Kubernetes cluster

echo ========================================
echo OpenSearch K8s Deployment for Windows
echo ========================================
echo.

REM Check if kubectl is available
kubectl version --client >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: kubectl is not installed or not in PATH
    echo Please install kubectl and try again
    exit /b 1
)

REM Check if Kubernetes cluster is running
kubectl cluster-info >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Kubernetes cluster is not running
    echo Please start Docker Desktop with Kubernetes enabled
    exit /b 1
)

echo [1/7] Creating namespace...
kubectl apply -f ..\k8s-manifests\00-namespace.yaml
if %errorlevel% neq 0 (
    echo ERROR: Failed to create namespace
    exit /b 1
)
echo.

echo [2/7] Creating ConfigMaps...
kubectl apply -f ..\k8s-manifests\01-configmap.yaml
if %errorlevel% neq 0 (
    echo ERROR: Failed to create ConfigMaps
    exit /b 1
)
echo.

echo [3/7] Creating PersistentVolume and PersistentVolumeClaim...
kubectl apply -f ..\k8s-manifests\02-pvc.yaml
if %errorlevel% neq 0 (
    echo ERROR: Failed to create PVC
    exit /b 1
)
echo.

echo [4/7] Deploying OpenSearch StatefulSet...
kubectl apply -f ..\k8s-manifests\03-statefulset.yaml
if %errorlevel% neq 0 (
    echo ERROR: Failed to deploy OpenSearch
    exit /b 1
)
echo.

echo [5/7] Deploying OpenSearch Dashboards...
kubectl apply -f ..\k8s-manifests\04-deployment-dashboards.yaml
if %errorlevel% neq 0 (
    echo ERROR: Failed to deploy Dashboards
    exit /b 1
)
echo.

echo [6/7] Creating Services...
kubectl apply -f ..\k8s-manifests\05-services.yaml
if %errorlevel% neq 0 (
    echo ERROR: Failed to create Services
    exit /b 1
)
echo.

echo [7/7] Waiting for pods to be ready...
echo This may take 2-3 minutes...
echo.

timeout /t 10 /nobreak >nul

echo Checking pod status...
kubectl get pods -n opensearch
echo.

echo ========================================
echo Deployment Complete!
echo ========================================
echo.
echo Access URLs:
echo   OpenSearch API: http://localhost:30920
echo   OpenSearch Dashboards: http://localhost:30561
echo.
echo To check status: kubectl get all -n opensearch
echo To view logs: kubectl logs -n opensearch -l app=opensearch
echo.
echo Note: It may take 2-3 minutes for all services to be fully ready
echo.

pause

@REM Made with Bob
