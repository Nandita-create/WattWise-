import '../models/appliance_model.dart';
import '../models/bill_model.dart';
import '../models/insight_model.dart';
import 'energy_calculator.dart';

class InsightsEngine {
  static List<MonthlyTrendPoint> buildMonthlyTrends(List<BillModel> bills) {
    final sorted = List<BillModel>.from(bills)
      ..sort((a, b) => a.billingMonthSortKey.compareTo(b.billingMonthSortKey));

    final List<MonthlyTrendPoint> points = [];
    for (int i = 0; i < sorted.length; i++) {
      final current = sorted[i];
      if (i == 0) {
        points.add(MonthlyTrendPoint(bill: current));
      } else {
        final prev = sorted[i - 1];
        final diff = current.totalUnitsKwh - prev.totalUnitsKwh;
        final pct =
            prev.totalUnitsKwh > 0 ? (diff / prev.totalUnitsKwh) * 100.0 : 0.0;
        points.add(MonthlyTrendPoint(
          bill: current,
          changeKwh: diff,
          changePercent: pct,
        ));
      }
    }
    return points;
  }

  static List<ConsumptionAnomaly> detectAnomalies({
    required List<BillModel> bills,
    required List<ApplianceModel> appliances,
  }) {
    if (bills.length < 2) return [];

    final sorted = List<BillModel>.from(bills)
      ..sort((a, b) => a.billingMonthSortKey.compareTo(b.billingMonthSortKey));

    final avg = sorted.fold<double>(0.0, (s, b) => s + b.totalUnitsKwh) /
        sorted.length;

    final List<ConsumptionAnomaly> anomalies = [];
    final sortedAppliances = List<ApplianceModel>.from(appliances)
      ..sort((a, b) => b.estimatedMonthlyKwh.compareTo(a.estimatedMonthlyKwh));

    for (int i = 0; i < sorted.length; i++) {
      final bill = sorted[i];
      final pctVsAvg =
          avg > 0 ? ((bill.totalUnitsKwh - avg) / avg) * 100.0 : 0.0;

      if (pctVsAvg.abs() >= 15.0) {
        final isSpike = pctVsAvg > 0;
        final severity = pctVsAvg.abs() >= 25.0
            ? AnomalySeverity.high
            : AnomalySeverity.medium;

        final reasons = _inferReasons(
          isSpike: isSpike,
          bill: bill,
          appliances: sortedAppliances,
        );

        anomalies.add(ConsumptionAnomaly(
          billingMonth: bill.billingMonth,
          unitsKwh: bill.totalUnitsKwh,
          baselineAvgKwh: avg,
          percentDeviation: pctVsAvg,
          direction: isSpike ? AnomalyDirection.spike : AnomalyDirection.drop,
          severity: severity,
          possibleReasons: reasons,
        ));
      }
    }
    return anomalies.reversed.toList();
  }

  static List<String> _inferReasons({
    required bool isSpike,
    required BillModel bill,
    required List<ApplianceModel> appliances,
  }) {
    final reasons = <String>[];
    final estimatedTotal = EnergyCalculator.totalEstimatedKwh(appliances);

    if (isSpike) {
      final cooling = appliances.where((a) => a.category == 'Cooling').toList();
      final heating = appliances.where((a) => a.category == 'Heating').toList();

      if (cooling.isNotEmpty) {
        final topCooling = cooling.first;
        reasons.add(
          'Extended ${topCooling.name} runtime (${topCooling.dailyUsageHours.toStringAsFixed(1)} hrs/day, ${topCooling.estimatedMonthlyKwh.toStringAsFixed(1)} kWh/mo) during warm weather.',
        );
      }
      if (heating.isNotEmpty) {
        final topHeating = heating.first;
        reasons.add(
          'Higher ${topHeating.name} usage (${topHeating.ratedPowerWatts.toInt()}W) can sharply raise monthly kWh.',
        );
      }
      if (estimatedTotal > 0 && bill.totalUnitsKwh > estimatedTotal * 1.15) {
        final unallocated = bill.totalUnitsKwh - estimatedTotal;
        reasons.add(
          '${unallocated.toStringAsFixed(1)} kWh of unallocated usage suggests unlisted appliances, standby loads, or guest occupancy.',
        );
      }
      if (reasons.isEmpty) {
        reasons.add(
          'Possible prolonged daily runtime of high-wattage appliances or tariff/billing cycle length variation.',
        );
      }
    } else {
      reasons.add(
        'Lower occupancy, travel days, or reduced runtime of high-load appliances compared to your baseline.',
      );
      if (appliances.isNotEmpty) {
        reasons.add(
          'Reduced usage of ${appliances.first.name} (${appliances.first.estimatedMonthlyKwh.toStringAsFixed(1)} kWh/mo) significantly lowers total units.',
        );
      }
    }
    return reasons;
  }

