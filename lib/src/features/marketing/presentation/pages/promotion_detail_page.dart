import 'package:flutter/material.dart';

class PromotionDetailPage extends StatelessWidget {
  const PromotionDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promotion Detail'),
      ),
      body: const Center(
        child: Text('Promotion Detail Page'),
      ),
    );
  }
}