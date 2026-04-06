# Gloria Marketing Database Schema

## Overview
The Gloria Marketing application uses a SQLite database with the following structure. The database is initialized from a pre-built asset file (`GloriyaMarketing.zip`) and contains cached API data.

## Tables

### 1. users
**Purpose**: Stores user authentication and profile information
```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT UNIQUE NOT NULL,
  username TEXT NOT NULL,
  password TEXT NOT NULL,
  name TEXT NOT NULL,
  role TEXT NOT NULL,
  warehouse_code TEXT,
  code_project TEXT,
  base_url TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
```

### 2. kpi_data
**Purpose**: Stores Key Performance Indicator data for users
```sql
CREATE TABLE kpi_data (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_code TEXT NOT NULL,
  plan TEXT NOT NULL,
  fact TEXT NOT NULL,
  total_percent TEXT NOT NULL,
  total_forecast TEXT NOT NULL,
  total_percent_forecast_fact TEXT NOT NULL,
  akb_plan TEXT NOT NULL,
  akb_fact TEXT NOT NULL,
  akb_percent TEXT NOT NULL,
  okb TEXT NOT NULL,
  update_date TEXT NOT NULL,
  created_at TEXT NOT NULL
)
```

### 3. business_regions
**Purpose**: Stores business region information
```sql
CREATE TABLE business_regions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
```

### 4. user_warehouses
**Purpose**: Stores warehouse information accessible to users
```sql
CREATE TABLE user_warehouses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  organization TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
```

### 5. product_brands
**Purpose**: Stores product brand information
```sql
CREATE TABLE product_brands (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
```

### 6. product_series
**Purpose**: Stores product series information linked to brands
```sql
CREATE TABLE product_series (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  brand_name TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (brand_name) REFERENCES product_brands (name) ON DELETE CASCADE,
  UNIQUE(name, brand_name)
)
```

### 7. product_balances
**Purpose**: Stores detailed product balance information per warehouse
```sql
CREATE TABLE product_balances (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code_sklad TEXT NOT NULL,
  code_product TEXT NOT NULL,
  name_product TEXT NOT NULL,
  have INTEGER NOT NULL,
  reserved INTEGER NOT NULL,
  available INTEGER NOT NULL,
  weight REAL NOT NULL,
  capacity REAL NOT NULL,
  code_project TEXT NOT NULL,
  vendor_code TEXT NOT NULL,
  product_brand TEXT NOT NULL,
  product_series TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (code_sklad) REFERENCES user_warehouses (code) ON DELETE CASCADE,
  FOREIGN KEY (code_product) REFERENCES products (code) ON DELETE CASCADE,
  FOREIGN KEY (product_brand) REFERENCES product_brands (name) ON DELETE CASCADE,
  UNIQUE(code_sklad, code_product)
)
```

### 8. clients
**Purpose**: Stores client/customer information
```sql
CREATE TABLE clients (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  address TEXT NOT NULL,
  phone TEXT,
  inn TEXT,
  contact_person TEXT,
  latitude REAL DEFAULT 0.0,
  longitude REAL DEFAULT 0.0,
  region TEXT,
  district TEXT,
  status TEXT DEFAULT 'active',
  last_visit_date TEXT,
  has_orders INTEGER DEFAULT 0,
  has_contracts INTEGER DEFAULT 0,
  is_visited INTEGER DEFAULT 0,
  has_contract INTEGER DEFAULT 0,
  owner_name TEXT,
  signboard TEXT,
  reference_point TEXT,
  responsible_person TEXT,
  responsible_person_phone TEXT,
  trade_point_type TEXT,
  credit_limit REAL DEFAULT 0.0,
  accumulated_credit REAL DEFAULT 0.0,
  code_region TEXT REFERENCES business_regions(code) ON DELETE SET NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
```

### 9. products
**Purpose**: Stores product catalog information
```sql
CREATE TABLE products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  unit TEXT NOT NULL,
  quantity REAL DEFAULT 0.0,
  reserved REAL DEFAULT 0.0,
  available REAL DEFAULT 0.0,
  category TEXT,
  barcode TEXT,
  have INTEGER DEFAULT 0,
  warehouse_code TEXT,
  weight REAL DEFAULT 0.0,
  capacity REAL DEFAULT 0.0,
  vendor_code TEXT,
  product_brand TEXT,
  product_series TEXT,
  code_project TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
```

### 10. price_types
**Purpose**: Stores different price type categories
```sql
CREATE TABLE price_types (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  is_default INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
```

### 11. product_prices
**Purpose**: Stores pricing information for products by price type
```sql
CREATE TABLE product_prices (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_code TEXT NOT NULL,
  price_type_code TEXT NOT NULL,
  price REAL NOT NULL,
  currency TEXT DEFAULT 'UZS',
  valid_from TEXT,
  valid_to TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (product_code) REFERENCES products (code) ON DELETE CASCADE,
  FOREIGN KEY (price_type_code) REFERENCES price_types (code) ON DELETE CASCADE,
  UNIQUE(product_code, price_type_code)
)
```

### 12. promotions
**Purpose**: Stores promotional campaign information
```sql
CREATE TABLE promotions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  min_promo_product_count INTEGER NOT NULL,
  bonus_count INTEGER NOT NULL,
  date_start TEXT NOT NULL,
  date_end TEXT NOT NULL,
  last_synced TEXT,
  is_active INTEGER DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
```