  static List<EnergyRecommendation> generateRecommendations({
    required List<ApplianceModel> appliances,
    required List<BillModel> bills,
    required double tariffRatePerKwh,
  }) {
    if (appliances.isEmpty) return [];

    final effectiveTariff = bills.isNotEmpty && bills.last.effectiveRatePerKwh > 0
        ? bills.last.effectiveRatePerKwh
        : tariffRatePerKwh;

    final sorted = List<ApplianceModel>.from(appliances)
      ..sort((a, b) => b.estimatedMonthlyKwh.compareTo(a.estimatedMonthlyKwh));

    final List<EnergyRecommendation> recs = [];

    for (final app in sorted.take(4)) {
      if (app.category == 'Cooling' && app.ratedPowerWatts >= 500) {
        final savedKwh = EnergyCalculator.calculateApplianceKwh(
          ratedPowerWatts: app.ratedPowerWatts,
          dailyUsageHours: 1.0,
          daysPerMonth: app.daysPerMonth,
          quantity: app.quantity,
        );
        recs.add(EnergyRecommendation(
          title: 'Trim ${app.name} by 1 hr/day',
          description:
              'Set thermostat to 24–25°C and use sleep/timer mode to save 1 hour daily.',
          category: app.category,
          potentialMonthlyKwhSavings: savedKwh,
          potentialMonthlyCostSavings: savedKwh * effectiveTariff,
        ));
      } else if (app.category == 'Heating') {
        final savedKwh = EnergyCalculator.calculateApplianceKwh(
          ratedPowerWatts: app.ratedPowerWatts,
          dailyUsageHours: 0.25,
          daysPerMonth: app.daysPerMonth,
          quantity: app.quantity,
        );
        recs.add(EnergyRecommendation(
          title: 'Reduce ${app.name} by 15 mins/day',
          description:
              'Lower thermostat to 50–55°C and switch off immediately after use.',
          category: app.category,
          potentialMonthlyKwhSavings: savedKwh,
          potentialMonthlyCostSavings: savedKwh * effectiveTariff,
        ));
      } else if (app.dailyUsageHours >= 4 && app.dailyUsageHours < 24) {
        final savedKwh = EnergyCalculator.calculateApplianceKwh(
          ratedPowerWatts: app.ratedPowerWatts,
          dailyUsageHours: 1.0,
          daysPerMonth: app.daysPerMonth,
          quantity: app.quantity,
        );
        recs.add(EnergyRecommendation(
          title: 'Cut ${app.name} by 1 hr/day',
          description:
              'Turn off when rooms are unoccupied to reduce continuous base load.',
          category: app.category,
          potentialMonthlyKwhSavings: savedKwh,
          potentialMonthlyCostSavings: savedKwh * effectiveTariff,
        ));
      } else {
        final savedKwh = app.estimatedMonthlyKwh * 0.10;
        recs.add(EnergyRecommendation(
          title: 'Optimize ${app.name} efficiency',
          description:
              'Clean coils/filters and avoid standby power draw to save ~10%.',
          category: app.category,
          potentialMonthlyKwhSavings: savedKwh,
          potentialMonthlyCostSavings: savedKwh * effectiveTariff,
        ));
      }
    }

    if (bills.isNotEmpty) {
      final latestBill = bills.last;
      final estimated = EnergyCalculator.totalEstimatedKwh(appliances);
      final unallocated = latestBill.totalUnitsKwh - estimated;
      if (unallocated > 25) {
        final standbySavings = unallocated * 0.30;
        recs.add(EnergyRecommendation(
          title: 'Eliminate Standby & Unlisted Loads',
          description:
              '${unallocated.toStringAsFixed(0)} kWh is unallocated in your latest bill. Use smart power strips to cut phantom loads.',
          category: 'General',
          potentialMonthlyKwhSavings: standbySavings,
          potentialMonthlyCostSavings: standbySavings * effectiveTariff,
        ));
      }
    }

    return recs;
  }
}
