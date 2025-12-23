import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
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
  final List<PromotionProduct> classList;
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
    this.classList = const [],
    this.lastSynced,
    this.isActive = true,
  });

  factory PromotionModel.fromXml(XmlElement element) {
    final timestamp = DateTime.now().toIso8601String();
    if (kDebugMode) print('[$timestamp] DEBUG MODEL: Parsing PromotionModel from XML');

    try {
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

      if (kDebugMode) print('[$timestamp] DEBUG MODEL: Basic fields - code: $code, name: $name, type: $type, dates: $dateStart to $dateEnd');

      final productListRaw = element.findAllElements('m:productList').map((product) {
        return PromotionProduct(
          code: product.findElements('m:code').first.innerText,
          productName: product.findElements('m:productName').first.innerText,
        );
      }).toList();

      // Deduplicate product list by code
      final productListMap = <String, PromotionProduct>{};
      for (final product in productListRaw) {
        productListMap[product.code] = product;
      }
      final productList = productListMap.values.toList();

      final bonusListRaw = element.findAllElements('m:bonusList').map((bonus) {
        return PromotionProduct(
          code: bonus.findElements('m:code').first.innerText,
          productName: bonus.findElements('m:productName').first.innerText,
        );
      }).toList();

      // Deduplicate bonus list by code
      final bonusListMap = <String, PromotionProduct>{};
      for (final bonus in bonusListRaw) {
        bonusListMap[bonus.code] = bonus;
      }
      final bonusList = bonusListMap.values.toList();

      final classListRaw = element.findAllElements('m:classList').map((classItem) {
        final classTypeElement = classItem.findElements('m:classType');
        if (classTypeElement.isNotEmpty) {
          final classType = classTypeElement.first.innerText.trim();
          if (classType.isNotEmpty) {
            return PromotionProduct(
              code: classType,
              productName: 'Class $classType',
            );
          }
        }
        return null;
      }).where((e) => e != null).cast<PromotionProduct>().toList();

      // Deduplicate class list by code
      final classListMap = <String, PromotionProduct>{};
      for (final classItem in classListRaw) {
        classListMap[classItem.code] = classItem;
      }
      final classList = classListMap.values.toList();

      if (kDebugMode) print('[$timestamp] DEBUG MODEL: Products: ${productList.length}, Bonuses: ${bonusList.length}, Classes: ${classList.length}');

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
        classList: classList,
        lastSynced: DateTime.now(),
        isActive: DateTime.now().isBefore(dateEnd),
      );
    } catch (e) {
      if (kDebugMode) {
        print('[$timestamp] DEBUG MODEL: Error parsing XML: $e');
        print('[$timestamp] DEBUG MODEL: XML element: ${element.toXmlString()}');
      }
      rethrow;
    }
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
      'class_list': classList.map((p) => p.toMap()).toList(),
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
      classList: (map['class_list'] as List<dynamic>?)
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
    List<PromotionProduct>? classList,
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
      classList: classList ?? this.classList,
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
    classList,
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