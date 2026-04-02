# E-Commerce Data Loader for OpenSearch (PowerShell)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OpenSearch E-Commerce Data Loader" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Python is installed
Write-Host "[1/3] Checking Python installation..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Python not found"
    }
    Write-Host $pythonVersion -ForegroundColor Green
} catch {
    Write-Host "ERROR: Python is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Python 3.7+ from https://www.python.org/" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# Check if requests library is installed
Write-Host "[2/3] Checking required Python packages..." -ForegroundColor Yellow
try {
    python -c "import requests" 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Installing required packages..." -ForegroundColor Yellow
        pip install -r requirements.txt
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to install packages"
        }
        Write-Host "Packages installed successfully" -ForegroundColor Green
    } else {
        Write-Host "Required packages already installed" -ForegroundColor Green
    }
} catch {
    Write-Host "ERROR: Failed to install required packages" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Check if OpenSearch is accessible
Write-Host "[3/3] Checking OpenSearch connection..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:30920" -UseBasicParsing -TimeoutSec 5 2>$null
    Write-Host "OpenSearch is accessible" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Cannot connect to OpenSearch at http://localhost:30920" -ForegroundColor Red
    Write-Host "Please ensure OpenSearch is running: kubectl get pods -n opensearch" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Loading E-Commerce Data" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Run the data loader
python load_ecommerce_data.py

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Data Loading Successful!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Open OpenSearch Dashboards: http://localhost:30561" -ForegroundColor White
    Write-Host "2. Go to Management > Stack Management > Index Patterns" -ForegroundColor White
    Write-Host "3. Create index patterns: products*, customers*, orders*" -ForegroundColor White
    Write-Host "4. Go to Discover to explore your data" -ForegroundColor White
    Write-Host ""
    
    # Offer to open Dashboards
    $openDashboards = Read-Host "Would you like to open OpenSearch Dashboards now? (y/n)"
    if ($openDashboards -eq "y" -or $openDashboards -eq "Y") {
        Start-Process "http://localhost:30561"
    }
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Data Loading Failed!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Please check the error messages above" -ForegroundColor Yellow
    Write-Host ""
}

# Wait for user input
Read-Host "Press Enter to continue"

# Made with Bob
