# Orders Feature Implementation

## Overview

This document describes the implementation of the Orders feature for the Gloria Marketing Flutter application. The feature provides comprehensive order management functionality including order listing, status tracking, filtering, and synchronization with the SOAP API.

## Architecture

### Components

1. **Models**
   - `Order`: Represents an order entity with all order details
   - `OrderStatus`: Represents order status information

2. **Services**
   - `SoapApiService`: Handles SOAP API communication for order data
   - `ApiDatabaseService`: Manages local SQLite database operations
   - `DataSyncService`: Coordinates data synchronization between API and local storage

3. **Repository**
   - `AgentRepository`: Provides a clean interface for order data operations

4. **UI Components**
   - `OrdersPage`: Main orders listing page with tabs, filters, and search
   - `OrderCard`: Individual order display card
   - `OrderGridTile`: Grid view representation of orders

## Database Schema

### Tables

#### `orders`
```sql
CREATE TABLE orders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  num_order TEXT UNIQUE NOT NULL,
  date_order TEXT NOT NULL,
  caption_order TEXT,
  type_price TEXT,
  status TEXT,
  comment_supervisor TEXT,
  comment_forwarder TEXT,
  comment_agent TEXT,
  total REAL NOT NULL,
  client_code TEXT NOT NULL,
  client_name TEXT NOT NULL,
  code_org TEXT,
  main_status TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (type_price) REFERENCES price_types (code) ON DELETE SET NULL,
  FOREIGN KEY (client_code) REFERENCES clients (code) ON DELETE CASCADE,
  FOREIGN KEY (main_status) REFERENCES order_statuses (message) ON DELETE SET NULL
);
```

#### `order_statuses`
```sql
CREATE TABLE order_statuses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  message TEXT UNIQUE NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

### Relationships

- `orders.type_price` → `price_types.code` (Foreign Key)
- `orders.client_code` → `clients.code` (Foreign Key)
- `orders.main_status` → `order_statuses.message` (Foreign Key)

## API Integration

### SOAP Endpoints

#### GetOrderStatusList
**Purpose**: Retrieves available order statuses
**Request**:
```xml
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
  <soap:Header/>
  <soap:Body>
    <sam:GetOrderStatusList>
      <sam:CodeAgent>000000329</sam:CodeAgent>
    </sam:GetOrderStatusList>
  </soap:Body>
</soap:Envelope>
```

**Response**:
```xml
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
  <soap:Body>
    <m:getOrderStatusListResponse xmlns:m="http://www.sample-package.org">
      <m:return xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <m:Row><m:message>Новый</m:message></m:Row>
        <m:Row><m:message>Оператор подтвердил и в процессе комплектации</m:message></m:Row>
        <!-- ... more statuses ... -->
      </m:return>
    </m:getOrderStatusListResponse>
  </soap:Body>
</soap:Envelope>
```

#### GetOrderList
**Purpose**: Retrieves user's orders with detailed information
**Request**:
```xml
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
  <soap:Header/>
  <soap:Body>
    <sam:GetOrderList>
      <sam:CodeAgent>000000329</sam:CodeAgent>
    </sam:GetOrderList>
  </soap:Body>
</soap:Envelope>
```

**Response**:
```xml
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
  <soap:Body>
    <m:GetOrderListResponse xmlns:m="http://www.sample-package.org">
      <m:return xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <m:Rows>
          <m:NumOrder>GL00-154855</m:NumOrder>
          <m:DateOrder>2025-10-01T10:52:10</m:DateOrder>
          <m:CaptionOrder>Заказ клиента GL00-154855 от 01.10.2025 10:52:10</m:CaptionOrder>
          <m:TypePrice>Цена PS опт</m:TypePrice>
          <m:Status>2</m:Status>
          <m:Total>785200</m:Total>
          <m:ClientCode>00-00054499</m:ClientCode>
          <m:ClientName>OVAYXON OOO</m:ClientName>
          <m:mainStatus>Доставлено и ожидает оплаты</m:mainStatus>
        </m:Rows>
        <!-- ... more orders ... -->
      </m:return>
    </m:GetOrderListResponse>
  </soap:Body>
