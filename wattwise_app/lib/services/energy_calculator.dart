import '../models/appliance_model.dart';
import '../models/bill_model.dart';

class BillComparisonResult {
  final BillModel bill;
  final double estimatedApplianceKwh;
  final double unallocatedKwh;
  final double unallocatedPercent;
  final double estimatedCoveragePercent;

  const BillComparisonResult({
    required this.bill,
    required this.estimatedApplianceKwh,
    required this.unallocatedKwh,
    required this.unallocatedPercent,
    required this.estimatedCoveragePercent,
  });
}

class EnergyCalculator {
  /// Core calculation: E = (P * H * D * N) / 1000
  static double calculateApplianceKwh({
    required double ratedPowerWatts,
    required double dailyUsageHours,
    required int daysPerMonth,
    required int quantity,
  }) {
    return (ratedPowerWatts * dailyUsageHours * daysPerMonth * quantity) /
        1000.0;
  }

  static double totalEstimatedKwh(List<ApplianceModel> appliances) {
    return appliances.fold<double>(
      0.0,
      (sum, item) => sum + item.estimatedMonthlyKwh,
    );
  }

  static Map<String, double> consumptionByCategory(
    List<ApplianceModel> appliances,
  ) {
    final Map<String, double> totals = {};
    for (final item in appliances) {
      totals[item.category] =
          (totals[item.category] ?? 0.0) + item.estimatedMonthlyKwh;
    }
    return totals;
  }

  static BillComparisonResult compareWithBill({
    required BillModel bill,
    required List<ApplianceModel> appliances,
  }) {
    final estimated = totalEstimatedKwh(appliances);
    final billed = bill.totalUnitsKwh;
    final unallocated = billed - estimated;
    final unallocatedPct = billed > 0 ? (unallocated / billed) * 100.0 : 0.0;
    final coveragePct = billed > 0 ? (estimated / billed) * 100.0 : 0.0;

    return BillComparisonResult(
      bill: bill,
      estimatedApplianceKwh: estimated,
      unallocatedKwh: unallocated,
      unallocatedPercent: unallocatedPct,
      estimatedCoveragePercent: coveragePct,
    );
  }
}
