# OpenSearch Kubernetes Deployment Script for Windows (PowerShell)
# This script deploys OpenSearch and Dashboards to local Kubernetes cluster

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OpenSearch K8s Deployment for Windows" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if kubectl is available
try {
    $null = kubectl version --client 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "kubectl not found"
    }
} catch {
    Write-Host "ERROR: kubectl is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install kubectl and try again" -ForegroundColor Yellow
    exit 1
}

# Check if Kubernetes cluster is running
try {
    $null = kubectl cluster-info 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Cluster not running"
    }
} catch {
    Write-Host "ERROR: Kubernetes cluster is not running" -ForegroundColor Red
    Write-Host "Please start Docker Desktop with Kubernetes enabled" -ForegroundColor Yellow
    exit 1
}

# Get the script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$manifestsDir = Join-Path (Split-Path -Parent $scriptDir) "k8s-manifests"

Write-Host "[1/7] Creating namespace..." -ForegroundColor Green
kubectl apply -f "$manifestsDir\00-namespace.yaml"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to create namespace" -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Host "[2/7] Creating ConfigMaps..." -ForegroundColor Green
kubectl apply -f "$manifestsDir\01-configmap.yaml"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to create ConfigMaps" -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Host "[3/7] Creating PersistentVolume and PersistentVolumeClaim..." -ForegroundColor Green
kubectl apply -f "$manifestsDir\02-pvc.yaml"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to create PVC" -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Host "[4/7] Deploying OpenSearch StatefulSet..." -ForegroundColor Green
kubectl apply -f "$manifestsDir\03-statefulset.yaml"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to deploy OpenSearch" -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Host "[5/7] Deploying OpenSearch Dashboards..." -ForegroundColor Green
kubectl apply -f "$manifestsDir\04-deployment-dashboards.yaml"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to deploy Dashboards" -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Host "[6/7] Creating Services..." -ForegroundColor Green
kubectl apply -f "$manifestsDir\05-services.yaml"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to create Services" -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Host "[7/7] Waiting for pods to be ready..." -ForegroundColor Green
Write-Host "This may take 2-3 minutes..." -ForegroundColor Yellow
Write-Host ""

Start-Sleep -Seconds 10

Write-Host "Checking pod status..." -ForegroundColor Cyan
kubectl get pods -n opensearch
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Access URLs:" -ForegroundColor Yellow
Write-Host "  OpenSearch API: http://localhost:30920" -ForegroundColor White
Write-Host "  OpenSearch Dashboards: http://localhost:30561" -ForegroundColor White
Write-Host ""
Write-Host "Useful Commands:" -ForegroundColor Yellow
Write-Host "  Check status: kubectl get all -n opensearch" -ForegroundColor White
Write-Host "  View logs: kubectl logs -n opensearch -l app=opensearch" -ForegroundColor White
Write-Host "  Dashboard logs: kubectl logs -n opensearch -l app=opensearch-dashboards" -ForegroundColor White
Write-Host ""
Write-Host "Note: It may take 2-3 minutes for all services to be fully ready" -ForegroundColor Yellow
Write-Host ""

# Wait for user input
Read-Host "Press Enter to continue"

# Made with Bob
