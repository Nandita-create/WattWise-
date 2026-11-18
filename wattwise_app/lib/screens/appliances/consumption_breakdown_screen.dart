import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../state/app_state.dart';

class ConsumptionBreakdownScreen extends StatelessWidget {
  const ConsumptionBreakdownScreen({super.key});

  static const _palette = [
    Color(0xFF167D69),
    Color(0xFF2E86AB),
    Color(0xFFF18F01),
    Color(0xFFC73E1D),
    Color(0xFF6B4E71),
    Color(0xFF3B7A57),
    Color(0xFF8D99AE),
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final appliances = List.of(state.appliances)
      ..sort((a, b) => b.estimatedMonthlyKwh.compareTo(a.estimatedMonthlyKwh));
    final total = state.totalEstimatedApplianceKwh;
    final categoryTotals = state.consumptionByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('Consumption Breakdown')),
      body: appliances.isEmpty
          ? const Center(
              child: Text('Add appliances to view consumption breakdown.'),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Category Share (kWh / month)',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 210,
                          child: PieChart(
                            PieChartData(
                              centerSpaceRadius: 42,
                              sectionsSpace: 2,
                              sections: List.generate(
                                categoryTotals.length,
                                (i) {
                                  final entry = categoryTotals[i];
                                  final pct = total > 0
                                      ? (entry.value / total) * 100
                                      : 0.0;
                                  return PieChartSectionData(
                                    value: entry.value,
                                    color: _palette[i % _palette.length],
                                    radius: 56,
                                    title: '${pct.toStringAsFixed(0)}%',
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: List.generate(categoryTotals.length, (i) {
                            final entry = categoryTotals[i];
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _palette[i % _palette.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                    '${entry.key}: ${entry.value.toStringAsFixed(1)} kWh'),
                              ],
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Appliance-wise Consumption',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...appliances.map((app) {
                  final kwh = app.estimatedMonthlyKwh;
                  final share = total > 0 ? kwh / total : 0.0;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
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
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(
                                '${kwh.toStringAsFixed(1)} kWh (${(share * 100).toStringAsFixed(1)}%)',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: share.clamp(0.0, 1.0),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
