class KpiData {
  final String plan;
  final String fact;
  final String totalPercent;
  final String totalForecast;
  final String totalPercentForecastFact;
  final String akbPlan;
  final String akbFact;
  final String akbPercent;
  final String okb;
  final String updateDate;

  const KpiData({
    required this.plan,
    required this.fact,
    required this.totalPercent,
    required this.totalForecast,
    required this.totalPercentForecastFact,
    required this.akbPlan,
    required this.akbFact,
    required this.akbPercent,
    required this.okb,
    required this.updateDate,
  });

  factory KpiData.fromJson(Map<String, dynamic> json) {
    return KpiData(
      plan: json['plan']?.toString() ?? '0',
      fact: json['fact']?.toString() ?? '0',
      totalPercent: json['totalPercent']?.toString() ?? '0%',
      totalForecast: json['totalForecast']?.toString() ?? '0',
      totalPercentForecastFact: json['totalPercentForecastFact']?.toString() ?? '0%',
      akbPlan: json['akbPlan']?.toString() ?? '0',
      akbFact: json['akbFact']?.toString() ?? '0',
      akbPercent: json['akbPercent']?.toString() ?? '0%',
      okb: json['okb']?.toString() ?? '0',
      updateDate: json['updateDate']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plan': plan,
      'fact': fact,
      'totalPercent': totalPercent,
      'totalForecast': totalForecast,
      'totalPercentForecastFact': totalPercentForecastFact,
      'akbPlan': akbPlan,
      'akbFact': akbFact,
      'akbPercent': akbPercent,
      'okb': okb,
      'updateDate': updateDate,
    };
  }

  KpiData copyWith({
    String? plan,
    String? fact,
    String? totalPercent,
    String? totalForecast,
    String? totalPercentForecastFact,
    String? akbPlan,
    String? akbFact,
    String? akbPercent,
    String? okb,
    String? updateDate,
  }) {
    return KpiData(
      plan: plan ?? this.plan,
      fact: fact ?? this.fact,
      totalPercent: totalPercent ?? this.totalPercent,
      totalForecast: totalForecast ?? this.totalForecast,
      totalPercentForecastFact: totalPercentForecastFact ?? this.totalPercentForecastFact,
      akbPlan: akbPlan ?? this.akbPlan,
      akbFact: akbFact ?? this.akbFact,
      akbPercent: akbPercent ?? this.akbPercent,
      okb: okb ?? this.okb,
      updateDate: updateDate ?? this.updateDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KpiData &&
        other.plan == plan &&
        other.fact == fact &&
        other.totalPercent == totalPercent &&
        other.totalForecast == totalForecast &&
        other.totalPercentForecastFact == totalPercentForecastFact &&
        other.akbPlan == akbPlan &&
        other.akbFact == akbFact &&
        other.akbPercent == akbPercent &&
        other.okb == okb &&
        other.updateDate == updateDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      plan, 
      fact, 
      totalPercent, 
      totalForecast, 
      totalPercentForecastFact, 
      akbPlan, 
      akbFact, 
      akbPercent, 
      okb, 
      updateDate
    );
  }

  @override
  String toString() {
    return 'KpiData(plan: $plan, fact: $fact, totalPercent: $totalPercent, totalForecast: $totalForecast, totalPercentForecastFact: $totalPercentForecastFact, akbPlan: $akbPlan, akbFact: $akbFact, akbPercent: $akbPercent, okb: $okb, updateDate: $updateDate)';
  }
}