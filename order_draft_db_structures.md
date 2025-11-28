# Order Draft Database Table Structures

This document defines the database table structures for `create_order` and `create_order_products` tables used in the order draft functionality.

## JSON Format

### create_order Table Structure
```json
{
  "table_name": "create_order",
  "fields": [
    {
      "name": "id",
      "type": "INTEGER",
      "primary_key": true,
      "auto_increment": true,
      "nullable": false,
      "description": "Unique identifier for the order"
    },
    {
      "name": "codeAgent",
      "type": "TEXT",
      "nullable": false,
      "description": "Agent code who created the order"
    },
    {
      "name": "codeClient",
      "type": "TEXT",
      "nullable": false,
      "description": "Client code for the order"
    },
    {
      "name": "codePrice",
      "type": "TEXT",
      "nullable": false,
      "description": "Price type code"
    },
    {
      "name": "payment",
      "type": "TEXT",
      "nullable": false,
      "description": "Payment method or terms"
    },
    {
      "name": "shippingDate",
      "type": "DATETIME",
      "nullable": false,
      "description": "Scheduled shipping date"
    },
    {
      "name": "commentSupervisor",
      "type": "TEXT",
      "nullable": true,
      "description": "Comments from supervisor"
    },
    {
      "name": "commentForwarder",
      "type": "TEXT",
      "nullable": true,
      "description": "Comments from forwarder"
    },
    {
      "name": "comment",
      "type": "TEXT",
      "nullable": true,
      "description": "General comments for the order"
    },
    {
      "name": "createDate",
      "type": "DATETIME",
      "nullable": false,
      "description": "Order creation timestamp"
    },
    {
      "name": "longitude",
      "type": "REAL",
      "nullable": false,
      "description": "GPS longitude coordinate"
    },
    {
      "name": "latitude",
      "type": "REAL",
      "nullable": false,
      "description": "GPS latitude coordinate"
    },
    {
      "name": "weight",
      "type": "REAL",
      "nullable": false,
      "description": "Total weight of the order"
    },
    {
      "name": "capacity",
      "type": "REAL",
      "nullable": false,
      "description": "Total capacity/volume of the order"
    },
    {
      "name": "credit",
      "type": "INTEGER",
      "nullable": false,
      "description": "Whether the order is on credit (0=false, 1=true)"
    },
    {
      "name": "codeProject",
      "type": "TEXT",
      "nullable": false,
      "description": "Project code associated with the order"
    },
    {
      "name": "orderType",
      "type": "INTEGER",
      "nullable": false,
      "description": "Type of order (numeric code)"
    },
    {
      "name": "codeOrg",
      "type": "TEXT",
      "nullable": false,
      "description": "Organization code"
    },
    {
      "name": "codeSklad",
      "type": "TEXT",
      "nullable": false,
      "description": "Warehouse code"
    },
    {
      "name": "codeContract",
      "type": "TEXT",
      "nullable": true,
      "description": "Contract code if applicable"
    },
    {
      "name": "hasPromo",
      "type": "INTEGER",
      "nullable": false,
      "description": "Whether the order has promotional items (0=false, 1=true)"
    },
    {
      "name": "isSynced",
      "type": "INTEGER",
      "nullable": false,
      "default": 0,
      "description": "Whether the order has been synced to server (0=false, 1=true)"
    },
    {
      "name": "syncedAt",
      "type": "DATETIME",
      "nullable": true,
      "description": "Timestamp when order was last synced"
    },
    {
      "name": "syncError",
      "type": "TEXT",
      "nullable": true,
      "description": "Error message if sync failed"
    }
  ]
}
```

