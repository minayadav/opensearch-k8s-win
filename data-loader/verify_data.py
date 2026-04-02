#!/usr/bin/env python3
"""
Data Verification Script for OpenSearch E-Commerce Data
Verifies that data was loaded correctly and provides statistics
"""

import requests
import json
from typing import Dict

OPENSEARCH_URL = "http://localhost:30920"
INDICES = ["products", "customers", "orders"]


def print_header(text: str):
    """Print formatted header"""
    print("\n" + "=" * 60)
    print(text)
    print("=" * 60)


def check_connection() -> bool:
    """Check if OpenSearch is accessible"""
    try:
        response = requests.get(OPENSEARCH_URL, timeout=5)
        if response.status_code == 200:
            info = response.json()
            print(f"✓ Connected to OpenSearch {info['version']['number']}")
            print(f"  Cluster: {info['cluster_name']}")
            return True
        return False
    except Exception as e:
        print(f"✗ Connection failed: {e}")
        return False


def get_index_stats(index_name: str) -> Dict:
    """Get statistics for an index"""
    try:
        # Get document count
        count_url = f"{OPENSEARCH_URL}/{index_name}/_count"
        count_response = requests.get(count_url)
        doc_count = count_response.json().get("count", 0) if count_response.status_code == 200 else 0
        
        # Get index size
        stats_url = f"{OPENSEARCH_URL}/{index_name}/_stats"
        stats_response = requests.get(stats_url)
        
        if stats_response.status_code == 200:
            stats = stats_response.json()
            index_stats = stats["indices"][index_name]["total"]
            size_bytes = index_stats["store"]["size_in_bytes"]
            size_mb = round(size_bytes / (1024 * 1024), 2)
            
            return {
                "exists": True,
                "doc_count": doc_count,
                "size_mb": size_mb,
                "shards": index_stats["docs"]["count"]
            }
        else:
            return {"exists": False}
    except Exception as e:
        return {"exists": False, "error": str(e)}


def get_sample_documents(index_name: str, size: int = 3) -> list:
    """Get sample documents from an index"""
    try:
        search_url = f"{OPENSEARCH_URL}/{index_name}/_search"
        query = {
            "size": size,
            "query": {"match_all": {}}
        }
        response = requests.post(search_url, json=query, headers={"Content-Type": "application/json"})
        
        if response.status_code == 200:
            hits = response.json()["hits"]["hits"]
            return [hit["_source"] for hit in hits]
        return []
    except Exception as e:
        print(f"  Error getting samples: {e}")
        return []


def verify_products():
    """Verify products index"""
    print("\n📦 Products Index")
    print("-" * 60)
    
    stats = get_index_stats("products")
    if not stats.get("exists"):
        print("✗ Index does not exist")
        return False
    
    print(f"✓ Documents: {stats['doc_count']}")
    print(f"✓ Size: {stats['size_mb']} MB")
    
    # Get sample
    samples = get_sample_documents("products", 2)
    if samples:
        print(f"\nSample Products:")
        for i, product in enumerate(samples, 1):
            print(f"  {i}. {product.get('name')} - ${product.get('price')}")
            print(f"     Category: {product.get('category')}, Stock: {product.get('stock_quantity')}")
    
    return True


def verify_customers():
    """Verify customers index"""
    print("\n👥 Customers Index")
    print("-" * 60)
    
    stats = get_index_stats("customers")
    if not stats.get("exists"):
        print("✗ Index does not exist")
        return False
    
    print(f"✓ Documents: {stats['doc_count']}")
    print(f"✓ Size: {stats['size_mb']} MB")
    
    # Get sample
    samples = get_sample_documents("customers", 2)
    if samples:
        print(f"\nSample Customers:")
        for i, customer in enumerate(samples, 1):
            print(f"  {i}. {customer.get('first_name')} {customer.get('last_name')}")
            print(f"     Email: {customer.get('email')}, City: {customer.get('address', {}).get('city')}")
    
    return True


