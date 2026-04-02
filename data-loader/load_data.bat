@echo off
REM E-Commerce Data Loader for OpenSearch (Windows Batch)

echo ========================================
echo OpenSearch E-Commerce Data Loader
echo ========================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.7+ from https://www.python.org/
    exit /b 1
)

echo [1/3] Checking Python installation...
python --version
echo.

REM Check if requests library is installed
python -c "import requests" >nul 2>&1
if %errorlevel% neq 0 (
    echo [2/3] Installing required Python packages...
    pip install -r requirements.txt
    if %errorlevel% neq 0 (
        echo ERROR: Failed to install required packages
        exit /b 1
    )
) else (
    echo [2/3] Required packages already installed
)
echo.

REM Check if OpenSearch is accessible
echo [3/3] Checking OpenSearch connection...
curl -s http://localhost:30920 >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Cannot connect to OpenSearch at http://localhost:30920
    echo Please ensure OpenSearch is running: kubectl get pods -n opensearch
    exit /b 1
)
echo OpenSearch is accessible
echo.

echo ========================================
echo Loading E-Commerce Data
echo ========================================
echo.

REM Run the data loader
python load_ecommerce_data.py

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo Data Loading Successful!
    echo ========================================
    echo.
    echo Next Steps:
    echo 1. Open OpenSearch Dashboards: http://localhost:30561
    echo 2. Go to Management ^> Stack Management ^> Index Patterns
    echo 3. Create index patterns: products*, customers*, orders*
    echo 4. Go to Discover to explore your data
    echo.
) else (
    echo.
    echo ========================================
    echo Data Loading Failed!
    echo ========================================
    echo Please check the error messages above
    echo.
)

pause

@REM Made with Bob
