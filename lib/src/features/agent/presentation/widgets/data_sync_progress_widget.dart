import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_exceptions.dart';

enum SyncStep {
  checkingUser('Foydalanuvchi tekshirilmoqda...', Icons.person_search),
  clearingData('Eski ma\'lumotlar tozalanmoqda...', Icons.cleaning_services),
  syncingKpi('KPI ma\'lumotlari yuklanmoqda...', Icons.bar_chart),
  syncingClients('Mijozlar ro\'yxati yuklanmoqda...', Icons.people),
  syncingProducts('Mahsulotlar yuklanmoqda...', Icons.inventory),
  syncingPriceTypes('Narx turlari yuklanmoqda...', Icons.price_change),
  syncingBusinessRegions('Biznes rayonlari yuklanmoqda...', Icons.location_on),
  syncingUserWarehouses('Foydalanuvchi omborlari yuklanmoqda...', Icons.warehouse),
  syncingProductPrices('Mahsulot narxlari yuklanmoqda...', Icons.attach_money),
  syncingProductBalances('Mahsulot balanslari yuklanmoqda...', Icons.balance),
  syncingClientContracts('Mijoz shartnomalari yuklanmoqda...', Icons.description),
  syncingOrderStatuses('Buyurtma statuslari yuklanmoqda...', Icons.list_alt),
  syncingOrders('Buyurtmalar yuklanmoqda...', Icons.shopping_cart),
  syncingSalesReqPermissions('Agent ruxsatlari yuklanmoqda...', Icons.security),
  syncingPromotions('Aksiyalar yuklanmoqda...', Icons.local_offer),
  syncingReports('Hisobotlar yuklanmoqda...', Icons.analytics),
  completed('Ma\'lumotlar yangilandi!', Icons.check_circle),
  error('Xatolik yuz berdi', Icons.error);

  const SyncStep(this.message, this.icon);
  final String message;
  final IconData icon;
}

class DataSyncProgressWidget extends StatefulWidget {
  final Stream<SyncStep> syncStepStream;
  final VoidCallback onComplete;
  final Function(dynamic error)? onError;

  const DataSyncProgressWidget({
    super.key,
    required this.syncStepStream,
    required this.onComplete,
    this.onError,
  });

  @override
  State<DataSyncProgressWidget> createState() => _DataSyncProgressWidgetState();
}

class _DataSyncProgressWidgetState extends State<DataSyncProgressWidget> {
  SyncStep _currentStep = SyncStep.checkingUser;
  double _progress = 0.0;
  String? _errorMessage;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    widget.syncStepStream.listen(
      (step) {
        setState(() {
          _currentStep = step;
          _progress = (SyncStep.values.indexOf(step) + 1) / SyncStep.values.length;
          _hasError = false;
          _errorMessage = null;
        });

        if (step == SyncStep.completed) {
          Future.delayed(const Duration(seconds: 1), widget.onComplete);
        }
      },
      onError: (error) {
        setState(() {
          _currentStep = SyncStep.error;
          _progress = 1.0;
          _hasError = true;
          _errorMessage = _getErrorMessage(error);
        });

        // Call the error callback if provided
        widget.onError?.call(error);

        // Auto-complete after showing error for 3 seconds
        Future.delayed(const Duration(seconds: 3), widget.onComplete);
      },
    );
  }

  String _getErrorMessage(dynamic error) {
    if (error is PaymentRequiredException) {
      return 'To\'lov talab qilinmoqda. Iltimos, obunangizni tekshiring.';
    } else if (error is AuthenticationException) {
      return 'Autentifikatsiya xatosi. Iltimos, qayta kiring.';
    } else if (error is ForbiddenException) {
      return 'Kirish taqiqlangan. Sizda ruxsat yo\'q.';
    } else if (error is NotFoundException) {
      return 'Xizmat topilmadi. Iltimos, qo\'llab-quvvatlashga murojaat qiling.';
    } else if (error is ServerUnavailableException) {
      return 'Server mavjud emas. Iltimos, keyinroq urinib ko\'ring.';
    } else {
      return 'Ma\'lumotlarni yangilashda xatolik yuz berdi. Kesh ma\'lumotlaridan foydalaniladi.';
    }
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