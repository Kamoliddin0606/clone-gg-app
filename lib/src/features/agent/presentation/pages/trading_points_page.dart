import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart' as model;
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/agent_repository.dart';

class TradingPointsPage extends StatefulWidget {
  const TradingPointsPage({super.key});

  @override
  State<TradingPointsPage> createState() => _TradingPointsPageState();
}

class _TradingPointsPageState extends State<TradingPointsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<TradingPoint> _allTradingPoints = [];
  List<TradingPoint> _filteredTradingPoints = [];
  bool _isLoading = true;
  String userCode = "";
  String password = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      await sl.isReady<SharedPreferencesService>();
      final prefs = sl<SharedPreferencesService>();
      
      setState(() {
        userCode = prefs.getUserCode() ?? "";
        password = prefs.getPassword() ?? "";
      });
      
      if (userCode.isNotEmpty && password.isNotEmpty) {
        _loadTradingPoints();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTradingPoints() async {
    if (userCode.isEmpty || password.isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final repository = sl<AgentRepository>();
      final tradingPoints = await repository.getClients(
        userCode: userCode,
        password: password,
      );
      
      _allTradingPoints = tradingPoints;

      _filteredTradingPoints = List.from(_allTradingPoints);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mijozlar ma\'lumotlarini yuklashda xatolik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterTradingPoints(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTradingPoints = List.from(_allTradingPoints);
      } else {
        _filteredTradingPoints = _allTradingPoints
            .where((tp) =>
                tp.name.toLowerCase().contains(query.toLowerCase()) ||
                tp.address.toLowerCase().contains(query.toLowerCase()) ||
                tp.contactPerson.toLowerCase().contains(query.toLowerCase()) ||
                tp.ownerName.toLowerCase().contains(query.toLowerCase()) ||
                tp.inn.contains(query))
            .toList();
      }
    });
  }

  Future<void> _makeCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Telefon raqami ko\'rsatilmagan')),
      );
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Telefon qo\'ng\'irog\'i amalga oshirilmadi')),
        );
      }
    }
  }

  Future<void> _informVisit(TradingPoint tradingPoint) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Tashrif haqida xabar berilmoqda...'),
          ],
        ),
      ),
    );

    // TODO: Send visit notification to server
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.of(context).pop(); // Close loading dialog
      
      // Update visit status
      setState(() {
        final index = _allTradingPoints.indexWhere((tp) => tp.id == tradingPoint.id);
        if (index != -1) {
          _allTradingPoints[index] = tradingPoint.copyWith(isVisited: true);
          _filterTradingPoints(_searchController.text);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${tradingPoint.name} ga tashrif haqida xabar berildi'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _createOrder(TradingPoint tradingPoint) {
    // TODO: Navigate to order creation page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${tradingPoint.name} uchun buyurtma yaratish')),
    );
  }

  void _viewContracts(TradingPoint tradingPoint) {
    // TODO: Navigate to contracts page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${tradingPoint.name} shartnomalarini ko\'rish')),
    );
  }

  void _showRefusalDialog(TradingPoint tradingPoint) {
    showDialog(
      context: context,
      builder: (context) => RefusalDialog(
        tradingPoint: tradingPoint,
        onRefusalSent: (reason) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${tradingPoint.name} uchun rad etish sababi yuborildi: $reason'),
              backgroundColor: Colors.orange,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savdo nuqtalari'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'orders':
                  // TODO: Navigate to created orders
                  break;
                case 'new_client':
                  // TODO: Navigate to new trading point creation
                  break;
                case 'orders_history':
                  // TODO: Navigate to orders history
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'orders',
                child: Row(
                  children: [
                    Icon(Icons.shopping_cart),
                    SizedBox(width: 8),
                    Text('Buyurtmalar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'new_client',
                child: Row(
                  children: [
                    Icon(Icons.add_business),
                    SizedBox(width: 8),
                    Text('Yangi mijoz'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'orders_history',
                child: Row(
                  children: [
                    Icon(Icons.history),
                    SizedBox(width: 8),
                    Text('Buyurtmalar tarixi'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Qidirish...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterTradingPoints,
            ),
          ),
          // Trading points list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTradingPoints.isEmpty
                    ? const Center(
                        child: Text(
                          'Savdo nuqtalari topilmadi',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await _loadUserData();
                        },
                        child: ListView.builder(
                          itemCount: _filteredTradingPoints.length,
                          itemBuilder: (context, index) {
                            final tradingPoint = _filteredTradingPoints[index];
                            return TradingPointCard(
                              tradingPoint: tradingPoint,
                              onCall: () => _makeCall(tradingPoint.phone),
                              onInformVisit: () => _informVisit(tradingPoint),
                              onCreateOrder: () => _createOrder(tradingPoint),
                              onViewContracts: () => _viewContracts(tradingPoint),
                              onRefusal: () => _showRefusalDialog(tradingPoint),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// Using TradingPoint model from separate file
typedef TradingPoint = model.TradingPoint;

class TradingPointCard extends StatelessWidget {
  final TradingPoint tradingPoint;
  final VoidCallback onCall;
  final VoidCallback onInformVisit;
  final VoidCallback onCreateOrder;
  final VoidCallback onViewContracts;
  final VoidCallback onRefusal;

  const TradingPointCard({
    super.key,
    required this.tradingPoint,
    required this.onCall,
    required this.onInformVisit,
    required this.onCreateOrder,
    required this.onViewContracts,
    required this.onRefusal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: tradingPoint.isVisited ? Colors.green : Colors.orange,
          child: Icon(
            tradingPoint.isVisited ? Icons.check : Icons.location_on,
            color: Colors.white,
          ),
        ),
        title: Text(
          tradingPoint.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tradingPoint.address),
            Text('INN: ${tradingPoint.inn}'),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, size: 16),
                    const SizedBox(width: 8),
                    Text('Aloqa: ${tradingPoint.contactPerson}'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 16),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onCall,
                      child: Text(
                        tradingPoint.phone,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Action buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (!tradingPoint.isVisited)
                      ElevatedButton.icon(
                        onPressed: onInformVisit,
                        icon: const Icon(Icons.location_on, size: 16),
                        label: const Text('Tashrif'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ElevatedButton.icon(
                      onPressed: onCreateOrder,
                      icon: const Icon(Icons.shopping_cart, size: 16),
                      label: const Text('Buyurtma'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    if (tradingPoint.hasContract)
                      ElevatedButton.icon(
                        onPressed: onViewContracts,
                        icon: const Icon(Icons.description, size: 16),
                        label: const Text('Shartnoma'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ElevatedButton.icon(
                      onPressed: onRefusal,
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Rad etish'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RefusalDialog extends StatefulWidget {
  final TradingPoint tradingPoint;
  final Function(String) onRefusalSent;

  const RefusalDialog({
    super.key,
    required this.tradingPoint,
    required this.onRefusalSent,
  });

  @override
  State<RefusalDialog> createState() => _RefusalDialogState();
}

class _RefusalDialogState extends State<RefusalDialog> {
  String? _selectedReason;
  bool _isLoading = false;

  final List<String> _refusalReasons = [
    'Mijoz yo\'q',
    'Vaqt yo\'q',
    'Mahsulot kerak emas',
    'Narx mos kelmaydi',
    'Boshqa ta\'minotchi bilan ishlaydi',
    'Boshqa sabab',
  ];

  Future<void> _sendRefusal() async {
    if (_selectedReason == null) return;

    setState(() {
      _isLoading = true;
    });

    // TODO: Send refusal to server
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.of(context).pop();
      widget.onRefusalSent(_selectedReason!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rad etish sababi'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${widget.tradingPoint.name} uchun rad etish sababini tanlang:'),
          const SizedBox(height: 16),
          ..._refusalReasons.map((reason) => RadioListTile<String>(
                title: Text(reason),
                value: reason,
                groupValue: _selectedReason,
                onChanged: (value) {
                  setState(() {
                    _selectedReason = value;
                  });
                },
              )),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Bekor qilish'),
        ),
        FilledButton(
          onPressed: _isLoading || _selectedReason == null ? null : _sendRefusal,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Yuborish'),
        ),
      ],
    );
  }
}