### 13. promotion_product_list
**Purpose**: Links promotions to eligible products
```sql
CREATE TABLE promotion_product_list (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  promotion_code TEXT NOT NULL,
  product_code TEXT NOT NULL,
  product_name TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (promotion_code) REFERENCES promotions (code) ON DELETE CASCADE,
  UNIQUE(promotion_code, product_code)
)
```

### 14. promotion_bonus_list
**Purpose**: Links promotions to bonus products
```sql
CREATE TABLE promotion_bonus_list (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  promotion_code TEXT NOT NULL,
  product_code TEXT NOT NULL,
  product_name TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (promotion_code) REFERENCES promotions (code) ON DELETE CASCADE,
  UNIQUE(promotion_code, product_code)
)
```

### 15. promotion_class_list
**Purpose**: Links promotions to product classes/categories
```sql
CREATE TABLE promotion_class_list (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  promotion_code TEXT NOT NULL,
  class_code TEXT NOT NULL,
  class_name TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (promotion_code) REFERENCES promotions (code) ON DELETE CASCADE,
  UNIQUE(promotion_code, class_code)
)
```

## Indexes

### Performance Indexes
```sql
-- Promotions
CREATE INDEX idx_promotions_code ON promotions(code);
CREATE INDEX idx_promotions_active ON promotions(is_active);
CREATE INDEX idx_promotions_date_range ON promotions(date_start, date_end);

-- Promotion lists
CREATE INDEX idx_promotion_product_list_promotion_code ON promotion_product_list(promotion_code);
CREATE INDEX idx_promotion_bonus_list_promotion_code ON promotion_bonus_list(promotion_code);
CREATE INDEX idx_promotion_class_list_promotion_code ON promotion_class_list(promotion_code);

-- Product balances
CREATE INDEX idx_product_balances_code_sklad ON product_balances(code_sklad);
CREATE INDEX idx_product_balances_code_product ON product_balances(code_product);
CREATE INDEX idx_product_balances_product_brand ON product_balances(product_brand);
CREATE INDEX idx_product_balances_product_series ON product_balances(product_series);
CREATE INDEX idx_product_series_brand_name ON product_series(brand_name);

-- Clients
CREATE INDEX idx_clients_code_region ON clients(code_region);
```

## Relationships

### Entity Relationships
- **users** ↔ **user_warehouses**: One-to-many (warehouse_code)
- **products** ↔ **product_prices**: One-to-many (product_code)
- **price_types** ↔ **product_prices**: One-to-many (price_type_code)
- **products** ↔ **product_balances**: One-to-many (code_product)
- **user_warehouses** ↔ **product_balances**: One-to-many (code_sklad)
- **product_brands** ↔ **product_series**: One-to-many (brand_name)
- **clients** ↔ **business_regions**: Many-to-one (code_region)
- **promotions** ↔ **promotion_product_list**: One-to-many (promotion_code)
- **promotions** ↔ **promotion_bonus_list**: One-to-many (promotion_code)
- **promotions** ↔ **promotion_class_list**: One-to-many (promotion_code)

## Optimized Query for Prices Page

The optimized query used in the prices page performs efficient JOINs:

```sql
SELECT
  p.code as product_code,
  p.name as product_name,
  p.unit as unit,
  p.quantity as quantity,
  p.reserved as reserved,
  p.available as available,
  p.category as category,
  p.barcode as barcode,
  p.have as have,
  p.warehouse_code as warehouse_code,
  COALESCE(uw.name, '') as warehouse_name,
  p.weight as weight,
  p.capacity as capacity,
  p.vendor_code as vendor_code,
  p.product_brand as product_brand,
  p.product_series as product_series,
  p.code_project as code_project,
  pp.price_type_code as price_type_code,
  pt.name as price_type_name,
  pp.price as price,
  pp.currency as currency,
  pp.valid_from as valid_from,
  pp.valid_to as valid_to
FROM product_prices pp
INNER JOIN products p ON pp.product_code = p.code
INNER JOIN price_types pt ON pp.price_type_code = pt.code
LEFT JOIN user_warehouses uw ON p.warehouse_code = uw.code
WHERE pp.price_type_code = ?
  AND p.code_project = ?
  AND p.warehouse_code IN (...)
ORDER BY p.name ASC, p.code ASC
```

### 19. user_projects
**Purpose**: Stores user project assignments retrieved from GetProjectsUser SOAP API
```sql
CREATE TABLE user_projects (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL,
  name TEXT NOT NULL,
  user_code TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  UNIQUE(code, user_code)
)
```
**Indexes**: `idx_user_projects_code`, `idx_user_projects_user_code`
**Relationships**: `user_code` → `users.code`

## Data Flow

1. **Initial Load**: Database is copied from assets and initialized
2. **API Sync**: Data is synchronized from SOAP API endpoints
3. **Caching**: API responses are stored in local SQLite database
4. **Query Optimization**: Complex JOINs provide efficient data retrieval
5. **Real-time Filtering**: Database-level filtering minimizes client processing

## Key Optimization Features

- **Foreign Key Constraints**: Ensure data integrity
- **Unique Constraints**: Prevent duplicate entries
- **Indexes**: Optimize query performance
- **Batch Operations**: Efficient bulk data operations
- **JOIN Optimization**: Single query replaces multiple data fetches