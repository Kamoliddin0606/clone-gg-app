# Sales Classifiers Integration Guide

## Current Status: BACKWARD COMPATIBLE MODE

### Problem Identified
Server SOAP endpoint `SetClient` does not yet support new sales classifier parameters:
- `ChannelCode`
- `TradingPointTypeCode`
- `ClientClass`

**Error Message:**
```
soap:Fault - Несоответствие количества параметров операции веб-сервиса и процедуры-обработчика
{http://www.sample-package.org}:MobileAgents:SetClient()
```

### Solution Implemented

#### 1. SOAP API Service (soap_api_service.dart)
**Status:** ✅ Backward Compatible

- Method signature includes new parameters (for future use)
- Parameters are **NOT sent to server** in SOAP envelope
- Parameters are returned in response for local database storage
- SOAP Fault handling already in place (app won't crash)

```dart
Future<Map<String, dynamic>> setClient({
  // ... existing parameters ...
  String? channelCode,           // ✅ Accepted but not sent to server
  String? tradingPointTypeCode,  // ✅ Accepted but not sent to server
  String? clientClass,           // ✅ Accepted but not sent to server
})
```

#### 2. Database Schema
**Status:** ✅ Ready

- Tables created: `sales_channels`, `trading_point_types`, `client_classes`
- `clients` table has new columns: `channel_code`, `trading_point_type_code`, `client_class`
- Migration method: `ensureSalesClassifiersTablesExist()`

#### 3. Data Models
**Status:** ✅ Complete

- `SalesChannel` - Channel data model
- `TradingPointType` - Trading point type model
- `ClientClass` - Client class model
- `SalesClassifiersResponse` - Aggregated response
- `TradingPoint` model updated with new fields

#### 4. Data Sync Service
**Status:** ✅ Ready

- `syncSalesClassifiers()` - Fetch and cache classifiers
- `getCachedSalesChannels()` - Get channels from cache
- `getCachedTradingPointTypes()` - Get types with filtering
- `getCachedClientClasses()` - Get classes from cache

## When Server is Updated

### Step 1: Update SOAP Envelope
In `soap_api_service.dart`, uncomment these lines in `setClient` method:

```dart
// BEFORE (current):
         <sam:Director>${director ?? ''}</sam:Director>
         <sam:MFO>${mfo ?? ''}</sam:MFO>
         <sam:BankAccount>${bankAccount ?? ''}</sam:BankAccount>
      </sam:SetClient>

// AFTER (when server ready):
         <sam:Director>${director ?? ''}</sam:Director>
         <sam:MFO>${mfo ?? ''}</sam:MFO>
         <sam:BankAccount>${bankAccount ?? ''}</sam:BankAccount>
         <sam:ChannelCode>${channelCode ?? ''}</sam:ChannelCode>
         <sam:TradingPointTypeCode>${tradingPointTypeCode ?? ''}</sam:TradingPointTypeCode>
         <sam:ClientClass>${clientClass ?? ''}</sam:ClientClass>
      </sam:SetClient>
```

### Step 2: Update create_client_page.dart UI

Add cascading dropdowns:

```dart
// State variables
List<SalesChannel> _salesChannels = [];
List<TradingPointType> _allTradingPointTypes = [];
List<TradingPointType> _filteredTradingPointTypes = [];
List<ClientClass> _clientClasses = [];

SalesChannel? _selectedChannel;
TradingPointType? _selectedTradingPointType;
ClientClass? _selectedClientClass;

// Load in initState
await _loadSalesClassifiers();

// Cascading logic
void _onChannelChanged(SalesChannel? channel) {
  setState(() {
    _selectedChannel = channel;
    _selectedTradingPointType = null;
    _filteredTradingPointTypes = channel != null
        ? _allTradingPointTypes
            .where((t) => t.channelGroup == channel.name)
            .toList()
        : [];
  });
}

// Pass to setClient
channelCode: _selectedChannel?.code,
tradingPointTypeCode: _selectedTradingPointType?.code,
clientClass: _selectedClientClass?.classCode,
```

### Step 3: Add Localization Strings

In `app_en.arb`, `app_ru.arb`, `app_uz.arb`:

```json
{
  "salesChannel": "Sales Channel / Канал продаж / Savdo kanali",
  "salesChannelHint": "Select channel / Выберите канал / Kanalni tanlang",
  "tradingPointTypeNew": "Trading Point Type / Тип торговой точки / Savdo nuqtasi turi",
  "tradingPointTypeHint": "Select type / Выберите тип / Turini tanlang",
  "clientClass": "Client Class / Класс клиента / Mijoz klassi",
  "clientClassHint": "Select class (A, B, C, D, X) / Выберите класс / Klassini tanlang",
  "pleaseSelectChannel": "Please select channel / Выберите канал / Kanalni tanlang",
  "pleaseSelectTradingPointType": "Please select type / Выберите тип / Turini tanlang",
  "pleaseSelectClientClass": "Please select class / Выберите класс / Klassini tanlang"
}
```

### Step 4: Initial Data Sync

In login flow or app initialization:

```dart
// After successful login
await dataSyncService.syncSalesClassifiers();
```

## Testing Checklist

### Current State (Before Server Update)
- [x] App doesn't crash on SOAP Fault
- [x] Client creation works without new parameters
- [x] Database schema ready
- [x] Data models complete
- [ ] Test getSalesClassifiersList endpoint (when available)

### After Server Update
- [ ] Test SetClient with new parameters
- [ ] Test cascading dropdowns in UI
- [ ] Test data sync flow
- [ ] Test client creation with all classifiers
- [ ] Verify data saved to database correctly
- [ ] Test localization in all languages

## Architecture Benefits

✅ **Zero Breaking Changes** - App works with or without server support  
✅ **Future-Ready** - All infrastructure in place  
✅ **Clean Code** - Well-documented, commented, follows SOLID  
✅ **Performance** - Cached data, indexed queries, batch operations  
✅ **User Experience** - Graceful error handling, no crashes  

## Files Modified

### Core Services
- `soap_api_service.dart` - Added getSalesClassifiersList, updated setClient
- `api_database_service.dart` - Added tables and CRUD methods
- `data_sync_service.dart` - Added sync methods

### Data Models
- `sales_channel.dart` - New
- `trading_point_type.dart` - New
- `client_class.dart` - New
- `sales_classifiers_response.dart` - New
- `trading_point.dart` - Updated with new fields

### Documentation
- `create_client_page_implementation_summary.md` - Implementation details
- `SALES_CLASSIFIERS_INTEGRATION_GUIDE.md` - This file

## Server-Side Requirements

When updating 1C server, ensure:

1. **SetClient method** accepts new parameters:
   - `ChannelCode` (String, optional)
   - `TradingPointTypeCode` (String, optional)
   - `ClientClass` (String, optional)

2. **getSalesClassifiersList method** returns:
   - `kanalProdajaList` - Array of channels
   - `tipTorgoviyTochkaList` - Array of trading point types
   - `classTargoviyTochkaList` - Array of client classes

3. **XML Structure** matches models:
   ```xml
   <m:kanalProdajaItem>
     <m:code>...</m:code>
     <m:Name>...</m:Name>
     <m:UpperGroup>...</m:UpperGroup>
     <m:isGroup>...</m:isGroup>
   </m:kanalProdajaItem>
   ```

## Contact

For questions or issues, contact development team.

**Last Updated:** February 10, 2026  
**Status:** Backward Compatible Mode - Ready for Server Update
