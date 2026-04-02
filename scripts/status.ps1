# OpenSearch Kubernetes Status Check Script for Windows (PowerShell)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OpenSearch K8s Status Check" -ForegroundColor Cyan
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
    exit 1
}

Write-Host ""
Write-Host "=== Namespace Status ===" -ForegroundColor Yellow
try {
    kubectl get namespace opensearch 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Namespace 'opensearch' does not exist. Run deploy script first." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Namespace 'opensearch' does not exist. Run deploy script first." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Pods Status ===" -ForegroundColor Yellow
kubectl get pods -n opensearch -o wide

Write-Host ""
Write-Host "=== Services Status ===" -ForegroundColor Yellow
kubectl get svc -n opensearch

Write-Host ""
Write-Host "=== PersistentVolumeClaims Status ===" -ForegroundColor Yellow
kubectl get pvc -n opensearch

Write-Host ""
Write-Host "=== Resource Usage ===" -ForegroundColor Yellow
try {
    kubectl top pods -n opensearch 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Note: Metrics server not available. Install metrics-server for resource usage." -ForegroundColor Gray
    }
} catch {
    Write-Host "Note: Metrics server not available. Install metrics-server for resource usage." -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== Recent Events ===" -ForegroundColor Yellow
kubectl get events -n opensearch --sort-by='.lastTimestamp' | Select-Object -Last 10

Write-Host ""
Write-Host "=== Access URLs ===" -ForegroundColor Yellow
Write-Host "OpenSearch API: http://localhost:30920" -ForegroundColor White
Write-Host "OpenSearch Dashboards: http://localhost:30561" -ForegroundColor White

Write-Host ""
Write-Host "=== Quick Health Check ===" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:30920/_cluster/health" -UseBasicParsing -TimeoutSec 5 2>$null
    Write-Host "OpenSearch Status:" -ForegroundColor Green
    Write-Host $response.Content
} catch {
    Write-Host "OpenSearch API not responding yet. Pods may still be starting..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Useful Commands ===" -ForegroundColor Yellow
Write-Host "View logs: kubectl logs -n opensearch -l app=opensearch -f" -ForegroundColor Gray
Write-Host "Dashboard logs: kubectl logs -n opensearch -l app=opensearch-dashboards -f" -ForegroundColor Gray
Write-Host "Describe pod: kubectl describe pod -n opensearch opensearch-0" -ForegroundColor Gray
Write-Host ""

# Wait for user input
Read-Host "Press Enter to continue"

# Made with Bob