def verify_orders():
    """Verify orders index"""
    print("\n🛒 Orders Index")
    print("-" * 60)
    
    stats = get_index_stats("orders")
    if not stats.get("exists"):
        print("✗ Index does not exist")
        return False
    
    print(f"✓ Documents: {stats['doc_count']}")
    print(f"✓ Size: {stats['size_mb']} MB")
    
    # Get sample
    samples = get_sample_documents("orders", 2)
    if samples:
        print(f"\nSample Orders:")
        for i, order in enumerate(samples, 1):
            print(f"  {i}. Order {order.get('id')} - ${order.get('total_amount')}")
            print(f"     Status: {order.get('status')}, Items: {len(order.get('items', []))}")
    
    return True


def run_sample_queries():
    """Run sample queries to demonstrate functionality"""
    print_header("Sample Queries")
    
    # Query 1: Products by category
    print("\n1. Products in Electronics category:")
    try:
        query = {
            "size": 5,
            "query": {
                "term": {"category": "Electronics"}
            }
        }
        response = requests.post(
            f"{OPENSEARCH_URL}/products/_search",
            json=query,
            headers={"Content-Type": "application/json"}
        )
        if response.status_code == 200:
            hits = response.json()["hits"]["hits"]
            for hit in hits:
                product = hit["_source"]
                print(f"   - {product['name']}: ${product['price']}")
    except Exception as e:
        print(f"   Error: {e}")
    
    # Query 2: High-value orders
    print("\n2. Orders over $500:")
    try:
        query = {
            "size": 5,
            "query": {
                "range": {"total_amount": {"gte": 500}}
            },
            "sort": [{"total_amount": {"order": "desc"}}]
        }
        response = requests.post(
            f"{OPENSEARCH_URL}/orders/_search",
            json=query,
            headers={"Content-Type": "application/json"}
        )
        if response.status_code == 200:
            hits = response.json()["hits"]["hits"]
            for hit in hits:
                order = hit["_source"]
                print(f"   - Order {order['id']}: ${order['total_amount']} ({order['status']})")
    except Exception as e:
        print(f"   Error: {e}")
    
    # Query 3: Premium customers
    print("\n3. Premium customers:")
    try:
        query = {
            "size": 5,
            "query": {
                "term": {"is_premium": True}
            }
        }
        response = requests.post(
            f"{OPENSEARCH_URL}/customers/_search",
            json=query,
            headers={"Content-Type": "application/json"}
        )
        if response.status_code == 200:
            hits = response.json()["hits"]["hits"]
            for hit in hits:
                customer = hit["_source"]
                print(f"   - {customer['first_name']} {customer['last_name']}: {customer['loyalty_points']} points")
    except Exception as e:
        print(f"   Error: {e}")


def main():
    print_header("OpenSearch Data Verification")
    
    # Check connection
    print("\nChecking connection...")
    if not check_connection():
        print("\n✗ Cannot connect to OpenSearch")
        print("  Make sure OpenSearch is running: kubectl get pods -n opensearch")
        return
    
    # Verify each index
    print_header("Index Verification")
    
    products_ok = verify_products()
    customers_ok = verify_customers()
    orders_ok = verify_orders()
    
    # Summary
    print_header("Verification Summary")
    
    total_indices = 3
    verified_indices = sum([products_ok, customers_ok, orders_ok])
    
    if verified_indices == total_indices:
        print(f"\n✓ All {total_indices} indices verified successfully!")
    else:
        print(f"\n⚠ {verified_indices}/{total_indices} indices verified")
    
    # Run sample queries
    if verified_indices > 0:
        run_sample_queries()
    
    # Next steps
    print_header("Next Steps")
    print("\n1. Open OpenSearch Dashboards: http://localhost:30561")
    print("2. Create index patterns in Stack Management:")
    print("   - products*")
    print("   - customers*")
    print("   - orders*")
    print("3. Explore data in Discover")
    print("4. Create visualizations and dashboards")
    print()


if __name__ == "__main__":
    main()

# Made with Bob
