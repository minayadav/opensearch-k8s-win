# OpenSearch Kubernetes Cleanup Script for Windows (PowerShell)
# This script removes all OpenSearch resources from the cluster

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OpenSearch K8s Cleanup for Windows" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "WARNING: This will delete all OpenSearch resources and data!" -ForegroundColor Red
Write-Host ""
$confirm = Read-Host "Are you sure you want to continue? (yes/no)"

if ($confirm -ne "yes") {
    Write-Host "Cleanup cancelled." -ForegroundColor Yellow
    exit 0
}

# Get the script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$manifestsDir = Join-Path (Split-Path -Parent $scriptDir) "k8s-manifests"

Write-Host ""
Write-Host "[1/6] Deleting Services..." -ForegroundColor Green
kubectl delete -f "$manifestsDir\05-services.yaml" --ignore-not-found=true
Write-Host ""

Write-Host "[2/6] Deleting OpenSearch Dashboards Deployment..." -ForegroundColor Green
kubectl delete -f "$manifestsDir\04-deployment-dashboards.yaml" --ignore-not-found=true
Write-Host ""

Write-Host "[3/6] Deleting OpenSearch StatefulSet..." -ForegroundColor Green
kubectl delete -f "$manifestsDir\03-statefulset.yaml" --ignore-not-found=true
Write-Host ""

Write-Host "[4/6] Deleting PersistentVolumeClaim..." -ForegroundColor Green
kubectl delete -f "$manifestsDir\02-pvc.yaml" --ignore-not-found=true
Write-Host ""

Write-Host "[5/6] Deleting ConfigMaps..." -ForegroundColor Green
kubectl delete -f "$manifestsDir\01-configmap.yaml" --ignore-not-found=true
Write-Host ""

Write-Host "[6/6] Deleting Namespace..." -ForegroundColor Green
kubectl delete -f "$manifestsDir\00-namespace.yaml" --ignore-not-found=true
Write-Host ""

Write-Host "Waiting for resources to be fully deleted..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Cleanup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "All OpenSearch resources have been removed." -ForegroundColor White
Write-Host ""

# Wait for user input
Read-Host "Press Enter to continue"

# Made with Bob
