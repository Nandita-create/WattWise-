class BillModel {
  final int? id;
  final int userId;
  final String billingMonth;
  final String billingMonthSortKey; // YYYY-MM for chronological sorting
  final String billingPeriod;
  final double totalUnitsKwh;
  final double totalAmount;
  final String sourceType; // 'manual', 'ocr_image', 'ocr_pdf'
  final String? filePath;
  final String createdAt;

  const BillModel({
    this.id,
    required this.userId,
    required this.billingMonth,
    required this.billingMonthSortKey,
    required this.billingPeriod,
    required this.totalUnitsKwh,
    required this.totalAmount,
    this.sourceType = 'manual',
    this.filePath,
    required this.createdAt,
  });

  double get effectiveRatePerKwh =>
      totalUnitsKwh > 0 ? totalAmount / totalUnitsKwh : 0.0;

  BillModel copyWith({
    int? id,
    int? userId,
    String? billingMonth,
    String? billingMonthSortKey,
    String? billingPeriod,
    double? totalUnitsKwh,
    double? totalAmount,
    String? sourceType,
    String? filePath,
    String? createdAt,
  }) {
    return BillModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      billingMonth: billingMonth ?? this.billingMonth,
      billingMonthSortKey: billingMonthSortKey ?? this.billingMonthSortKey,
      billingPeriod: billingPeriod ?? this.billingPeriod,
      totalUnitsKwh: totalUnitsKwh ?? this.totalUnitsKwh,
      totalAmount: totalAmount ?? this.totalAmount,
      sourceType: sourceType ?? this.sourceType,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'billing_month': billingMonth,
      'billing_month_sort_key': billingMonthSortKey,
      'billing_period': billingPeriod,
      'total_units_kwh': totalUnitsKwh,
      'total_amount': totalAmount,
      'source_type': sourceType,
      'file_path': filePath,
      'created_at': createdAt,
    };
  }

  factory BillModel.fromMap(Map<String, dynamic> map) {
    return BillModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      billingMonth: map['billing_month'] as String,
      billingMonthSortKey: map['billing_month_sort_key'] as String,
      billingPeriod: map['billing_period'] as String,
      totalUnitsKwh: (map['total_units_kwh'] as num).toDouble(),
      totalAmount: (map['total_amount'] as num).toDouble(),
      sourceType: (map['source_type'] as String?) ?? 'manual',
      filePath: map['file_path'] as String?,
      createdAt: map['created_at'] as String,
    );
  }
}