### create_order_products Table Structure
```json
{
  "table_name": "create_order_products",
  "fields": [
    {
      "name": "id",
      "type": "INTEGER",
      "primary_key": true,
      "auto_increment": true,
      "nullable": false,
      "description": "Unique identifier for the order product"
    },
    {
      "name": "createOrderId",
      "type": "INTEGER",
      "nullable": false,
      "foreign_key": "create_order.id",
      "description": "Foreign key reference to create_order table"
    },
    {
      "name": "codeSklad",
      "type": "TEXT",
      "nullable": false,
      "description": "Warehouse code for the product"
    },
    {
      "name": "codeProduct",
      "type": "TEXT",
      "nullable": false,
      "description": "Product code"
    },
    {
      "name": "vendorCode",
      "type": "TEXT",
      "nullable": false,
      "description": "Vendor/supplier code for the product"
    },
    {
      "name": "amount",
      "type": "INTEGER",
      "nullable": false,
      "description": "Quantity of the product"
    },
    {
      "name": "price",
      "type": "REAL",
      "nullable": false,
      "description": "Unit price of the product"
    },
    {
      "name": "total",
      "type": "REAL",
      "nullable": false,
      "description": "Total price for this product line (price * amount)"
    },
    {
      "name": "weight",
      "type": "REAL",
      "nullable": false,
      "description": "Weight of this product line"
    },
    {
      "name": "capacity",
      "type": "REAL",
      "nullable": false,
      "description": "Capacity/volume of this product line"
    },
    {
      "name": "paymentType",
      "type": "INTEGER",
      "nullable": false,
      "description": "Payment type code for this product"
    },
    {
      "name": "discountSum",
      "type": "REAL",
      "nullable": false,
      "description": "Fixed discount amount"
    },
    {
      "name": "discountRate",
      "type": "REAL",
      "nullable": false,
      "description": "Discount percentage rate"
    },
    {
      "name": "giftAmount",
      "type": "INTEGER",
      "nullable": false,
      "description": "Number of gift items"
    },
    {
      "name": "promo",
      "type": "INTEGER",
      "nullable": false,
      "description": "Whether this product is promotional (0=false, 1=true)"
    }
  ]
}
```

## Table Format

### create_order Table

| Field | Type | Nullable | Default | Description |
|-------|------|----------|---------|-------------|
| id | INTEGER | NO | AUTO_INCREMENT | Unique identifier for the order |
| codeAgent | TEXT | NO | - | Agent code who created the order |
| codeClient | TEXT | NO | - | Client code for the order |
| codePrice | TEXT | NO | - | Price type code |
| payment | TEXT | NO | - | Payment method or terms |
| shippingDate | DATETIME | NO | - | Scheduled shipping date |
| commentSupervisor | TEXT | YES | NULL | Comments from supervisor |
| commentForwarder | TEXT | YES | NULL | Comments from forwarder |
| comment | TEXT | YES | NULL | General comments for the order |
| createDate | DATETIME | NO | - | Order creation timestamp |
| longitude | REAL | NO | - | GPS longitude coordinate |
| latitude | REAL | NO | - | GPS latitude coordinate |
| weight | REAL | NO | - | Total weight of the order |
| capacity | REAL | NO | - | Total capacity/volume of the order |
| credit | INTEGER | NO | - | Whether the order is on credit (0=false, 1=true) |
| codeProject | TEXT | NO | - | Project code associated with the order |
| orderType | INTEGER | NO | - | Type of order (numeric code) |
| codeOrg | TEXT | NO | - | Organization code |
| codeSklad | TEXT | NO | - | Warehouse code |
| codeContract | TEXT | YES | NULL | Contract code if applicable |
| hasPromo | INTEGER | NO | - | Whether the order has promotional items (0=false, 1=true). Calculated from product list. |
| isSynced | INTEGER | NO | 0 | Whether the order has been synced to server (0=false, 1=true) |
| syncedAt | DATETIME | YES | NULL | Timestamp when order was last synced |
| syncError | TEXT | YES | NULL | Error message if sync failed |

## Field Population Logic

The following fields are automatically populated from various sources:

- **codeAgent**: Retrieved from current user preferences (`SharedPreferencesService.getUserCode()`)
- **longitude/latitude**: Retrieved from location service (`LocationService.getStoredLocation()`)
- **weight**: Calculated as sum of (product.weight × product.amount) for all selected products
- **capacity**: Calculated as sum of (product.capacity × product.amount) for all selected products
- **codeProject**: Retrieved from user preferences (`SharedPreferencesService.getCodeProject()`)
- **hasPromo**: Calculated as true if any selected product has `promo = true`
- **payment**: Default empty string (configurable by user)
- **commentSupervisor**: Default empty string (set by supervisor)
- **commentForwarder**: Default empty string (set by forwarder)
- **credit**: Default false (0)
- **orderType**: Default 0 (configurable)
- **codeContract**: Default empty string (set when contract is selected)

### create_order_products Table

