/// ============================================================================
/// Client Balance Widget
/// ============================================================================
/// Bu widget mijoz balansi ma'lumotlarini ko'rsatish uchun ishlatiladi.
/// Trading points page'da mijoz detail oynasida birinchi tabda ko'rsatiladi.
/// 
/// Asosiy funksiyalar:
/// - Balans holatini ko'rsatish (qarzdor yoki ortiqcha to'lov)
/// - 10 soniyalik yangilash cooldown bilan countdown
/// - Balans detallari sahifasiga o'tish
/// ============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/client_balance.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';
import 'package:gloria_marketing_flutter/src/core/services/client_balance_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/project_context.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/client_balance_details_page.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';

/// ============================================================================
/// ClientBalanceWidget - Mijoz balansi widgeti
/// ============================================================================
/// Trading points detail sahifasida mijoz balansini ko'rsatadi.
/// Balans ma'lumotlari avtomatik yangilanadi (internet mavjud bo'lsa).
class ClientBalanceWidget extends StatefulWidget {
  /// Mijoz ma'lumotlari (INN olish uchun)
  final TradingPoint tradingPoint;

  const ClientBalanceWidget({
    super.key,
    required this.tradingPoint,
  });

  @override
  State<ClientBalanceWidget> createState() => _ClientBalanceWidgetState();
}

class _ClientBalanceWidgetState extends State<ClientBalanceWidget> {
  /// Client balance service instance
  ClientBalanceService? _balanceService;

  /// Joriy balans ma'lumotlari
  ClientBalance? _balance;
  
  /// Yuklanish holati
  bool _isLoading = true;
  
  /// Xatolik xabari
  String? _errorMessage;
  
  /// Yangilash countdown timer
  Timer? _countdownTimer;
  