</soap:Envelope>
```

## Features

### Order Listing
- **Tabbed Interface**: Orders categorized by status (All, Delivered, In Progress, Return, Expired)
- **Search Functionality**: Search by order number, client code, client name, status, or total amount
- **Filtering**: Filter by status and date range
- **View Modes**: Switch between list and grid views

### Data Synchronization
- **Automatic Sync**: Orders are synchronized when the app starts if no cached data exists
- **Manual Refresh**: Pull-to-refresh functionality
- **Background Sync**: Integrated with the app's data sync service

### Status Management
- **Status Tracking**: Real-time status updates from the server
- **Visual Indicators**: Color-coded status badges
- **Status Filtering**: Filter orders by specific statuses

## Code Quality

### Best Practices Implemented

1. **Clean Architecture**: Separation of concerns with clear layers (UI, Repository, Services, Models)
2. **Error Handling**: Comprehensive try-catch blocks with user-friendly error messages
3. **Async/Await**: Proper asynchronous programming patterns
4. **Null Safety**: Full null safety implementation
5. **SOLID Principles**: Single responsibility, dependency injection, etc.
6. **Material Design 3**: Modern UI components and theming

### Testing

- **Unit Tests**: Model classes, database operations, API parsing
- **Integration Tests**: Service layer interactions
- **Widget Tests**: UI component testing

## Usage

### Navigation
Orders can be accessed from the main drawer menu under "Buyurtmalar".

### Filtering and Search
1. Use the search bar to find specific orders
2. Tap the filter icon to access advanced filters
3. Switch between tabs to view orders by status
4. Use the view toggle to switch between list and grid modes

### Data Management
- Orders are automatically cached locally for offline access
- Pull down to refresh data from the server
- Data sync happens in the background during app usage

## Future Enhancements

1. **Order Details Page**: Detailed view for individual orders
2. **Order Creation**: New order creation functionality
3. **Order Modification**: Edit existing orders
4. **Bulk Operations**: Select multiple orders for batch operations
5. **Export Functionality**: Export orders to PDF/Excel
6. **Push Notifications**: Real-time order status updates

## Dependencies

- `sqflite`: Local database storage
- `dio`: HTTP client for SOAP requests
- `xml`: XML parsing for SOAP responses
- `intl`: Date and number formatting
- `flutter_bloc`: State management (inherited from app architecture)

## UI Design Updates

### Order Card Widget
A new modern order card widget has been implemented with the following features:

- **Material Design 3 Compliance**: Uses proper color schemes, typography, and spacing
- **Dual View Modes**: Supports both list and grid view layouts
- **Status Color Coding**:
  - **Доставлено** (Delivered): Primary container color
  - **Возврат** (Return): Error container color
  - **В процессе** (In Progress): Secondary container color
  - **Истек** (Expired): Tertiary container color
  - **Новый** (New): Default surface color
- **Responsive Design**: Adapts to different screen sizes and content lengths
- **Accessibility**: Proper contrast ratios and touch targets
- **No Images**: Grid view does not include images as requested

### Key UI Components

#### List View Card
- Order ID and status in header
- Client information with business icon
- Client code display
- Date and amount in bottom row
- Price type display (when available)

#### Grid View Card
- Compact status chip at top-right
- Order ID and client name
- Shortened date format
- Amount display
- Status chip with truncated text for long statuses

## Files Created/Modified

### New Files
- `lib/src/features/agent/data/models/order.dart`
- `lib/src/features/agent/data/models/order_status.dart`
- `lib/src/features/agent/presentation/pages/orders_page.dart`
- `lib/src/features/agent/presentation/widgets/order_card_widget.dart`
- `test/order_database_test.dart`
- `test/order_model_test.dart`
- `test/order_status_database_test.dart`
- `test/order_status_model_test.dart`
- `test/order_card_widget_test.dart`

### Modified Files
- `lib/src/core/database/database_helper.dart` (added order tables)
- `lib/src/core/services/soap_api_service.dart` (added order API methods)
- `lib/src/core/services/api_database_service.dart` (added order DB methods)
- `lib/src/core/services/data_sync_service.dart` (added order sync methods)
- `lib/src/features/agent/data/repositories/agent_repository.dart` (added order methods)
- `lib/src/core/router/app_router.dart` (added orders route)
- `lib/src/features/agent/presentation/pages/agent_home_modern.dart` (added orders menu item)

This implementation provides a robust, scalable, and maintainable orders management system that integrates seamlessly with the existing Gloria Marketing Flutter application architecture.