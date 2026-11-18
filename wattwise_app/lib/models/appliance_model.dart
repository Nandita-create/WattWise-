class ApplianceModel {
  final int? id;
  final int userId;
  final String name;
  final String category;
  final double ratedPowerWatts; // P
  final int quantity; // N
  final double dailyUsageHours; // H
  final int daysPerMonth; // D

  const ApplianceModel({
    this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.ratedPowerWatts,
    required this.quantity,
    required this.dailyUsageHours,
    required this.daysPerMonth,
  });

  /// Core calculation: E = (P * H * D * N) / 1000
  double get estimatedMonthlyKwh =>
      (ratedPowerWatts * dailyUsageHours * daysPerMonth * quantity) / 1000.0;

  double get estimatedDailyKwh =>
      (ratedPowerWatts * dailyUsageHours * quantity) / 1000.0;

  ApplianceModel copyWith({
    int? id,
    int? userId,
    String? name,
    String? category,
    double? ratedPowerWatts,
    int? quantity,
    double? dailyUsageHours,
    int? daysPerMonth,
  }) {
    return ApplianceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      ratedPowerWatts: ratedPowerWatts ?? this.ratedPowerWatts,
      quantity: quantity ?? this.quantity,
      dailyUsageHours: dailyUsageHours ?? this.dailyUsageHours,
      daysPerMonth: daysPerMonth ?? this.daysPerMonth,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'name': name,
      'category': category,
      'rated_power_watts': ratedPowerWatts,
      'quantity': quantity,
      'daily_usage_hours': dailyUsageHours,
      'days_per_month': daysPerMonth,
    };
  }

  factory ApplianceModel.fromMap(Map<String, dynamic> map) {
    return ApplianceModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      category: map['category'] as String,
      ratedPowerWatts: (map['rated_power_watts'] as num).toDouble(),
      quantity: map['quantity'] as int,
      dailyUsageHours: (map['daily_usage_hours'] as num).toDouble(),
      daysPerMonth: map['days_per_month'] as int,
    );
  }
}

class PredefinedAppliance {
  final String name;
  final String category;
  final double defaultWatts;
  final double defaultHours;
  final int defaultDays;

  const PredefinedAppliance({
    required this.name,
    required this.category,
    required this.defaultWatts,
    required this.defaultHours,
    this.defaultDays = 30,
  });

  static const List<PredefinedAppliance> catalog = [
    PredefinedAppliance(
      name: 'Split Air Conditioner (1.5 Ton)',
      category: 'Cooling',
      defaultWatts: 1500,
      defaultHours: 6.0,
    ),
    PredefinedAppliance(
      name: 'Window Air Conditioner (1 Ton)',
      category: 'Cooling',
      defaultWatts: 1100,
      defaultHours: 5.0,
    ),
    PredefinedAppliance(
      name: 'Ceiling Fan',
      category: 'Cooling',
      defaultWatts: 75,
      defaultHours: 10.0,
    ),
    PredefinedAppliance(
      name: 'Refrigerator (Double Door)',
      category: 'Kitchen',
      defaultWatts: 180,
      defaultHours: 24.0,
    ),
    PredefinedAppliance(
      name: 'Microwave Oven',
      category: 'Kitchen',
      defaultWatts: 1200,
      defaultHours: 0.5,
    ),
    PredefinedAppliance(
      name: 'Induction Cooktop',
      category: 'Kitchen',
      defaultWatts: 1800,
      defaultHours: 1.0,
    ),
    PredefinedAppliance(
      name: 'Water Heater (Geyser)',
      category: 'Heating',
      defaultWatts: 2000,
      defaultHours: 1.0,
    ),
    PredefinedAppliance(
      name: 'Washing Machine',
      category: 'Laundry',
      defaultWatts: 500,
      defaultHours: 1.0,
      defaultDays: 20,
    ),
    PredefinedAppliance(
      name: 'Electric Iron',
      category: 'Laundry',
      defaultWatts: 1000,
      defaultHours: 0.5,
      defaultDays: 15,
    ),
    PredefinedAppliance(
      name: 'LED Television (43")',
      category: 'Entertainment',
      defaultWatts: 90,
      defaultHours: 4.0,
    ),
    PredefinedAppliance(
      name: 'Laptop / Desktop PC',
      category: 'Work & Study',
      defaultWatts: 120,
      defaultHours: 6.0,
    ),
    PredefinedAppliance(
      name: 'LED Bulb (9W)',
      category: 'Lighting',
      defaultWatts: 9,
      defaultHours: 6.0,
    ),
    PredefinedAppliance(
      name: 'Wi-Fi Router',
      category: 'Work & Study',
      defaultWatts: 12,
      defaultHours: 24.0,
    ),
    PredefinedAppliance(
      name: 'Water Purifier (RO)',
      category: 'Kitchen',
      defaultWatts: 40,
      defaultHours: 2.0,
    ),
  ];
}