  /// Qolgan soniyalar
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// Service'larni ishga tushirish
  Future<void> _initializeServices() async {
    try {
      if (sl.isRegistered<ClientBalanceService>()) {
        _balanceService = sl<ClientBalanceService>();
      }

      // Dastlabki balansni yuklash
      await _loadBalance();
    } catch (e) {
      if (kDebugMode) {
        print('ClientBalanceWidget: Error initializing services: $e');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = AppLocalizations.of(context)?.serviceInitError ?? 'Error initializing services';
        });
      }
    }
  }

  /// Balansni yuklash (keshdan yoki API'dan)
  Future<void> _loadBalance() async {
    if (_balanceService == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = AppLocalizations.of(context)?.balanceServiceNotAvailable ?? 'Balance service not available';
      });
      return;
    }

    final inn = widget.tradingPoint.inn;
    if (inn.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = AppLocalizations.of(context)?.clientInnNotAvailable ?? 'Client INN not available';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Avval keshdan olish
      final cachedBalance = _balanceService!.getClientBalanceFromCache(inn);
      if (cachedBalance != null) {
        setState(() {
          _balance = cachedBalance;
          _isLoading = false;
        });
        _updateCountdown();
      }

      // API'dan yangilash (agar cooldown tugagan bo'lsa)
      if (_balanceService!.canRefresh(inn)) {
        final projectCode = _resolveProjectCode();
        if (projectCode == null) {
          // No active project — fall back to whatever the DB has cached.
          final dbBalance = await _balanceService!.getClientBalanceFromDb(inn);
          if (mounted) {
            setState(() {
              _balance = dbBalance;
              _isLoading = false;
            });
          }
          return;
        }

        final newBalance = await _balanceService!.fetchClientBalance(
          code1c: widget.tradingPoint.code1c,
          projectCode: projectCode,
          inn: inn,
        );

        if (mounted && newBalance != null) {
          setState(() {
            _balance = newBalance;
            _isLoading = false;
          });
          _startCountdown();
        }
      } else {
        // Keshdan o'qish
        if (_balance == null) {
          final dbBalance = await _balanceService!.getClientBalanceFromDb(inn);
          if (mounted) {
            setState(() {
              _balance = dbBalance;
              _isLoading = false;
            });
          }
        }
        _updateCountdown();
      }
    } catch (e) {
      if (kDebugMode) {
        print('ClientBalanceWidget: Error loading balance: $e');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = AppLocalizations.of(context)?.balanceLoadError ?? 'Error loading balance';
        });
      }
    }
  }

  /// Active project code from [ProjectContext]. The new REST balance proxy
  /// (`/api/mobile/v2/customers/balance/`, Passport §2) needs `project_code`
  /// = `UserProject.code`. Returns `null` when no project is active so the
  /// caller can degrade gracefully without firing a request that would 400.
  String? _resolveProjectCode() {
    if (!sl.isRegistered<ProjectContext>()) return null;
    return sl<ProjectContext>().activeProject?.code;
  }

  /// Countdown timerni boshlash
  void _startCountdown() {
    _countdownTimer?.cancel();
    _remainingSeconds = ClientBalanceService.refreshCooldownSeconds;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });
        if (_remainingSeconds <= 0) {
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
  }

  /// Countdown'ni yangilash (mavjud vaqtga qarab)
  void _updateCountdown() {
    if (_balanceService == null) return;
    
    final inn = widget.tradingPoint.inn;
    final remaining = _balanceService!.getSecondsUntilRefresh(inn);
    
    if (remaining > 0) {
      _countdownTimer?.cancel();
      _remainingSeconds = remaining;

      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
          });
          if (_remainingSeconds <= 0) {
            timer.cancel();
          }
        } else {
          timer.cancel();
        }
      });
    }
  }

  /// Yangilash tugmasi bosilganda
  Future<void> _onRefresh() async {
    if (_balanceService == null) return;
    
    final inn = widget.tradingPoint.inn;
    if (!_balanceService!.canRefresh(inn)) {
      // Cooldown hali tugamagan
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.refreshAfterSeconds(_remainingSeconds)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    await _loadBalance();
  }

  /// Balans info icon bosilganda
  void _showBalanceInfo() {
    if (_balance == null) return;

    final isDebtor = _balance!.isDebtor;
    final l10n = AppLocalizations.of(context);
    final message = isDebtor
        ? l10n?.clientIsDebtor(_formatCurrency(_balance!.absoluteBalance)) ?? 'Client is debtor. Total debt: ${_formatCurrency(_balance!.absoluteBalance)} sum'
        : _balance!.hasOverpayment
            ? l10n?.clientHasOverpayment(_formatCurrency(_balance!.absoluteBalance)) ?? 'Client has overpaid. Overpayment: ${_formatCurrency(_balance!.absoluteBalance)} sum'
            : l10n?.clientBalanceZero ?? 'Client balance is zero.';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isDebtor ? Icons.warning_amber_rounded : Icons.info_outline,
              color: isDebtor ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)?.balanceStatusTitle ?? 'Balans holati'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)?.close ?? 'Yopish'),
          ),
        ],
      ),
    );
  }

  /// Balans detallari sahifasini ochish
  void _openBalanceDetails() {
    if (_balance == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientBalanceDetailsPage(
          tradingPoint: widget.tradingPoint,
          balance: _balance!,
        ),
      ),
    );
  }

  /// Summa formatlash
  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'uz_UZ');
    return formatter.format(amount.abs());
  }

  /// Sana formatlash
  String _formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('dd.MM.yyyy HH:mm', 'uz_UZ');
    return formatter.format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: "Mijoz balansi" va info icon
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 20,
                color: cs.primary,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)?.clientBalance ?? 'Client balance',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              // Animated info icon
              _buildInfoIcon(cs),
              const Spacer(),
              // Refresh button with countdown
              _buildRefreshButton(cs),
            ],
          ),

          const SizedBox(height: 8),

          // Content
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_errorMessage != null)
            _buildErrorWidget(cs)
          else if (_balance != null)
            _buildBalanceContent(theme, cs)
          else
            _buildNoDataWidget(cs),
        ],
      ),
    );
  }

  /// Animated info icon
  Widget _buildInfoIcon(ColorScheme cs) {
    final hasBalance = _balance != null;
    final isDebtor = _balance?.isDebtor ?? false;

    return GestureDetector(
      onTap: hasBalance ? _showBalanceInfo : null,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: hasBalance
              ? (isDebtor ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1))
              : cs.surfaceContainerHighest,
          boxShadow: hasBalance
              ? [
                  BoxShadow(
                    color: (isDebtor ? Colors.red : Colors.green).withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Icon(
          Icons.info_outline,
          size: 16,
          color: hasBalance
              ? (isDebtor ? Colors.red : Colors.green)
              : cs.outline,
        ),
      ),
    );
  }

  /// Refresh button with countdown
  Widget _buildRefreshButton(ColorScheme cs) {
    final canRefresh = _remainingSeconds <= 0;

    return InkWell(
      onTap: canRefresh ? _onRefresh : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: canRefresh ? cs.primary : cs.outline.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.refresh,
              size: 16,
              color: canRefresh ? cs.primary : cs.outline,
            ),
            if (!canRefresh) ...[
              const SizedBox(width: 4),
              Text(
                '${_remainingSeconds}s',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.outline,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Error widget
  Widget _buildErrorWidget(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage ?? AppLocalizations.of(context)?.errorOccurredTitle ?? 'Error occurred',
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: _loadBalance,
            child: Text(AppLocalizations.of(context)?.retry ?? 'Qayta urinish'),
          ),
        ],
      ),
    );
  }

  /// No data widget
  Widget _buildNoDataWidget(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: cs.outline, size: 20),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context)?.balanceDataNotFound ?? 'Balance data not found',
            style: TextStyle(color: cs.outline, fontSize: 13),
          ),
        ],
      ),
    );
  }

  /// Balance content
  Widget _buildBalanceContent(ThemeData theme, ColorScheme cs) {
    final balance = _balance!;
    final isDebtor = balance.isDebtor;
    final hasOverpayment = balance.hasOverpayment;

    // Rang tanlash
    final balanceColor = isDebtor
        ? Colors.red
        : hasOverpayment
            ? Colors.green
            : cs.onSurface;

    return InkWell(
      onTap: _openBalanceDetails,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Yangilash vaqti
          Row(
            children: [
              Icon(Icons.update, size: 14, color: cs.outline),
              const SizedBox(width: 4),
              Text(
                AppLocalizations.of(context)?.updatedAtTime(_formatDateTime(balance.lastUpdated)) ?? 'Updated: ${_formatDateTime(balance.lastUpdated)}',
                style: TextStyle(
                  fontSize: 11,
                  color: cs.outline,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Balans holati va summa
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Holat xabari
                    Text(
                      isDebtor
                          ? AppLocalizations.of(context)?.clientDebtorStatus ?? 'Client is debtor'
                          : hasOverpayment
                              ? AppLocalizations.of(context)?.overpaymentStatus ?? 'Overpayment'
                              : AppLocalizations.of(context)?.balanceZeroStatus ?? 'Balance is zero',
                      style: TextStyle(
                        fontSize: 13,
                        color: balanceColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Summa
                    Text(
                      '${isDebtor ? '-' : hasOverpayment ? '+' : ''}${_formatCurrency(balance.absoluteBalance)} so\'m',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: balanceColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow icon
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: cs.outline,
              ),
            ],
          ),

          // Qo'shimcha ma'lumotlar
          if (balance.unpaidOrdersCount > 0 || balance.overdueOrdersCount > 0) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                if (balance.unpaidOrdersCount > 0) ...[
                  _buildInfoChip(
                    icon: Icons.pending_outlined,
                    label: AppLocalizations.of(context)?.unpaidOrders(balance.unpaidOrdersCount) ?? '${balance.unpaidOrdersCount} unpaid',
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                ],
                if (balance.overdueOrdersCount > 0)
                  _buildInfoChip(
                    icon: Icons.warning_amber_rounded,
                    label: AppLocalizations.of(context)?.overdueOrders(balance.overdueOrdersCount) ?? '${balance.overdueOrdersCount} overdue',
                    color: Colors.red,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Info chip widget
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
