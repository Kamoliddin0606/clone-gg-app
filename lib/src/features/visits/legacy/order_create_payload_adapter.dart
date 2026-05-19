import '../../agent/data/models/create_order.dart';

/// Translates the legacy [CreateOrder] aggregate into the JSON payload the
/// v2 `ORDER_CREATE` task expects.
///
/// Keeps the v2 task page free of SOAP-era field names (codeAgent /
/// codePrice / hasPromo) — the UI keeps using the historical `create_order`
/// table while the envelope ships a flat product-centric shape the backend
/// can validate against its JSON Schema.
///
/// The adapter is intentionally one-way: v2 → SOAP migration is owned by
/// `OneCTaskAdapter` on the backend, not here.
class OrderCreatePayloadAdapter {
  const OrderCreatePayloadAdapter._();

  /// Build the `task.payload` map for a single visit's order draft. Caller
  /// passes `null` when the user opted out (skipped order step) so the
  /// adapter can return a canonical "empty order" instead of crashing.
  static Map<String, dynamic> fromCreateOrder(CreateOrder? draft) {
    if (draft == null) {
      return const {
        'products': <Map<String, dynamic>>[],
        'total_uzs': 0,
        'total_weight_kg': 0,
        'total_capacity_m3': 0,
      };
    }

    final products = draft.products
        .map((p) => <String, dynamic>{
              'product_code_1c': p.codeProduct,
              'vendor_code': p.vendorCode,
              'sklad_code': p.codeSklad,
              'quantity': p.amount,
              'price_uzs': p.price,
              'total_uzs': p.total,
              'weight_kg': p.weight,
              'capacity_m3': p.capacity,
              'payment_type': p.paymentType,
              'discount_sum': p.discountSum,
              'discount_rate': p.discountRate,
              'gift_amount': p.giftAmount,
              'promo': p.promo,
            })
        .toList(growable: false);

    final totalUzs = products.fold<double>(
      0,
      (acc, p) => acc + ((p['total_uzs'] as num).toDouble()),
    );

    return {
      'code_price': draft.codePrice,
      'code_org': draft.codeOrg,
      'code_sklad': draft.codeSklad,
      'code_contract': draft.codeContract,
      'order_type': draft.orderType,
      'payment': draft.payment,
      'credit': draft.credit,
      'has_promo': draft.hasPromo,
      'shipping_date':
          draft.shippingDate.toUtc().toIso8601String().split('T').first,
      'create_date': draft.createDate.toUtc().toIso8601String(),
      'products': products,
      'total_uzs': totalUzs,
      'total_weight_kg': draft.weight,
      'total_capacity_m3': draft.capacity,
      if (draft.comment != null) 'comment': draft.comment,
      if (draft.commentSupervisor != null)
        'comment_supervisor': draft.commentSupervisor,
      if (draft.commentForwarder != null)
        'comment_forwarder': draft.commentForwarder,
      if (draft.competitiveIntelligence.isNotEmpty)
        'competitive_intelligence': draft.competitiveIntelligence
            .map((c) => c.toJson())
            .toList(growable: false),
      if (draft.creditDetails.isNotEmpty)
        'credit_details': draft.creditDetails
            .map((c) => c.toJson())
            .toList(growable: false),
    };
  }
}
