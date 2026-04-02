# E-Commerce Sample Data Loader for OpenSearch

This directory contains scripts to load sample e-commerce data into OpenSearch for testing and demonstration purposes.

## 📋 Overview

The data loader generates and loads three types of data:
- **50 Products**: Electronics, clothing, books, and more with prices, descriptions, and inventory
- **100 Customers**: Contact information, addresses, and loyalty data
- **200 Orders**: Linking customers and products with order history

## 🎯 Features

- **Realistic Data**: Generated with proper relationships between entities
- **Proper Mappings**: Optimized index mappings for each data type
- **Bulk Loading**: Efficient bulk API usage for fast data loading
- **Verification**: Built-in data verification and sample queries
- **Windows Native**: Batch and PowerShell wrapper scripts

## 📦 Prerequisites

1. **Python 3.7+** installed and in PATH
2. **OpenSearch** running on Kubernetes
3. **Network access** to http://localhost:30920

### Check Prerequisites

```powershell
# Check Python
python --version

# Check OpenSearch
kubectl get pods -n opensearch

# Test OpenSearch access
curl http://localhost:30920
```

## 🚀 Quick Start

### Option 1: Using PowerShell (Recommended)

```powershell
cd opensearch-k8s-windows\data-loader
.\load_data.ps1
```

### Option 2: Using Batch Script

```batch
cd opensearch-k8s-windows\data-loader
load_data.bat
```

### Option 3: Direct Python Execution

```powershell
# Install dependencies
pip install -r requirements.txt

# Run loader
python load_ecommerce_data.py
```

## 📊 Data Structure

### Products Index

**Index Name**: `products`

**Sample Document**:
```json
{
  "id": "PROD0001",
  "name": "Brand5 Laptop",
  "category": "Electronics",
  "description": "High-quality laptop from Brand5. Perfect for everyday use.",
  "price": 899.99,
  "stock_quantity": 45,
  "rating": 4.5,
  "reviews_count": 234,
  "brand": "Brand5",
  "created_at": "2025-06-15T10:30:00",
  "updated_at": "2026-04-01T12:00:00",
  "tags": ["electronics", "laptop", "brand5"],
  "is_active": true
}
```

**Mapping Highlights**:
- `name`: Text with keyword sub-field for exact matching
- `category`, `brand`: Keywords for aggregations
- `price`: Float for range queries
- `rating`: Float for sorting
- `tags`: Keyword array for filtering

### Customers Index

**Index Name**: `customers`

**Sample Document**:
```json
{
  "id": "CUST0001",
  "first_name": "James",
  "last_name": "Smith",
  "email": "james.smith1@example.com",
  "phone": "+1-555-123-4567",
  "address": {
    "street": "123 Main St",
    "city": "New York",
    "state": "NY",
    "zip_code": "10001",
    "country": "USA"
  },
  "registration_date": "2024-03-15T08:00:00",
  "last_login": "2026-03-25T14:30:00",
  "total_orders": 15,
  "total_spent": 2450.75,
  "loyalty_points": 2450,
  "is_premium": true
}
```

**Mapping Highlights**:
- `email`: Keyword for exact matching
- `address`: Nested object with structured fields
- `total_spent`: Float for analytics
- `is_premium`: Boolean for filtering

### Orders Index

**Index Name**: `orders`

**Sample Document**:
```json
{
  "id": "ORD00001",
  "customer_id": "CUST0042",
  "order_date": "2026-02-15T10:30:00",
  "status": "delivered",
  "items": [
    {
      "product_id": "PROD0015",
      "product_name": "Brand3 Smartphone",
      "quantity": 1,
      "unit_price": 599.99,
      "subtotal": 599.99
    }
  ],
  "total_amount": 599.99,
  "shipping_address": {
    "street": "456 Oak Ave",
    "city": "Los Angeles",
    "state": "CA",
    "zip_code": "90001",
    "country": "USA"
  },
  "payment_method": "credit_card",
  "shipping_method": "express",
  "tracking_number": "TRK123456789",
  "notes": "Leave at door"
}
```

**Mapping Highlights**:
- `items`: Nested array for order line items
- `order_date`: Date for time-based queries
- `status`: Keyword for filtering
- `total_amount`: Float for analytics

## 🔍 Data Verification

After loading data, verify it was loaded correctly:

```powershell
python verify_data.py
```

This will:
- Check connection to OpenSearch
- Verify all three indices exist
- Display document counts and sizes
- Show sample documents
- Run example queries

## 📈 Using the Data in OpenSearch Dashboards

### 1. Create Index Patterns

1. Open OpenSearch Dashboards: http://localhost:30561
2. Go to **Management** > **Stack Management** > **Index Patterns**
3. Create three index patterns:
   - `products*`
   - `customers*`
   - `orders*`

