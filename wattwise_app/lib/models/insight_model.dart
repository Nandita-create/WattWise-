import 'bill_model.dart';

class MonthlyTrendPoint {
  final BillModel bill;
  final double? changeKwh;
  final double? changePercent;

  const MonthlyTrendPoint({
    required this.bill,
    this.changeKwh,
    this.changePercent,
  });
}

enum AnomalySeverity { high, medium }

enum AnomalyDirection { spike, drop }

class ConsumptionAnomaly {
  final String billingMonth;
  final double unitsKwh;
  final double baselineAvgKwh;
  final double percentDeviation;
  final AnomalyDirection direction;
  final AnomalySeverity severity;
  final List<String> possibleReasons;

  const ConsumptionAnomaly({
    required this.billingMonth,
    required this.unitsKwh,
    required this.baselineAvgKwh,
    required this.percentDeviation,
    required this.direction,
    required this.severity,
    required this.possibleReasons,
  });
}

class EnergyRecommendation {
  final String title;
  final String description;
  final String category;
  final double potentialMonthlyKwhSavings;
  final double potentialMonthlyCostSavings;

  const EnergyRecommendation({
    required this.title,
    required this.description,
    required this.category,
    required this.potentialMonthlyKwhSavings,
    required this.potentialMonthlyCostSavings,
  });
}