| Field | Type | Nullable | Default | Description |
|-------|------|----------|---------|-------------|
| id | INTEGER | NO | AUTO_INCREMENT | Unique identifier for the order product |
| createOrderId | INTEGER | NO | - | Foreign key reference to create_order.id |
| codeSklad | TEXT | NO | - | Warehouse code for the product |
| codeProduct | TEXT | NO | - | Product code |
| vendorCode | TEXT | NO | - | Vendor/supplier code for the product |
| amount | INTEGER | NO | - | Quantity of the product |
| price | REAL | NO | - | Unit price of the product |
| total | REAL | NO | - | Total price for this product line (price * amount) |
| weight | REAL | NO | - | Weight of this product line |
| capacity | REAL | NO | - | Capacity/volume of this product line |
| paymentType | INTEGER | NO | - | Payment type code for this product |
| discountSum | REAL | NO | - | Fixed discount amount |
| discountRate | REAL | NO | - | Discount percentage rate |
| giftAmount | INTEGER | NO | - | Number of gift items |
| promo | INTEGER | NO | - | Whether this product is promotional (0=false, 1=true) |

## Relationships

- `create_order_products.createOrderId` → `create_order.id` (Foreign Key)
## Order Draft Data Content Structure

The order draft data is stored as JSON in the `dataContent` field of the `visit_steps_data` table with `dataType = 'order_draft'`.

### JSON Structure
```json
{
  "visitId": "string",
  "clientCode": "string",
  "stepCode": "integer",
  "stepName": "string",
  "selectedOrganization": "string",
  "selectedWarehouse": "string",
  "selectedPriceType": "string",
  "selectedOrganizationcode": "string",
  "selectedWarehousecode": "string",
  "selectedPriceTypecode": "string",
  "shippingDate": "string (ISO8601 datetime)",
  "products": [
    {
      "id": "integer (optional)",
      "createOrderId": "integer (optional)",
      "codeSklad": "string",
      "codeProduct": "string",
      "vendorCode": "string",
      "amount": "integer",
      "price": "number",
      "total": "number",
      "weight": "number",
      "capacity": "number",
      "paymentType": "integer",
      "discountSum": "number",
      "discountRate": "number",
      "giftAmount": "integer",
      "promo": "boolean"
    }
  ],
  "notes": "string",
  "timestamp": "string (ISO8601 datetime)",
  "version": "integer",
  "codeAgent": "string",
  "longitude": "number",
  "latitude": "number",
  "weight": "number",
  "capacity": "number",
  "codeProject": "string",
  "hasPromo": "boolean"
}
```

### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| visitId | string | Yes | Unique identifier for the visit |
| clientCode | string | Yes | Client code for the order |
| stepCode | integer | Yes | Step code in the visit process |
| stepName | string | Yes | Name of the current step |
| selectedOrganization | string | Yes | Display name of selected organization |
| selectedWarehouse | string | Yes | Display name of selected warehouse |
| selectedPriceType | string | Yes | Display name of selected price type |
| selectedOrganizationcode | string | Yes | Code of selected organization |
| selectedWarehousecode | string | Yes | Code of selected warehouse |
| selectedPriceTypecode | string | Yes | Code of selected price type |
| shippingDate | string | Yes | Shipping date in ISO8601 format |
| products | array | Yes | Array of selected products (CreateOrderProduct format) |
| notes | string | Yes | Additional notes/comments |
| timestamp | string | Yes | Last save timestamp in ISO8601 format |
| version | integer | Yes | Data structure version for migration support |
| codeAgent | string | Yes | Agent code who created the order (from user preferences) |
| longitude | number | Yes | GPS longitude coordinate (from location service) |
| latitude | number | Yes | GPS latitude coordinate (from location service) |
| weight | number | Yes | Total weight calculated from selected products |
| capacity | number | Yes | Total capacity calculated from selected products |
| codeProject | string | Yes | Project code from user preferences |
| hasPromo | boolean | Yes | Whether order contains promotional products |

### Products Array Structure

Each product in the `products` array follows the `CreateOrderProduct` model structure with the following fields:

- `codeSklad`: Warehouse code
- `codeProduct`: Product code
- `vendorCode`: Vendor/supplier code
- `amount`: Quantity
- `price`: Unit price
- `total`: Total price (price × amount)
- `weight`: Product weight
- `capacity`: Product capacity/volume
- `paymentType`: Payment type code
- `discountSum`: Fixed discount amount
- `discountRate`: Discount percentage
- `giftAmount`: Number of gift items
- `promo`: Whether product is promotional
- One-to-many relationship: One order can have multiple products