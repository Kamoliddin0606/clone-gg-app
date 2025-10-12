# Order Management Implementation

## Overview
This document describes the implementation of order management functionality for the Gloria Marketing Flutter application. The implementation includes SOAP API integration for fetching order statuses and order lists, database schema design, model classes, service layers, and comprehensive testing.

## Architecture Analysis

### Project Structure
- **Framework**: Flutter with Dart
- **State Management**: BLoC pattern
- **Networking**: Dio with XML parsing for SOAP APIs
- **Database**: SQLite with Sqflite
- **Architecture**: Clean Architecture with feature-based organization

### Key Components
- **Models**: Data classes for Order and OrderStatus
- **Services**: SOAP API service, Database service, Data sync service
- **Database**: SQLite tables with foreign key relationships
- **Testing**: Unit tests and integration tests

## API Analysis

### getOrderStatusList API
**Purpose**: Retrieves available order status messages from the server.

**Request Format**:
```xml
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
   <soap:Header/>
   <soap:Body>
      <sam:getOrderStatusList>
         <sam:CodeAgent>000000329</sam:CodeAgent>
      </sam:getOrderStatusList>
   </soap:Body>
</soap:Envelope>
```

**Response Format**:
```xml
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
   <soap:Body>
      <m:getOrderStatusListResponse xmlns:m="http://www.sample-package.org">
         <m:return xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <m:Row><m:message>Новый</m:message></m:Row>
            <m:Row><m:message>Доставлено и оплачено</m:message></m:Row>
            <!-- ... more statuses ... -->
         </m:return>
      </m:getOrderStatusListResponse>
   </soap:Body>
</soap:Envelope>
```

### GetOrderList API
**Purpose**: Retrieves detailed order information for a specific agent.

**Request Format**:
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

**Response Format**:
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
               <m:CodeOrg>00000000001</m:CodeOrg>
               <m:mainStatus>Доставлено и ожидает оплаты</m:mainStatus>
            </m:Rows>
            <!-- ... more orders ... -->
         </m:return>
      </m:GetOrderListResponse>
   </soap:Body>
</soap:Envelope>
```

## Database Schema

### Tables Created

#### order_statuses
```sql
CREATE TABLE order_statuses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  message TEXT UNIQUE NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

#### orders
```sql
CREATE TABLE orders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  num_order TEXT UNIQUE NOT NULL,
  date_order TEXT NOT NULL,
  caption_order TEXT NOT NULL,
  type_price_code TEXT NOT NULL,
  status INTEGER NOT NULL,
  comment_supervisor TEXT,
  comment_forwarder TEXT,
  comment_agent TEXT,
  total REAL NOT NULL,
  client_code TEXT NOT NULL,
  client_name TEXT NOT NULL,
  code_org TEXT NOT NULL,
  main_status TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

### Relationships
- `orders.type_price_code` → `price_types.code` (foreign key)
- `orders.client_code` → `clients.code` (foreign key)
- `orders.main_status` → `order_statuses.message` (logical relationship)

### Indexes
- `idx_orders_num_order` on orders(num_order)
- `idx_orders_client_code` on orders(client_code)
- `idx_orders_type_price_code` on orders(type_price_code)
- `idx_orders_main_status` on orders(main_status)
- `idx_order_statuses_message` on order_statuses(message)

## Model Classes

### OrderStatus
```dart
class OrderStatus {
  final int id;
  final String message;

  OrderStatus({
    this.id = 0,
    required this.message,
  });

  // JSON serialization methods
  factory OrderStatus.fromJson(Map<String, dynamic> json) => OrderStatus(
    id: json['id'] as int? ?? 0,
    message: json['message'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'message': message,
  };

  // Copy and equality methods
  OrderStatus copyWith({int? id, String? message}) => OrderStatus(
    id: id ?? this.id,
    message: message ?? this.message,
  );

  @override
  bool operator ==(Object other) => identical(this, other) ||
    (other is OrderStatus && other.id == id && other.message == message);

  @override
  int get hashCode => id.hashCode ^ message.hashCode;

  @override
  String toString() => 'OrderStatus(id: $id, message: $message)';
}
```

### Order
```dart
class Order {
  final int id;
  final String numOrder;
  final DateTime dateOrder;
  final String captionOrder;
  final String typePriceCode;
  final int status;
  final String? commentSupervisor;
  final String? commentForwarder;
  final String? commentAgent;
  final double total;
  final String clientCode;
  final String clientName;
  final String codeOrg;
  final String mainStatus;

