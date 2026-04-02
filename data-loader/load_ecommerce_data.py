#!/usr/bin/env python3
"""
E-Commerce Sample Data Loader for OpenSearch
Generates and loads sample products, customers, and orders data
"""

import json
import random
import requests
from datetime import datetime, timedelta
from typing import List, Dict
import sys

# OpenSearch connection settings
OPENSEARCH_URL = "http://localhost:30920"
PRODUCTS_INDEX = "products"
CUSTOMERS_INDEX = "customers"
ORDERS_INDEX = "orders"

# Sample data for generation
CATEGORIES = [
    "Electronics", "Clothing", "Books", "Home & Garden", 
    "Sports & Outdoors", "Toys & Games", "Health & Beauty", "Automotive"
]

PRODUCT_NAMES = {
    "Electronics": ["Laptop", "Smartphone", "Tablet", "Headphones", "Smart Watch", "Camera", "Speaker"],
    "Clothing": ["T-Shirt", "Jeans", "Dress", "Jacket", "Sneakers", "Hat", "Sweater"],
    "Books": ["Novel", "Cookbook", "Biography", "Science Fiction", "Mystery", "Self-Help", "History"],
    "Home & Garden": ["Lamp", "Cushion", "Plant Pot", "Rug", "Mirror", "Vase", "Clock"],
    "Sports & Outdoors": ["Yoga Mat", "Dumbbell", "Tent", "Bicycle", "Running Shoes", "Backpack", "Water Bottle"],
    "Toys & Games": ["Board Game", "Puzzle", "Action Figure", "Doll", "Building Blocks", "Card Game", "RC Car"],
    "Health & Beauty": ["Shampoo", "Face Cream", "Perfume", "Makeup Kit", "Hair Dryer", "Massage Oil", "Vitamins"],
    "Automotive": ["Car Cover", "Floor Mats", "Phone Mount", "Dash Cam", "Air Freshener", "Tool Kit", "Tire Gauge"]
}

FIRST_NAMES = [
    "James", "Mary", "John", "Patricia", "Robert", "Jennifer", "Michael", "Linda",
    "William", "Elizabeth", "David", "Barbara", "Richard", "Susan", "Joseph", "Jessica",
    "Thomas", "Sarah", "Charles", "Karen", "Christopher", "Nancy", "Daniel", "Lisa"
]

LAST_NAMES = [
    "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis",
    "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson", "Thomas"
]

CITIES = [
    "New York", "Los Angeles", "Chicago", "Houston", "Phoenix", "Philadelphia",
    "San Antonio", "San Diego", "Dallas", "San Jose", "Austin", "Jacksonville"
]

STATES = ["NY", "CA", "IL", "TX", "AZ", "PA", "FL"]

ORDER_STATUSES = ["pending", "processing", "shipped", "delivered", "cancelled"]


class OpenSearchDataLoader:
    def __init__(self, base_url: str):
        self.base_url = base_url
        self.session = requests.Session()
        
    def create_index(self, index_name: str, mappings: Dict) -> bool:
        """Create an index with specified mappings"""
        url = f"{self.base_url}/{index_name}"
        
        # Delete index if exists
        try:
            self.session.delete(url)
            print(f"Deleted existing index: {index_name}")
        except:
            pass
        
        # Create new index
        response = self.session.put(url, json=mappings, headers={"Content-Type": "application/json"})
        
        if response.status_code in [200, 201]:
            print(f"[OK] Created index: {index_name}")
            return True
        else:
            print(f"[ERROR] Failed to create index {index_name}: {response.text}")
            return False
    
    def bulk_index(self, index_name: str, documents: List[Dict]) -> bool:
        """Bulk index documents"""
        url = f"{self.base_url}/_bulk"
        
        # Prepare bulk request body
        bulk_data = []
        for doc in documents:
            bulk_data.append(json.dumps({"index": {"_index": index_name, "_id": doc.get("id")}}))
            bulk_data.append(json.dumps(doc))
        
        bulk_body = "\n".join(bulk_data) + "\n"
        
        response = self.session.post(
            url,
            data=bulk_body,
            headers={"Content-Type": "application/x-ndjson"}
        )
        
        if response.status_code == 200:
            result = response.json()
            if not result.get("errors"):
                print(f"[OK] Indexed {len(documents)} documents to {index_name}")
                return True
            else:
                print(f"[ERROR] Some documents failed to index in {index_name}")
                return False
        else:
            print(f"[ERROR] Bulk index failed for {index_name}: {response.text}")
            return False
    
    def verify_data(self, index_name: str) -> int:
        """Verify data by counting documents"""
        url = f"{self.base_url}/{index_name}/_count"
        response = self.session.get(url)
        
        if response.status_code == 200:
            count = response.json().get("count", 0)
            print(f"[OK] Index {index_name} contains {count} documents")
            return count
        else:
            print(f"[ERROR] Failed to count documents in {index_name}")
            return 0


