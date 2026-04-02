# ArgoCD Installation Script for Windows
# This script installs and configures ArgoCD on your Kubernetes cluster

param(
    [string]$Namespace = "argocd",
    [switch]$SkipUI,
    [switch]$Help
)

if ($Help) {
    Write-Host @"
ArgoCD Installation Script

Usage: .\install-argocd.ps1 [-Namespace <namespace>] [-SkipUI] [-Help]

Parameters:
  -Namespace    Kubernetes namespace for ArgoCD (default: argocd)
  -SkipUI       Skip opening the ArgoCD UI
  -Help         Show this help message

Examples:
  .\install-argocd.ps1
  .\install-argocd.ps1 -Namespace my-argocd
  .\install-argocd.ps1 -SkipUI
"@
    exit 0
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "ArgoCD Installation for Kubernetes" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
Write-Host "[1/8] Checking prerequisites..." -ForegroundColor Yellow

# Check kubectl
try {
    $null = kubectl version --client 2>&1
    Write-Host "[OK] kubectl is installed" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] kubectl is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install kubectl: https://kubernetes.io/docs/tasks/tools/" -ForegroundColor Red
    exit 1
}

# Check cluster connection
try {
    $null = kubectl cluster-info 2>&1
    Write-Host "[OK] Connected to Kubernetes cluster" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Cannot connect to Kubernetes cluster" -ForegroundColor Red
    Write-Host "Please ensure your cluster is running and kubectl is configured" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Create namespace
Write-Host "[2/8] Creating namespace '$Namespace'..." -ForegroundColor Yellow
try {
    kubectl create namespace $Namespace 2>&1 | Out-Null
    Write-Host "[OK] Namespace created" -ForegroundColor Green
} catch {
    Write-Host "[INFO] Namespace already exists" -ForegroundColor Cyan
}

Write-Host ""

# Install ArgoCD
Write-Host "[3/8] Installing ArgoCD..." -ForegroundColor Yellow
Write-Host "This may take a few minutes..." -ForegroundColor Gray

try {
    kubectl apply -n $Namespace -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml | Out-Null
    Write-Host "[OK] ArgoCD manifests applied" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to install ArgoCD" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Wait for ArgoCD to be ready
Write-Host "[4/8] Waiting for ArgoCD pods to be ready..." -ForegroundColor Yellow
Write-Host "This may take 2-3 minutes..." -ForegroundColor Gray

$timeout = 300
$elapsed = 0
$interval = 5

while ($elapsed -lt $timeout) {
    $ready = kubectl get pods -n $Namespace -o json | ConvertFrom-Json
    $allReady = $true
    
    foreach ($pod in $ready.items) {
        $podReady = $false
        foreach ($condition in $pod.status.conditions) {
            if ($condition.type -eq "Ready" -and $condition.status -eq "True") {
                $podReady = $true
                break
            }
        }
        if (-not $podReady) {
            $allReady = $false
            break
        }
    }
    
    if ($allReady -and $ready.items.Count -gt 0) {
        Write-Host "[OK] All ArgoCD pods are ready" -ForegroundColor Green
        break
    }
    
    Write-Host "." -NoNewline -ForegroundColor Gray
    Start-Sleep -Seconds $interval
    $elapsed += $interval
}

if ($elapsed -ge $timeout) {
    Write-Host ""
    Write-Host "[WARNING] Timeout waiting for pods. Check status with: kubectl get pods -n $Namespace" -ForegroundColor Yellow
}

Write-Host ""

# Get admin password
Write-Host "[5/8] Retrieving ArgoCD admin password..." -ForegroundColor Yellow

try {
    $passwordBase64 = kubectl -n $Namespace get secret argocd-initial-admin-secret -o jsonpath="{.data.password}"
    $password = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($passwordBase64))
    
    Write-Host "[OK] Admin password retrieved" -ForegroundColor Green
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "ArgoCD Credentials" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "Username: admin" -ForegroundColor White
    Write-Host "Password: $password" -ForegroundColor White
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Save credentials to file
    $credFile = "argocd-credentials.txt"
    @"
ArgoCD Credentials
==================
URL: https://localhost:8080
Username: admin
Password: $password

Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@ | Out-File -FilePath $credFile -Encoding UTF8
    
    Write-Host "[INFO] Credentials saved to: $credFile" -ForegroundColor Cyan
    
} catch {
    Write-Host "[ERROR] Failed to retrieve admin password" -ForegroundColor Red
    Write-Host "You can retrieve it manually with:" -ForegroundColor Yellow
    Write-Host "kubectl -n $Namespace get secret argocd-initial-admin-secret -o jsonpath=`"{.data.password}`" | base64 -d" -ForegroundColor Yellow
}

Write-Host ""

# Patch ArgoCD server service (optional - for easier access)
Write-Host "[6/8] Configuring ArgoCD server service..." -ForegroundColor Yellow

try {
    kubectl patch svc argocd-server -n $Namespace -p '{\"spec\":{\"type\":\"LoadBalancer\"}}' 2>&1 | Out-Null
    Write-Host "[OK] Service configured as LoadBalancer" -ForegroundColor Green
} catch {
    Write-Host "[INFO] Service configuration skipped" -ForegroundColor Cyan
}

Write-Host ""

# Install ArgoCD CLI (optional)
Write-Host "[7/8] Checking ArgoCD CLI..." -ForegroundColor Yellow

$argoCLI = Get-Command argocd -ErrorAction SilentlyContinue
if ($argoCLI) {
    Write-Host "[OK] ArgoCD CLI is already installed" -ForegroundColor Green
} else {
    Write-Host "[INFO] ArgoCD CLI not found" -ForegroundColor Cyan
    Write-Host "To install ArgoCD CLI, visit: https://argo-cd.readthedocs.io/en/stable/cli_installation/" -ForegroundColor Cyan
    Write-Host "Or use Chocolatey: choco install argocd-cli" -ForegroundColor Cyan
}

Write-Host ""

# Start port-forward
Write-Host "[8/8] Setting up port-forward to ArgoCD UI..." -ForegroundColor Yellow

if (-not $SkipUI) {
    Write-Host "[INFO] Starting port-forward in background..." -ForegroundColor Cyan
    Write-Host "ArgoCD UI will be available at: https://localhost:8080" -ForegroundColor Cyan
    
    # Kill any existing port-forward
    Get-Process | Where-Object {$_.ProcessName -eq "kubectl" -and $_.CommandLine -like "*port-forward*argocd-server*"} | Stop-Process -Force -ErrorAction SilentlyContinue
    
    # Start new port-forward in background
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward svc/argocd-server -n $Namespace 8080:443" -WindowStyle Minimized
    
    Start-Sleep -Seconds 2
    Write-Host "[OK] Port-forward started" -ForegroundColor Green
    
    # Open browser
    Write-Host "[INFO] Opening ArgoCD UI in browser..." -ForegroundColor Cyan
    Start-Sleep -Seconds 2
    Start-Process "https://localhost:8080"
} else {
    Write-Host "[INFO] Skipping UI setup (use -SkipUI flag)" -ForegroundColor Cyan
    Write-Host "To access ArgoCD UI manually, run:" -ForegroundColor Yellow
    Write-Host "kubectl port-forward svc/argocd-server -n $Namespace 8080:443" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "ArgoCD Installation Complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Access ArgoCD UI at: https://localhost:8080" -ForegroundColor White
Write-Host "2. Login with username 'admin' and the password above" -ForegroundColor White
Write-Host "3. Deploy OpenSearch application:" -ForegroundColor White
Write-Host "   kubectl apply -f cicd/argocd/opensearch-application.yaml" -ForegroundColor Cyan
Write-Host ""
Write-Host "Useful Commands:" -ForegroundColor Yellow
Write-Host "- View ArgoCD pods: kubectl get pods -n $Namespace" -ForegroundColor White
Write-Host "- View applications: kubectl get applications -n $Namespace" -ForegroundColor White
Write-Host "- ArgoCD logs: kubectl logs -n $Namespace -l app.kubernetes.io/name=argocd-server" -ForegroundColor White
Write-Host ""
Write-Host "Documentation: https://argo-cd.readthedocs.io/" -ForegroundColor Cyan
Write-Host ""

# Made with Bob
