import 'package:flutter/material.dart';

import '../../../../core/services/service_locator.dart';
import '../../../agent/data/models/create_order.dart';
import '../../../agent/services/order_draft_service.dart';
import '../../legacy/order_create_payload_adapter.dart';
import 'task_context.dart';

/// `ORDER_CREATE` task host that bridges the legacy `OrderDraftService`
/// into the v2 envelope.
///
/// The draft itself is still produced by the historical Create-Order UI
/// (out of scope for this refactor — its product picker / pricing engine
/// is intricate). On entry we read the latest local draft for the task's
/// step code; on completion we run it through
/// [OrderCreatePayloadAdapter] and hand the v2-shaped payload to the
/// bloc. If no draft exists yet, we expose a skip + empty-finish path so
/// the agent can move on without an order.
class OrderCreatePage extends StatefulWidget {
  const OrderCreatePage({super.key, required this.ctx, this.stepCode = 4});

  final TaskContext ctx;

  /// Step code used in the legacy `visit_steps_data` table. Defaults to 4
  /// (`создать заказ`) because that's the historical SOAP value; new
  /// catalog entries can override it via `config.legacy_step_code`.
  final int stepCode;

  @override
  State<OrderCreatePage> createState() => _OrderCreatePageState();
}

class _OrderCreatePageState extends State<OrderCreatePage> {
  late Future<CreateOrder?> _draftFuture;

  @override
  void initState() {
    super.initState();
    _draftFuture = _loadDraft();
  }

  Future<CreateOrder?> _loadDraft() async {
    if (!sl.isRegistered<OrderDraftService>()) return null;
    final step = (widget.ctx.config['legacy_step_code'] as int?) ?? widget.stepCode;
    final raw = await sl<OrderDraftService>().loadOrderDraft(
      widget.ctx.visitId,
      step,
    );
    if (raw == null) return null;
    try {
      return CreateOrder.fromJson(raw);
    } catch (_) {
      // Unparseable draft — treat as no draft so the user can decide.
      return null;
    }
  }

  void _completeWithDraft(CreateOrder? draft) {
    widget.ctx.onCompleted(
      OrderCreatePayloadAdapter.fromCreateOrder(draft),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buyurtma yaratish'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.ctx.onBack,
        ),
      ),
      body: FutureBuilder<CreateOrder?>(
        future: _draftFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final draft = snap.data;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (draft == null)
                  const _NoDraftCard()
                else
                  _DraftSummaryCard(draft: draft),
                const Spacer(),
                FilledButton(
                  onPressed: () => _completeWithDraft(draft),
                  child: Text(draft == null
                      ? 'Buyurtmasiz yakunlash'
                      : 'Buyurtmani biriktirish'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => widget.ctx.onSkipped('order_not_required'),
                  child: const Text('Bu safar o\'tkazib yuborish'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NoDraftCard extends StatelessWidget {
  const _NoDraftCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Bu tashrif uchun saqlangan buyurtma topilmadi. '
                'Eski sahifada draft yarating yoki bu qadamni '
                'buyurtmasiz yakunlang.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftSummaryCard extends StatelessWidget {
  const _DraftSummaryCard({required this.draft});

  final CreateOrder draft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalUzs = draft.products.fold<double>(
      0,
      (acc, p) => acc + p.total,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Buyurtma loyihasi',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _SummaryRow('Mahsulotlar', '${draft.products.length}'),
            _SummaryRow('Jami summa', '${totalUzs.toStringAsFixed(0)} so\'m'),
            _SummaryRow('Og\'irlik', '${draft.weight.toStringAsFixed(1)} kg'),
            _SummaryRow('Hajm', '${draft.capacity.toStringAsFixed(3)} m³'),
            _SummaryRow(
              'Yetkazib berish',
              draft.shippingDate.toIso8601String().split('T').first,
            ),
            if (draft.hasPromo) ...[
              const SizedBox(height: 4),
              const Chip(
                avatar: Icon(Icons.local_offer, size: 16),
                label: Text('Promo aktiv'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
