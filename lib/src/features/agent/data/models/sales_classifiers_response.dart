import 'sales_channel.dart';
import 'trading_point_type.dart';
import 'client_class.dart';

/// Sales Classifiers Response Model
/// Aggregates all classifier data from getSalesClassifiersList SOAP response
/// Contains channels, trading point types, and client classes
class SalesClassifiersResponse {
  /// List of sales channels (kanal prodaja)
  final List<SalesChannel> channels;
  
  /// List of trading point types (tip torgoviy tochka)
  final List<TradingPointType> tradingPointTypes;
  
  /// List of client classes (class torgoviy tochka)
  final List<ClientClass> clientClasses;

  const SalesClassifiersResponse({
    required this.channels,
    required this.tradingPointTypes,
    required this.clientClasses,
  });

  /// Create empty response
  factory SalesClassifiersResponse.empty() {
    return const SalesClassifiersResponse(
      channels: [],
      tradingPointTypes: [],
      clientClasses: [],
    );
  }

  /// Check if response has any data
  bool get isEmpty => 
      channels.isEmpty && 
      tradingPointTypes.isEmpty && 
      clientClasses.isEmpty;

  /// Check if response has all required data
  bool get isComplete => 
      channels.isNotEmpty && 
      tradingPointTypes.isNotEmpty && 
      clientClasses.isNotEmpty;

  /// Get trading point types filtered by channel
  /// Used for cascading dropdown functionality
  List<TradingPointType> getTypesForChannel(String channelName) {
    return tradingPointTypes
        .where((type) => type.channelGroup == channelName)
        .toList();
  }

  /// Get all unique channel names
  List<String> get channelNames => 
      channels.map((c) => c.name).toList();

  @override
  String toString() {
    return 'SalesClassifiersResponse('
        'channels: ${channels.length}, '
        'tradingPointTypes: ${tradingPointTypes.length}, '
        'clientClasses: ${clientClasses.length})';
  }
}