  Order({
    this.id = 0,
    required this.numOrder,
    required this.dateOrder,
    required this.captionOrder,
    required this.typePriceCode,
    required this.status,
    this.commentSupervisor,
    this.commentForwarder,
    this.commentAgent,
    required this.total,
    required this.clientCode,
    required this.clientName,
    required this.codeOrg,
    required this.mainStatus,
  });

  // JSON serialization methods
  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] as int? ?? 0,
    numOrder: json['numOrder'] as String,
    dateOrder: DateTime.parse(json['dateOrder'] as String),
    captionOrder: json['captionOrder'] as String,
    typePriceCode: json['typePriceCode'] as String,
    status: json['status'] as int,
    commentSupervisor: json['commentSupervisor'] as String?,
    commentForwarder: json['commentForwarder'] as String?,
    commentAgent: json['commentAgent'] as String?,
    total: (json['total'] as num).toDouble(),
    clientCode: json['clientCode'] as String,
    clientName: json['clientName'] as String,
    codeOrg: json['codeOrg'] as String,
    mainStatus: json['mainStatus'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'numOrder': numOrder,
    'dateOrder': dateOrder.toIso8601String(),
    'captionOrder': captionOrder,
    'typePriceCode': typePriceCode,
    'status': status,
    'commentSupervisor': commentSupervisor,
    'commentForwarder': commentForwarder,
    'commentAgent': commentAgent,
    'total': total,
    'clientCode': clientCode,
    'clientName': clientName,
    'codeOrg': codeOrg,
    'mainStatus': mainStatus,
  };

  // Copy and equality methods
  Order copyWith({
    int? id,
    String? numOrder,
    DateTime? dateOrder,
    String? captionOrder,
    String? typePriceCode,
    int? status,
    String? commentSupervisor,
    String? commentForwarder,
    String? commentAgent,
    double? total,
    String? clientCode,
    String? clientName,
    String? codeOrg,
    String? mainStatus,
  }) => Order(
    id: id ?? this.id,
    numOrder: numOrder ?? this.numOrder,
    dateOrder: dateOrder ?? this.dateOrder,
    captionOrder: captionOrder ?? this.captionOrder,
    typePriceCode: typePriceCode ?? this.typePriceCode,
    status: status ?? this.status,
    commentSupervisor: commentSupervisor ?? this.commentSupervisor,
    commentForwarder: commentForwarder ?? this.commentForwarder,
    commentAgent: commentAgent ?? this.commentAgent,
    total: total ?? this.total,
    clientCode: clientCode ?? this.clientCode,
    clientName: clientName ?? this.clientName,
    codeOrg: codeOrg ?? this.codeOrg,
    mainStatus: mainStatus ?? this.mainStatus,
  );

  @override
  bool operator ==(Object other) => identical(this, other) ||
    (other is Order &&
     other.id == id &&
     other.numOrder == numOrder &&
     other.dateOrder == dateOrder &&
     other.captionOrder == captionOrder &&
     other.typePriceCode == typePriceCode &&
     other.status == status &&
     other.commentSupervisor == commentSupervisor &&
     other.commentForwarder == commentForwarder &&
     other.commentAgent == commentAgent &&
     other.total == total &&
     other.clientCode == clientCode &&
     other.clientName == clientName &&
     other.codeOrg == codeOrg &&
     other.mainStatus == mainStatus);

  @override
  int get hashCode => Object.hashAll([
    id, numOrder, dateOrder, captionOrder, typePriceCode, status,
    commentSupervisor, commentForwarder, commentAgent, total,
    clientCode, clientName, codeOrg, mainStatus
  ]);

