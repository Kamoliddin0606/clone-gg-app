import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/src/features/marketing/presentation/pages/promotion_detail_page.dart';
import 'package:gloria_marketing_flutter/src/features/marketing/presentation/widgets/promotion_card.dart';

class PromotionsPage extends StatelessWidget {
  const PromotionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // This is mock data. In a real app, you would fetch this from an API.
    final promotions = List.generate(
      10,
      (index) => {
        'id': 'PROMO-00${index + 1}',
        'name': 'Aksiya Nomi ${index + 1}',
        'description': 'Bu aksiya uchun uzunroq tavsif. Matn 20 ta so\'zdan oshmasligi kerak va qolgani kesiladi. Qisqa va mazmunli bo\'lishi muhim.',
        'startDate': '01.09.2023',
        'endDate': '30.09.2023',
      },
    );

    final cs = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withOpacity(.08),
            cs.primaryContainer.withOpacity(.06),
          ],
        ),
      ),
      child: ListView.separated(
        itemCount: promotions.length,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        physics: const BouncingScrollPhysics(),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final promotion = promotions[index];
          return PromotionCard(
            name: promotion['name']!,
            id: promotion['id']!,
            description: promotion['description']!,
            startDate: promotion['startDate']!,
            endDate: promotion['endDate']!,
            onTap: () {
              Navigator.pushNamed(context, '/promotion-detail');
            },
          );
        },
      ),
    );
  }
}