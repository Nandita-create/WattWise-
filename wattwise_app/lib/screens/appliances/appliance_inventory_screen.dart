import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import 'add_edit_appliance_screen.dart';
import 'bill_comparison_screen.dart';
import 'consumption_breakdown_screen.dart';

class ApplianceInventoryScreen extends StatelessWidget {
  const ApplianceInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final appliances = state.appliances;
    final totalKwh = state.totalEstimatedApplianceKwh;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        children: [
          Card(
            color: cs.primaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Estimated Appliance Consumption',
                    style: TextStyle(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${totalKwh.toStringAsFixed(1)} kWh / month',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onPrimaryContainer,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const ConsumptionBreakdownScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.pie_chart_outline, size: 18),
                          label: const Text('Breakdown'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BillComparisonScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.compare_arrows, size: 18),
                          label: const Text('Bill vs Est.'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (appliances.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  'No appliances added yet.\nTap "Add Appliance" to calculate consumption.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            )
          else
            ...appliances.map((item) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${item.category} • ${item.ratedPowerWatts.toInt()}W × ${item.quantity} unit(s)\n'
                    '${item.dailyUsageHours.toStringAsFixed(1)} hrs/day • ${item.daysPerMonth} days/mo',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${item.estimatedMonthlyKwh.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: cs.primary,
                            ),
                          ),
                          const Text('kWh/mo',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.black54)),
                        ],
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    AddEditApplianceScreen(existing: item),
                              ),
                            );
                          } else if (value == 'delete') {
                            state.deleteAppliance(item.id!);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ],
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddEditApplianceScreen(existing: item),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_appliance_fab',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEditApplianceScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Appliance'),
      ),
    );
  }
}