def get_products_mapping() -> Dict:
    """Define mapping for products index"""
    return {
        "mappings": {
            "properties": {
                "id": {"type": "keyword"},
                "name": {"type": "text", "fields": {"keyword": {"type": "keyword"}}},
                "category": {"type": "keyword"},
                "description": {"type": "text"},
                "price": {"type": "float"},
                "stock_quantity": {"type": "integer"},
                "rating": {"type": "float"},
                "reviews_count": {"type": "integer"},
                "brand": {"type": "keyword"},
                "created_at": {"type": "date"},
                "updated_at": {"type": "date"},
                "tags": {"type": "keyword"},
                "is_active": {"type": "boolean"}
            }
        }
    }


def get_customers_mapping() -> Dict:
    """Define mapping for customers index"""
    return {
        "mappings": {
            "properties": {
                "id": {"type": "keyword"},
                "first_name": {"type": "text", "fields": {"keyword": {"type": "keyword"}}},
                "last_name": {"type": "text", "fields": {"keyword": {"type": "keyword"}}},
                "email": {"type": "keyword"},
                "phone": {"type": "keyword"},
                "address": {
                    "properties": {
                        "street": {"type": "text"},
                        "city": {"type": "keyword"},
                        "state": {"type": "keyword"},
                        "zip_code": {"type": "keyword"},
                        "country": {"type": "keyword"}
                    }
                },
                "registration_date": {"type": "date"},
                "last_login": {"type": "date"},
                "total_orders": {"type": "integer"},
                "total_spent": {"type": "float"},
                "loyalty_points": {"type": "integer"},
                "is_premium": {"type": "boolean"}
            }
        }
    }


def get_orders_mapping() -> Dict:
    """Define mapping for orders index"""
    return {
        "mappings": {
            "properties": {
                "id": {"type": "keyword"},
                "customer_id": {"type": "keyword"},
                "order_date": {"type": "date"},
                "status": {"type": "keyword"},
                "items": {
                    "type": "nested",
                    "properties": {
                        "product_id": {"type": "keyword"},
                        "product_name": {"type": "text"},
                        "quantity": {"type": "integer"},
                        "unit_price": {"type": "float"},
                        "subtotal": {"type": "float"}
                    }
                },
                "total_amount": {"type": "float"},
                "shipping_address": {
                    "properties": {
                        "street": {"type": "text"},
                        "city": {"type": "keyword"},
                        "state": {"type": "keyword"},
                        "zip_code": {"type": "keyword"},
                        "country": {"type": "keyword"}
                    }
                },
                "payment_method": {"type": "keyword"},
                "shipping_method": {"type": "keyword"},
                "tracking_number": {"type": "keyword"},
                "notes": {"type": "text"}
            }
        }
    }


def generate_products(count: int = 50) -> List[Dict]:
    """Generate sample product data"""
    products = []
    product_id = 1
    
    for category in CATEGORIES:
        products_in_category = count // len(CATEGORIES)
        for i in range(products_in_category):
            product_name = random.choice(PRODUCT_NAMES[category])
            brand = f"Brand{random.randint(1, 10)}"
            
            product = {
                "id": f"PROD{product_id:04d}",
                "name": f"{brand} {product_name}",
                "category": category,
                "description": f"High-quality {product_name.lower()} from {brand}. Perfect for everyday use.",
                "price": round(random.uniform(9.99, 999.99), 2),
                "stock_quantity": random.randint(0, 500),
                "rating": round(random.uniform(3.0, 5.0), 1),
                "reviews_count": random.randint(0, 1000),
                "brand": brand,
                "created_at": (datetime.now() - timedelta(days=random.randint(1, 365))).isoformat(),
                "updated_at": datetime.now().isoformat(),
                "tags": [category.lower(), product_name.lower(), brand.lower()],
                "is_active": random.choice([True, True, True, False])  # 75% active
            }
            products.append(product)
            product_id += 1
    
    return products


