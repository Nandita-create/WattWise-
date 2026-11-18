import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/insight_model.dart';
import '../../services/energy_calculator.dart';
import '../../state/app_state.dart';

class InsightsScreen extends StatelessWidget {
  final int initialTabIndex;

  const InsightsScreen({super.key, this.initialTabIndex = 0});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      initialIndex: initialTabIndex,
      child: Column(
        children: [
          const Material(
            color: Colors.white,
            child: TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Trends'),
                Tab(text: 'Anomalies'),
                Tab(text: 'Recommendations'),
                Tab(text: 'Simulator'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _MonthlyTrendsTab(),
                _AnomalyDetectionTab(),
                _RecommendationsTab(),
                _SavingsSimulatorTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyTrendsTab extends StatelessWidget {
  const _MonthlyTrendsTab();

  @override
  Widget build(BuildContext context) {
    final trends = AppScope.of(context).monthlyTrends;
    final cs = Theme.of(context).colorScheme;

    if (trends.isEmpty) {
      return const Center(
        child: Text('Add electricity bills to view monthly consumption trends.'),
      );
    }

    final spots = List.generate(
      trends.length,
      (i) => FlSpot(i.toDouble(), trends[i].bill.totalUnitsKwh),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Month-on-Month Consumption (kWh)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (val, _) {
                              final idx = val.toInt();
                              if (idx < 0 || idx >= trends.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  trends[idx].bill.billingMonth.split(' ').first,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: cs.primary,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: cs.primary.withOpacity(0.12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Monthly History',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...trends.reversed.map((point) {
          final pct = point.changePercent;
          final diff = point.changeKwh;
          final isUp = (diff ?? 0) > 0;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              title: Text(point.bill.billingMonth,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('₹${point.bill.totalAmount.toStringAsFixed(2)}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${point.bill.totalUnitsKwh.toStringAsFixed(0)} kWh',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  if (pct != null && diff != null)
                    Text(
                      '${isUp ? '+' : ''}${pct.toStringAsFixed(1)}% (${isUp ? '+' : ''}${diff.toStringAsFixed(0)} kWh)',
                      style: TextStyle(
                        fontSize: 12,
                        color: isUp ? Colors.redAccent : Colors.green.shade700,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _AnomalyDetectionTab extends StatelessWidget {
  const _AnomalyDetectionTab();

  @override
  Widget build(BuildContext context) {
    final anomalies = AppScope.of(context).anomalies;

    if (anomalies.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No unusual spikes or drops detected yet.\nAdd at least 2 monthly bills to run anomaly detection.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: anomalies.length,
      itemBuilder: (context, index) {
        final a = anomalies[index];
        final isSpike = a.direction == AnomalyDirection.spike;
        final color = isSpike ? Colors.redAccent : Colors.blueAccent;

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isSpike ? Icons.trending_up : Icons.trending_down,
                      color: color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${a.billingMonth} — ${isSpike ? 'Unusual Spike' : 'Unusual Drop'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(
                        '${a.percentDeviation > 0 ? '+' : ''}${a.percentDeviation.toStringAsFixed(1)}%',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: color,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Recorded: ${a.unitsKwh.toStringAsFixed(1)} kWh vs Baseline Avg: ${a.baselineAvgKwh.toStringAsFixed(1)} kWh',
                  style: const TextStyle(color: Colors.black54),
                ),
                const Divider(height: 20),
                const Text(
                  'Possible Reasons:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                ...a.possibleReasons.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(child: Text(r)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RecommendationsTab extends StatelessWidget {
  const _RecommendationsTab();

  @override
  Widget build(BuildContext context) {
    final recs = AppScope.of(context).recommendations;

    if (recs.isEmpty) {
      return const Center(
        child: Text('Add appliances to generate personalized recommendations.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recs.length,
      itemBuilder: (context, index) {
        final r = recs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tips_and_updates_outlined,
                        color: Color(0xFF167D69)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        r.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(r.description),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F5F1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Potential Savings: ${r.potentialMonthlyKwhSavings.toStringAsFixed(1)} kWh/mo  •  ₹${r.potentialMonthlyCostSavings.toStringAsFixed(0)}/mo',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF167D69),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SavingsSimulatorTab extends StatefulWidget {
  const _SavingsSimulatorTab();

  @override
  State<_SavingsSimulatorTab> createState() => _SavingsSimulatorTabState();
}

class _SavingsSimulatorTabState extends State<_SavingsSimulatorTab> {
  final Map<int, double> _simulatedHours = {};

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final appliances = state.appliances;
    final tariff = state.effectiveTariffRate;
    final cs = Theme.of(context).colorScheme;

    if (appliances.isEmpty) {
      return const Center(
        child: Text('Add appliances to run the interactive savings simulator.'),
      );
    }

    double baselineTotal = 0.0;
    double simulatedTotal = 0.0;

    for (final app in appliances) {
      final baseKwh = app.estimatedMonthlyKwh;
      final simH = _simulatedHours[app.id] ?? app.dailyUsageHours;
      final simKwh = EnergyCalculator.calculateApplianceKwh(
        ratedPowerWatts: app.ratedPowerWatts,
        dailyUsageHours: simH,
        daysPerMonth: app.daysPerMonth,
        quantity: app.quantity,
      );
      baselineTotal += baseKwh;
      simulatedTotal += simKwh;
    }

    final savedKwh = baselineTotal - simulatedTotal;
    final savedCost = savedKwh * tariff;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: cs.primaryContainer,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Simulated Monthly Impact',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SimStat(
                      label: 'Units Saved',
                      value: '${savedKwh.toStringAsFixed(1)} kWh',
                    ),
                    _SimStat(
                      label: 'Est. Savings',
                      value: '₹${savedCost.toStringAsFixed(0)}/mo',
                    ),
                    _SimStat(
                      label: 'New Total',
                      value: '${simulatedTotal.toStringAsFixed(1)} kWh',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() => _simulatedHours.clear()),
                    child: const Text('Reset Sliders'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        ...appliances.map((app) {
          final currentH = _simulatedHours[app.id] ?? app.dailyUsageHours;
          final simKwh = EnergyCalculator.calculateApplianceKwh(
            ratedPowerWatts: app.ratedPowerWatts,
            dailyUsageHours: currentH,
            daysPerMonth: app.daysPerMonth,
            quantity: app.quantity,
          );
          final deltaKwh = app.estimatedMonthlyKwh - simKwh;

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          app.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '${currentH.toStringAsFixed(1)} hrs/day',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: currentH.clamp(0.0, 24.0),
                    min: 0,
                    max: 24,
                    divisions: 48,
                    label: '${currentH.toStringAsFixed(1)} h',
                    onChanged: (val) {
                      if (app.id != null) {
                        setState(() => _simulatedHours[app.id!] = val);
                      }
                    },
                  ),
                  Text(
                    'Baseline: ${app.estimatedMonthlyKwh.toStringAsFixed(1)} kWh  →  Simulated: ${simKwh.toStringAsFixed(1)} kWh  '
                    '(${deltaKwh >= 0 ? 'Saves' : 'Adds'} ${deltaKwh.abs().toStringAsFixed(1)} kWh)',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _SimStat extends StatelessWidget {
  final String label;
  final String value;

  const _SimStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