### 2. Explore Data

Go to **Discover** and select each index pattern to explore the data.

### 3. Sample Queries

#### Find Electronics Products
```json
GET /products/_search
{
  "query": {
    "term": {
      "category": "Electronics"
    }
  }
}
```

#### Find High-Value Orders
```json
GET /orders/_search
{
  "query": {
    "range": {
      "total_amount": {
        "gte": 500
      }
    }
  },
  "sort": [
    {
      "total_amount": {
        "order": "desc"
      }
    }
  ]
}
```

#### Find Premium Customers
```json
GET /customers/_search
{
  "query": {
    "term": {
      "is_premium": true
    }
  }
}
```

#### Aggregate Orders by Status
```json
GET /orders/_search
{
  "size": 0,
  "aggs": {
    "by_status": {
      "terms": {
        "field": "status"
      }
    }
  }
}
```

#### Products by Category with Average Price
```json
GET /products/_search
{
  "size": 0,
  "aggs": {
    "by_category": {
      "terms": {
        "field": "category"
      },
      "aggs": {
        "avg_price": {
          "avg": {
            "field": "price"
          }
        }
      }
    }
  }
}
```

## 🎨 Creating Visualizations

### Example: Sales by Category

1. Go to **Visualize** > **Create visualization**
2. Select **Pie chart**
3. Choose `orders*` index pattern
4. Metrics: Sum of `total_amount`
5. Buckets: Terms aggregation on `items.product_name.keyword`

### Example: Customer Distribution by City

1. Create **Bar chart**
2. Choose `customers*` index pattern
3. Metrics: Count
4. Buckets: Terms on `address.city`

### Example: Order Timeline

1. Create **Line chart**
2. Choose `orders*` index pattern
3. Metrics: Count
4. Buckets: Date histogram on `order_date`

## 🔄 Reloading Data

To reload data (this will delete existing data):

```powershell
# The loader automatically deletes and recreates indices
.\load_data.ps1
```

## 🧹 Cleaning Up Data

To remove all loaded data:

```powershell
# Delete indices
curl -X DELETE http://localhost:30920/products
curl -X DELETE http://localhost:30920/customers
curl -X DELETE http://localhost:30920/orders
```

Or using PowerShell:

```powershell
Invoke-WebRequest -Method Delete -Uri "http://localhost:30920/products"
Invoke-WebRequest -Method Delete -Uri "http://localhost:30920/customers"
Invoke-WebRequest -Method Delete -Uri "http://localhost:30920/orders"
```

## 📝 Customization

### Modify Data Quantities

Edit `load_ecommerce_data.py`:

```python
# Generate data
products = generate_products(100)  # Change from 50 to 100
customers = generate_customers(200)  # Change from 100 to 200
orders = generate_orders(500, products, customers)  # Change from 200 to 500
```

### Add Custom Categories

Edit the `CATEGORIES` list:

```python
CATEGORIES = [
    "Electronics", "Clothing", "Books",
    "Custom Category 1", "Custom Category 2"
]
```

### Modify Product Names

Edit the `PRODUCT_NAMES` dictionary:

```python
PRODUCT_NAMES = {
    "Electronics": ["Laptop", "Smartphone", "Your Product"],
    # ... add more
}
```

## 🐛 Troubleshooting

### Python Not Found

**Error**: `python: command not found`

**Solution**: Install Python from https://www.python.org/ and ensure it's in PATH

### Cannot Connect to OpenSearch

**Error**: `Cannot connect to OpenSearch at http://localhost:30920`

**Solution**:
```powershell
# Check if OpenSearch is running
kubectl get pods -n opensearch

# Check if pod is ready
kubectl describe pod opensearch-0 -n opensearch

# Check service
kubectl get svc -n opensearch
```

### Import Error: requests

**Error**: `ModuleNotFoundError: No module named 'requests'`

**Solution**:
```powershell
pip install requests
# or
pip install -r requirements.txt
```

### Index Already Exists

The loader automatically deletes existing indices before creating new ones. If you see errors, manually delete:

```powershell
curl -X DELETE http://localhost:30920/products
curl -X DELETE http://localhost:30920/customers
curl -X DELETE http://localhost:30920/orders
```

## 📚 Additional Resources

- [OpenSearch Documentation](https://opensearch.org/docs/latest/)
- [OpenSearch Python Client](https://opensearch.org/docs/latest/clients/python/)
- [OpenSearch Query DSL](https://opensearch.org/docs/latest/query-dsl/)
- [OpenSearch Dashboards](https://opensearch.org/docs/latest/dashboards/)

## 🤝 Contributing

Feel free to modify the data generation logic to suit your needs. The code is well-commented and easy to extend.

---

**Version**: 1.0  
**Last Updated**: April 2026  
**Compatible with**: OpenSearch 2.11+