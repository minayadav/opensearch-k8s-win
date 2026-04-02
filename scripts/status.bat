@echo off
REM OpenSearch Kubernetes Status Check Script for Windows

echo ========================================
echo OpenSearch K8s Status Check
echo ========================================
echo.

echo Checking if kubectl is available...
kubectl version --client >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: kubectl is not installed or not in PATH
    exit /b 1
)

echo.
echo === Namespace Status ===
kubectl get namespace opensearch 2>nul
if %errorlevel% neq 0 (
    echo Namespace 'opensearch' does not exist. Run deploy script first.
    exit /b 1
)

echo.
echo === Pods Status ===
kubectl get pods -n opensearch -o wide

echo.
echo === Services Status ===
kubectl get svc -n opensearch

echo.
echo === PersistentVolumeClaims Status ===
kubectl get pvc -n opensearch

echo.
echo === Resource Usage ===
kubectl top pods -n opensearch 2>nul
if %errorlevel% neq 0 (
    echo Note: Metrics server not available. Install metrics-server for resource usage.
)

echo.
echo === Recent Events ===
kubectl get events -n opensearch --sort-by='.lastTimestamp' | findstr /V "Normal" | more

echo.
echo === Access URLs ===
echo OpenSearch API: http://localhost:30920
echo OpenSearch Dashboards: http://localhost:30561
echo.
echo === Quick Health Check ===
curl -s http://localhost:30920/_cluster/health 2>nul
if %errorlevel% neq 0 (
    echo OpenSearch API not responding yet. Pods may still be starting...
)
echo.

pause

@REM Made with Bob
