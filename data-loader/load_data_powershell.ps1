# E-Commerce Data Loader for OpenSearch (Pure PowerShell - No Python Required)
# This script loads sample data directly using REST API calls

$OPENSEARCH_URL = "http://localhost:30920"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OpenSearch E-Commerce Data Loader" -ForegroundColor Cyan
Write-Host "(PowerShell Native - No Python Required)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check OpenSearch connection
Write-Host "Checking OpenSearch connection..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri $OPENSEARCH_URL -Method Get -TimeoutSec 5
    Write-Host "✓ Connected to OpenSearch $($response.version.number)" -ForegroundColor Green
    Write-Host "  Cluster: $($response.cluster_name)" -ForegroundColor Gray
} catch {
    Write-Host "✗ Cannot connect to OpenSearch at $OPENSEARCH_URL" -ForegroundColor Red
    Write-Host "  Please ensure OpenSearch is running: kubectl get pods -n opensearch" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# Function to create index with mapping
function Create-Index {
    param($IndexName, $Mapping)
    
    # Delete if exists
    try {
        Invoke-RestMethod -Uri "$OPENSEARCH_URL/$IndexName" -Method Delete -ErrorAction SilentlyContinue | Out-Null
    } catch {}
    
    # Create new index
    try {
        $body = $Mapping | ConvertTo-Json -Depth 10
        Invoke-RestMethod -Uri "$OPENSEARCH_URL/$IndexName" -Method Put -Body $body -ContentType "application/json" | Out-Null
        Write-Host "✓ Created index: $IndexName" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "✗ Failed to create index: $IndexName" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Gray
        return $false
    }
}

# Function to bulk index documents
function Bulk-Index {
    param($IndexName, $Documents)
    
    $bulkBody = ""
    foreach ($doc in $Documents) {
        $action = @{ index = @{ _index = $IndexName; _id = $doc.id } } | ConvertTo-Json -Compress
        $docJson = $doc | ConvertTo-Json -Compress -Depth 10
        $bulkBody += "$action`n$docJson`n"
    }
    
    try {
        $response = Invoke-RestMethod -Uri "$OPENSEARCH_URL/_bulk" -Method Post -Body $bulkBody -ContentType "application/x-ndjson"
        if (-not $response.errors) {
            Write-Host "✓ Indexed $($Documents.Count) documents to $IndexName" -ForegroundColor Green
            return $true
        } else {
            Write-Host "⚠ Some documents failed to index in $IndexName" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "✗ Bulk index failed for $IndexName" -ForegroundColor Red
        return $false
    }
}

# Create Products Index
Write-Host "Creating indices..." -ForegroundColor Yellow
$productsMapping = @{
    mappings = @{
        properties = @{
            id = @{ type = "keyword" }
            name = @{ type = "text"; fields = @{ keyword = @{ type = "keyword" } } }
            category = @{ type = "keyword" }
            description = @{ type = "text" }
            price = @{ type = "float" }
            stock_quantity = @{ type = "integer" }
            rating = @{ type = "float" }
            brand = @{ type = "keyword" }
            created_at = @{ type = "date" }
            tags = @{ type = "keyword" }
            is_active = @{ type = "boolean" }
        }
    }
}

$customersMapping = @{
    mappings = @{
        properties = @{
            id = @{ type = "keyword" }
            first_name = @{ type = "text"; fields = @{ keyword = @{ type = "keyword" } } }
            last_name = @{ type = "text"; fields = @{ keyword = @{ type = "keyword" } } }
            email = @{ type = "keyword" }
            phone = @{ type = "keyword" }
            address = @{
                properties = @{
                    street = @{ type = "text" }
                    city = @{ type = "keyword" }
                    state = @{ type = "keyword" }
                    zip_code = @{ type = "keyword" }
                    country = @{ type = "keyword" }
                }
            }
            registration_date = @{ type = "date" }
            total_orders = @{ type = "integer" }
            total_spent = @{ type = "float" }
            loyalty_points = @{ type = "integer" }
            is_premium = @{ type = "boolean" }
        }
    }
}

$ordersMapping = @{
    mappings = @{
        properties = @{
            id = @{ type = "keyword" }
            customer_id = @{ type = "keyword" }
            order_date = @{ type = "date" }
            status = @{ type = "keyword" }
            items = @{
                type = "nested"
                properties = @{
                    product_id = @{ type = "keyword" }
                    product_name = @{ type = "text" }
                    quantity = @{ type = "integer" }
                    unit_price = @{ type = "float" }
                    subtotal = @{ type = "float" }
                }
            }
            total_amount = @{ type = "float" }
            payment_method = @{ type = "keyword" }
            shipping_method = @{ type = "keyword" }
        }
    }
}

Create-Index -IndexName "products" -Mapping $productsMapping | Out-Null
Create-Index -IndexName "customers" -Mapping $customersMapping | Out-Null
Create-Index -IndexName "orders" -Mapping $ordersMapping | Out-Null
Write-Host ""

# Generate sample products
Write-Host "Generating sample data..." -ForegroundColor Yellow
$categories = @("Electronics", "Clothing", "Books", "Home and Garden")
$brands = @("Brand1", "Brand2", "Brand3", "Brand4", "Brand5")
$products = @()

for ($i = 1; $i -le 50; $i++) {
    $category = $categories | Get-Random
    $brand = $brands | Get-Random
    $products += @{
        id = "PROD{0:D4}" -f $i
        name = "$brand Product $i"
        category = $category
        description = "High-quality product from $brand"
        price = [math]::Round((Get-Random -Minimum 10 -Maximum 1000) + (Get-Random) , 2)
        stock_quantity = Get-Random -Minimum 0 -Maximum 500
        rating = [math]::Round((Get-Random -Minimum 3.0 -Maximum 5.0), 1)
        brand = $brand
        created_at = (Get-Date).AddDays(-(Get-Random -Minimum 1 -Maximum 365)).ToString("yyyy-MM-ddTHH:mm:ss")
        tags = @($category.ToLower(), $brand.ToLower())
        is_active = $true
    }
}
Write-Host "✓ Generated $($products.Count) products" -ForegroundColor Green

# Generate sample customers
$firstNames = @("James", "Mary", "John", "Patricia", "Robert", "Jennifer", "Michael", "Linda")
$lastNames = @("Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis")
$cities = @("New York", "Los Angeles", "Chicago", "Houston", "Phoenix")
$states = @("NY", "CA", "IL", "TX", "AZ")
$customers = @()

for ($i = 1; $i -le 100; $i++) {
    $firstName = $firstNames | Get-Random
    $lastName = $lastNames | Get-Random
    $customers += @{
        id = "CUST{0:D4}" -f $i
        first_name = $firstName
        last_name = $lastName
        email = "$($firstName.ToLower()).$($lastName.ToLower())$i@example.com"
        phone = "+1-{0:D3}-{1:D3}-{2:D4}" -f (Get-Random -Minimum 200 -Maximum 999), (Get-Random -Minimum 100 -Maximum 999), (Get-Random -Minimum 1000 -Maximum 9999)
        address = @{
            street = "{0} Main St" -f (Get-Random -Minimum 100 -Maximum 9999)
            city = $cities | Get-Random
            state = $states | Get-Random
            zip_code = "{0:D5}" -f (Get-Random -Minimum 10000 -Maximum 99999)
            country = "USA"
        }
        registration_date = (Get-Date).AddDays(-(Get-Random -Minimum 1 -Maximum 730)).ToString("yyyy-MM-ddTHH:mm:ss")
        total_orders = Get-Random -Minimum 0 -Maximum 50
        total_spent = [math]::Round((Get-Random -Minimum 0 -Maximum 5000) + (Get-Random), 2)
        loyalty_points = Get-Random -Minimum 0 -Maximum 10000
        is_premium = (Get-Random -Minimum 0 -Maximum 2) -eq 1
    }
}
Write-Host "✓ Generated $($customers.Count) customers" -ForegroundColor Green

# Generate sample orders
$statuses = @("pending", "processing", "shipped", "delivered", "cancelled")
$paymentMethods = @("credit_card", "debit_card", "paypal")
$shippingMethods = @("standard", "express", "overnight")
$orders = @()

for ($i = 1; $i -le 200; $i++) {
    $customer = $customers | Get-Random
    $numItems = Get-Random -Minimum 1 -Maximum 4
    $items = @()
    $totalAmount = 0
    
    for ($j = 0; $j -lt $numItems; $j++) {
        $product = $products | Get-Random
        $quantity = Get-Random -Minimum 1 -Maximum 3
        $subtotal = [math]::Round($product.price * $quantity, 2)
        $totalAmount += $subtotal
        
        $items += @{
            product_id = $product.id
            product_name = $product.name
            quantity = $quantity
            unit_price = $product.price
            subtotal = $subtotal
        }
    }
    
    $orders += @{
        id = "ORD{0:D5}" -f $i
        customer_id = $customer.id
        order_date = (Get-Date).AddDays(-(Get-Random -Minimum 0 -Maximum 180)).ToString("yyyy-MM-ddTHH:mm:ss")
        status = $statuses | Get-Random
        items = $items
        total_amount = [math]::Round($totalAmount, 2)
        payment_method = $paymentMethods | Get-Random
        shipping_method = $shippingMethods | Get-Random
    }
}
Write-Host "✓ Generated $($orders.Count) orders" -ForegroundColor Green
Write-Host ""

# Load data
Write-Host "Loading data into OpenSearch..." -ForegroundColor Yellow
Bulk-Index -IndexName "products" -Documents $products
Bulk-Index -IndexName "customers" -Documents $customers
Bulk-Index -IndexName "orders" -Documents $orders
Write-Host ""

# Verify data
Write-Host "Verifying data..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

$productsCount = (Invoke-RestMethod -Uri "$OPENSEARCH_URL/products/_count").count
$customersCount = (Invoke-RestMethod -Uri "$OPENSEARCH_URL/customers/_count").count
$ordersCount = (Invoke-RestMethod -Uri "$OPENSEARCH_URL/orders/_count").count

Write-Host "✓ Products index: $productsCount documents" -ForegroundColor Green
Write-Host "✓ Customers index: $customersCount documents" -ForegroundColor Green
Write-Host "✓ Orders index: $ordersCount documents" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✓ Data Loading Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Open OpenSearch Dashboards: http://localhost:30561" -ForegroundColor White
Write-Host "2. Go to Management > Stack Management > Index Patterns" -ForegroundColor White
Write-Host "3. Create index patterns: products*, customers*, orders*" -ForegroundColor White
Write-Host "4. Go to Discover to explore your data" -ForegroundColor White
Write-Host ""

$openDashboards = Read-Host "Would you like to open OpenSearch Dashboards now? (y/n)"
if ($openDashboards -eq "y" -or $openDashboards -eq "Y") {
    Start-Process "http://localhost:30561"
}
