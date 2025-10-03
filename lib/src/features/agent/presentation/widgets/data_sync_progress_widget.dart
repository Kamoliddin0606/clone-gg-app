import 'package:flutter/material.dart';

enum SyncStep {
  checkingUser('Foydalanuvchi tekshirilmoqda...', Icons.person_search),
  clearingData('Eski ma\'lumotlar tozalanmoqda...', Icons.cleaning_services),
  syncingKpi('KPI ma\'lumotlari yuklanmoqda...', Icons.bar_chart),
  syncingClients('Mijozlar ro\'yxati yuklanmoqda...', Icons.people),
  syncingProducts('Mahsulotlar yuklanmoqda...', Icons.inventory),
  syncingPriceTypes('Narx turlari yuklanmoqda...', Icons.price_change),
  syncingProductPrices('Mahsulot narxlari yuklanmoqda...', Icons.attach_money),
  completed('Ma\'lumotlar yangilandi!', Icons.check_circle);

  const SyncStep(this.message, this.icon);
  final String message;
  final IconData icon;
}

class DataSyncProgressWidget extends StatefulWidget {
  final Stream<SyncStep> syncStepStream;
  final VoidCallback onComplete;

  const DataSyncProgressWidget({
    super.key,
    required this.syncStepStream,
    required this.onComplete,
  });

  @override
  State<DataSyncProgressWidget> createState() => _DataSyncProgressWidgetState();
}

class _DataSyncProgressWidgetState extends State<DataSyncProgressWidget> {
  SyncStep _currentStep = SyncStep.checkingUser;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    widget.syncStepStream.listen((step) {
      setState(() {
        _currentStep = step;
        _progress = (SyncStep.values.indexOf(step) + 1) / SyncStep.values.length;
      });

      if (step == SyncStep.completed) {
        Future.delayed(const Duration(seconds: 1), widget.onComplete);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _currentStep == SyncStep.completed
                  ? colorScheme.primaryContainer
                  : colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _currentStep.icon,
              size: 48,
              color: _currentStep == SyncStep.completed
                  ? colorScheme.primary
                  : colorScheme.primary,
            ),
          ),

          const SizedBox(height: 16),

          // Title
          Text(
            _currentStep == SyncStep.completed
                ? 'Muvaffaqiyatli!'
                : 'Ma\'lumotlar yangilanmoqda...',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Message
          Text(
            _currentStep.message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                _currentStep == SyncStep.completed
                    ? colorScheme.primary
                    : colorScheme.primary,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Progress Text
          Text(
            '${(_progress * 100).round()}%',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}