  @override
  String toString() => 'Order(id: $id, numOrder: $numOrder, total: $total, mainStatus: $mainStatus)';
}
```

## Service Implementation

### SoapApiService Extensions
Added methods for SOAP API calls:
- `getOrderStatusList()`: Fetches order status messages
- `getOrderList()`: Fetches detailed order information

### ApiDatabaseService Extensions
Added CRUD operations:
- `saveOrderStatuses()`: Bulk insert/update order statuses
- `getOrderStatuses()`: Retrieve all order statuses
- `getOrderStatusByMessage()`: Find status by message
- `saveOrders()`: Bulk insert/update orders
- `getOrders()`: Retrieve orders with optional filtering
- `getOrderByNumOrder()`: Find order by order number
- `updateOrderStatus()`: Update order status
- `deleteOrder()`: Delete order by number

### DataSyncService Extensions
Added synchronization methods:
- `syncOrderStatuses()`: Sync order statuses with caching
- `syncOrders()`: Sync orders with caching
- `getCachedOrderStatuses()`: Get cached statuses
- `getCachedOrders()`: Get cached orders with filtering
- `getCachedOrderByNumOrder()`: Get cached order by number
- `updateCachedOrderStatus()`: Update cached order status
- `deleteCachedOrder()`: Delete cached order

## Testing

### Unit Tests
- **OrderStatus Model Tests**: JSON serialization, copyWith, equality
- **Order Model Tests**: JSON serialization, copyWith, equality

### Integration Tests
- **OrderStatus Database Tests**: CRUD operations, duplicate handling
- **Order Database Tests**: CRUD operations, filtering, status updates

### Test Coverage
- Model serialization/deserialization
- Database operations (create, read, update, delete)
- Error handling
- Edge cases (duplicates, null values, filtering)

## Best Practices Implemented

### Code Quality
- **Clean Code**: Descriptive variable names, clear method signatures
- **SOLID Principles**: Single responsibility, dependency injection
- **Error Handling**: Try-catch blocks, proper exception throwing
- **Async/Await**: Proper asynchronous programming
- **Null Safety**: Comprehensive null checking

### Database Design
- **Foreign Keys**: Proper relationships with cascade rules
- **Indexes**: Performance optimization for queries
- **Unique Constraints**: Data integrity
- **Batch Operations**: Efficient bulk inserts/updates

### API Integration
- **SOAP Parsing**: XML parsing with error handling
- **Retry Logic**: Network failure recovery
- **Caching**: Reduce API calls with local storage
- **Progress Updates**: User feedback during sync operations

## Usage Examples

### Sync Order Data
```dart
final dataSyncService = sl<DataSyncService>();

// Sync order statuses
final statuses = await dataSyncService.syncOrderStatuses(userCode: '000000329');

// Sync orders
final orders = await dataSyncService.syncOrders(userCode: '000000329');

// Get cached data
final cachedOrders = await dataSyncService.getCachedOrders();
final cachedStatuses = await dataSyncService.getCachedOrderStatuses();
```

### Database Operations
```dart
final dbService = sl<ApiDatabaseService>();

// Save orders
await dbService.saveOrders(orderList);

// Query with filters
final clientOrders = await dbService.getOrders(clientCode: '00-00054499');
final pendingOrders = await dbService.getOrders(mainStatus: 'Доставлено и ожидает оплаты');

// Update order status
await dbService.updateOrderStatus('GL00-154855', 'Доставлено и оплачено');
```

## Performance Considerations

### Database Optimization
- Batch operations for bulk inserts
- Proper indexing for query performance
- Connection pooling (handled by Sqflite)

### Memory Management
- Efficient XML parsing
- Streaming for large datasets
- Proper disposal of resources

### Network Optimization
- Caching to reduce API calls
- Retry mechanisms for reliability
- Progress tracking for user experience

## Future Enhancements

### Potential Improvements
- **Pagination**: For large order lists
- **Real-time Updates**: WebSocket integration for live status updates
- **Offline Mode**: Enhanced offline capabilities
- **Search**: Full-text search across orders
- **Analytics**: Order statistics and reporting

### Monitoring
- API response time tracking
- Database query performance
- Error rate monitoring
- User interaction analytics

## Conclusion

The order management implementation provides a robust, scalable solution for handling order data in the Gloria Marketing application. It follows Flutter and Dart best practices, implements proper error handling, and includes comprehensive testing. The modular architecture allows for easy maintenance and future enhancements.