def generate_customers(count: int = 100) -> List[Dict]:
    """Generate sample customer data"""
    customers = []
    
    for i in range(1, count + 1):
        first_name = random.choice(FIRST_NAMES)
        last_name = random.choice(LAST_NAMES)
        email = f"{first_name.lower()}.{last_name.lower()}{i}@example.com"
        
        registration_date = datetime.now() - timedelta(days=random.randint(1, 730))
        
        customer = {
            "id": f"CUST{i:04d}",
            "first_name": first_name,
            "last_name": last_name,
            "email": email,
            "phone": f"+1-{random.randint(200, 999)}-{random.randint(100, 999)}-{random.randint(1000, 9999)}",
            "address": {
                "street": f"{random.randint(100, 9999)} {random.choice(['Main', 'Oak', 'Maple', 'Cedar'])} St",
                "city": random.choice(CITIES),
                "state": random.choice(STATES),
                "zip_code": f"{random.randint(10000, 99999)}",
                "country": "USA"
            },
            "registration_date": registration_date.isoformat(),
            "last_login": (datetime.now() - timedelta(days=random.randint(0, 30))).isoformat(),
            "total_orders": random.randint(0, 50),
            "total_spent": round(random.uniform(0, 5000), 2),
            "loyalty_points": random.randint(0, 10000),
            "is_premium": random.choice([True, False])
        }
        customers.append(customer)
    
    return customers


def generate_orders(count: int, products: List[Dict], customers: List[Dict]) -> List[Dict]:
    """Generate sample order data"""
    orders = []
    payment_methods = ["credit_card", "debit_card", "paypal", "apple_pay", "google_pay"]
    shipping_methods = ["standard", "express", "overnight", "pickup"]
    
    for i in range(1, count + 1):
        customer = random.choice(customers)
        num_items = random.randint(1, 5)
        order_items = []
        total_amount = 0
        
        for _ in range(num_items):
            product = random.choice(products)
            quantity = random.randint(1, 3)
            unit_price = product["price"]
            subtotal = round(quantity * unit_price, 2)
            total_amount += subtotal
            
            order_items.append({
                "product_id": product["id"],
                "product_name": product["name"],
                "quantity": quantity,
                "unit_price": unit_price,
                "subtotal": subtotal
            })
        
        order_date = datetime.now() - timedelta(days=random.randint(0, 180))
        
        order = {
            "id": f"ORD{i:05d}",
            "customer_id": customer["id"],
            "order_date": order_date.isoformat(),
            "status": random.choice(ORDER_STATUSES),
            "items": order_items,
            "total_amount": round(total_amount, 2),
            "shipping_address": customer["address"],
            "payment_method": random.choice(payment_methods),
            "shipping_method": random.choice(shipping_methods),
            "tracking_number": f"TRK{random.randint(100000000, 999999999)}",
            "notes": random.choice(["", "", "", "Gift wrap requested", "Leave at door", "Call before delivery"])
        }
        orders.append(order)
    
    return orders


def main():
    print("=" * 60)
    print("OpenSearch E-Commerce Data Loader")
    print("=" * 60)
    print()
    
    # Initialize loader
    loader = OpenSearchDataLoader(OPENSEARCH_URL)
    
    # Test connection
    try:
        response = requests.get(OPENSEARCH_URL)
        if response.status_code == 200:
            print(f"[OK] Connected to OpenSearch at {OPENSEARCH_URL}")
            print()
        else:
            print(f"[ERROR] Failed to connect to OpenSearch")
            sys.exit(1)
    except Exception as e:
        print(f"[ERROR] Connection error: {e}")
        sys.exit(1)
    
    # Create indices with mappings
    print("Creating indices...")
    loader.create_index(PRODUCTS_INDEX, get_products_mapping())
    loader.create_index(CUSTOMERS_INDEX, get_customers_mapping())
    loader.create_index(ORDERS_INDEX, get_orders_mapping())
    print()
    
    # Generate data
    print("Generating sample data...")
    products = generate_products(50)
    print(f"[OK] Generated {len(products)} products")
    
    customers = generate_customers(100)
    print(f"[OK] Generated {len(customers)} customers")
    
    orders = generate_orders(200, products, customers)
    print(f"[OK] Generated {len(orders)} orders")
    print()
    
    # Load data
    print("Loading data into OpenSearch...")
    loader.bulk_index(PRODUCTS_INDEX, products)
    loader.bulk_index(CUSTOMERS_INDEX, customers)
    loader.bulk_index(ORDERS_INDEX, orders)
    print()
    
    # Verify data
    print("Verifying data...")
    loader.verify_data(PRODUCTS_INDEX)
    loader.verify_data(CUSTOMERS_INDEX)
    loader.verify_data(ORDERS_INDEX)
    print()
    
    print("=" * 60)
    print("[OK] Data loading complete!")
    print("=" * 60)
    print()
    print("Access OpenSearch Dashboards at: http://localhost:30561")
    print("Create index patterns: products*, customers*, orders*")
    print()


if __name__ == "__main__":
    main()

# Made with Bob
