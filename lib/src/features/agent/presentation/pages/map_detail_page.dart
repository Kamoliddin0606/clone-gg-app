import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart' as model;

class MapDetailPage extends StatelessWidget {
  final model.TradingPoint tradingPoint;

  const MapDetailPage({
    super.key,
    required this.tradingPoint,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Detail'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'User: ${tradingPoint.name}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Client Coordinates: ${tradingPoint.latitude}, ${tradingPoint.longitude}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}