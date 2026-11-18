import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/bill_model.dart';
import '../../services/energy_calculator.dart';
import '../../state/app_state.dart';

class BillComparisonScreen extends StatefulWidget {
  const BillComparisonScreen({super.key});

  @override
  State<BillComparisonScreen> createState() => _BillComparisonScreenState();
}

class _BillComparisonScreenState extends State<BillComparisonScreen> {
  BillModel? _selectedBill;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final bills = state.bills.reversed.toList();

    if (bills.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bill vs Estimated Usage')),
        body: const Center(
          child: Text('Add at least one electricity bill to compare.'),
        ),
      );
    }

    final activeBill = (_selectedBill != null &&
            bills.any((b) => b.id == _selectedBill!.id))
        ? bills.firstWhere((b) => b.id == _selectedBill!.id)
        : bills.first;

    final result = EnergyCalculator.compareWithBill(
      bill: activeBill,
      appliances: state.appliances,
    );

    final cs = Theme.of(context).colorScheme;
    final maxY = [
      result.bill.totalUnitsKwh,
      result.estimatedApplianceKwh,
      result.unallocatedKwh.abs(),
    ].reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: const Text('Bill vs Estimated Usage')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<BillModel>(
            value: activeBill,
            decoration: const InputDecoration(
              labelText: 'Select Billing Month',
              prefixIcon: Icon(Icons.receipt_long),
            ),
            items: bills
                .map((b) => DropdownMenuItem(
                      value: b,
                      child: Text(
                          '${b.billingMonth} (${b.totalUnitsKwh.toStringAsFixed(0)} kWh)'),
                    ))
                .toList(),
            onChanged: (b) => setState(() => _selectedBill = b),
          ),
          const SizedBox(height: 16),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Actual Billed vs Estimated Appliance Units (kWh)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        maxY: (maxY * 1.25).clamp(10.0, double.infinity),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, _) {
                                switch (val.toInt()) {
                                  case 0:
                                    return const Text('Billed');
                                  case 1:
                                    return const Text('Estimated');
                                  case 2:
                                    return const Text('Unallocated');
                                  default:
                                    return const Text('');
                                }
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(
                                toY: result.bill.totalUnitsKwh,
                                width: 28,
                                color: cs.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [
                              BarChartRodData(
                                toY: result.estimatedApplianceKwh,
                                width: 28,
                                color: const Color(0xFF2E86AB),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 2,
                            barRods: [
                              BarChartRodData(
                                toY: result.unallocatedKwh.abs(),
                                width: 28,
                                color: result.unallocatedKwh >= 0
                                    ? const Color(0xFFF18F01)
                                    : Colors.redAccent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ],
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
          _MetricRow(
            label: 'Actual Billed Units',
            value: '${result.bill.totalUnitsKwh.toStringAsFixed(1)} kWh',
            color: cs.primary,
          ),
          _MetricRow(
            label: 'Total Estimated Appliance Consumption',
            value:
                '${result.estimatedApplianceKwh.toStringAsFixed(1)} kWh (${result.estimatedCoveragePercent.toStringAsFixed(1)}%)',
            color: const Color(0xFF2E86AB),
          ),
          _MetricRow(
            label: result.unallocatedKwh >= 0
                ? 'Unallocated Consumption'
                : 'Over-Estimated Variance',
            value:
                '${result.unallocatedKwh.toStringAsFixed(1)} kWh (${result.unallocatedPercent.toStringAsFixed(1)}%)',
            color: result.unallocatedKwh >= 0
                ? const Color(0xFFF18F01)
                : Colors.redAccent,
          ),
          const SizedBox(height: 12),
          Card(
            color: Colors.amber.shade50,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                result.unallocatedKwh > 0
                    ? 'Unallocated consumption (${result.unallocatedKwh.toStringAsFixed(1)} kWh) typically comes from standby power, unlisted devices, or higher-than-average daily appliance hours.'
                    : 'Your estimated appliance hours slightly exceed the billed meter reading. Consider lowering daily usage hours on infrequently used devices.',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(radius: 8, backgroundColor: color),
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
