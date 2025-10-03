import 'package:equatable/equatable.dart';
import 'package:xml/xml.dart';

class PromotionModel extends Equatable {
  final String code;
  final String name;
  final String type;
  final int minPromoProductCount;
  final int bonusCount;
  final DateTime dateStart;
  final DateTime dateEnd;
  final List<PromotionProduct> productList;
  final List<PromotionProduct> bonusList;
  final DateTime? lastSynced;
  final bool isActive;

  const PromotionModel({
    required this.code,
    required this.name,
    required this.type,
    required this.minPromoProductCount,
    required this.bonusCount,
    required this.dateStart,
    required this.dateEnd,
    required this.productList,
    required this.bonusList,
    this.lastSynced,
    this.isActive = true,
  });

  factory PromotionModel.fromXml(XmlElement element) {
    final code = element.findElements('m:code').first.innerText;
    final name = element.findElements('m:name').first.innerText;
    final type = element.findElements('m:type').first.innerText;
    final minPromoProductCount = int.tryParse(
        element.findElements('m:minPromoProductcount').first.innerText) ?? 0;
    final bonusCount = int.tryParse(
        element.findElements('m:bonusCount').first.innerText) ?? 0;
    final dateStart = DateTime.parse(
        element.findElements('m:dateStart').first.innerText);
    final dateEnd = DateTime.parse(
        element.findElements('m:dateEnd').first.innerText);

    final productList = element.findAllElements('m:productList').map((product) {
      return PromotionProduct(
        code: product.findElements('m:code').first.innerText,
        productName: product.findElements('m:productName').first.innerText,
      );
    }).toList();

    final bonusList = element.findAllElements('m:bonusList').map((bonus) {
      return PromotionProduct(
        code: bonus.findElements('m:code').first.innerText,
        productName: bonus.findElements('m:productName').first.innerText,
      );
    }).toList();

    return PromotionModel(
      code: code,
      name: name,
      type: type,
      minPromoProductCount: minPromoProductCount,
      bonusCount: bonusCount,
      dateStart: dateStart,
      dateEnd: dateEnd,
      productList: productList,
      bonusList: bonusList,
      lastSynced: DateTime.now(),
      isActive: DateTime.now().isBefore(dateEnd),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'type': type,
      'min_promo_product_count': minPromoProductCount,
      'bonus_count': bonusCount,
      'date_start': dateStart.toIso8601String(),
      'date_end': dateEnd.toIso8601String(),
      'product_list': productList.map((p) => p.toMap()).toList(),
      'bonus_list': bonusList.map((p) => p.toMap()).toList(),
      'last_synced': lastSynced?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  factory PromotionModel.fromMap(Map<String, dynamic> map) {
    return PromotionModel(
      code: map['code'],
      name: map['name'],
      type: map['type'],
      minPromoProductCount: map['min_promo_product_count'],
      bonusCount: map['bonus_count'],
      dateStart: DateTime.parse(map['date_start']),
      dateEnd: DateTime.parse(map['date_end']),
      productList: (map['product_list'] as List<dynamic>?)
          ?.map((p) => PromotionProduct.fromMap(p))
          .toList() ?? [],
      bonusList: (map['bonus_list'] as List<dynamic>?)
          ?.map((p) => PromotionProduct.fromMap(p))
          .toList() ?? [],
      lastSynced: map['last_synced'] != null
          ? DateTime.parse(map['last_synced'])
          : null,
      isActive: map['is_active'] == 1,
    );
  }

  PromotionModel copyWith({
    String? code,
    String? name,
    String? type,
    int? minPromoProductCount,
    int? bonusCount,
    DateTime? dateStart,
    DateTime? dateEnd,
    List<PromotionProduct>? productList,
    List<PromotionProduct>? bonusList,
    DateTime? lastSynced,
    bool? isActive,
  }) {
    return PromotionModel(
      code: code ?? this.code,
      name: name ?? this.name,
      type: type ?? this.type,
      minPromoProductCount: minPromoProductCount ?? this.minPromoProductCount,
      bonusCount: bonusCount ?? this.bonusCount,
      dateStart: dateStart ?? this.dateStart,
      dateEnd: dateEnd ?? this.dateEnd,
      productList: productList ?? this.productList,
      bonusList: bonusList ?? this.bonusList,
      lastSynced: lastSynced ?? this.lastSynced,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
    code,
    name,
    type,
    minPromoProductCount,
    bonusCount,
    dateStart,
    dateEnd,
    productList,
    bonusList,
    lastSynced,
    isActive,
  ];
}

class PromotionProduct extends Equatable {
  final String code;
  final String productName;

  const PromotionProduct({
    required this.code,
    required this.productName,
  });

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'product_name': productName,
    };
  }

  factory PromotionProduct.fromMap(Map<String, dynamic> map) {
    return PromotionProduct(
      code: map['code'],
      productName: map['product_name'],
    );
  }

  @override
  List<Object?> get props => [code, productName];
}