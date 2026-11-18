import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../appliances/add_edit_appliance_screen.dart';
import '../appliances/appliance_inventory_screen.dart';
import '../appliances/bill_comparison_screen.dart';
import '../appliances/consumption_breakdown_screen.dart';
import '../bills/bills_screen.dart';
import '../bills/manual_bill_screen.dart';
import '../bills/upload_bill_screen.dart';
import '../insights/insights_screen.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  void _switchTab(int idx) => setState(() => _currentIndex = idx);

  @override
  Widget build(BuildContext context) {
    const titles = [
      'WattWise Dashboard',
      'Electricity Bills',
      'Appliance Inventory',
      'Energy Insights',
      'User Profile',
    ];

    final pages = [
      _DashboardHomeTab(onNavigateTab: _switchTab),
      const BillsScreen(),
      const ApplianceInventoryScreen(),
      const InsightsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _switchTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Bills',
          ),
          NavigationDestination(
            icon: Icon(Icons.devices_other_outlined),
            selectedIcon: Icon(Icons.devices_other),
            label: 'Appliances',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _DashboardHomeTab extends StatelessWidget {
  final ValueChanged<int> onNavigateTab;

  const _DashboardHomeTab({required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.currentUser;
    final latestBill = state.latestBill;
    final comparison = state.latestBillComparison;
    final anomalies = state.anomalies;
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Welcome back, ${user?.fullName ?? 'User'}',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Your unified energy & bill overview',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 16),
        if (anomalies.isNotEmpty)
          Card(
            color: Colors.red.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: const Icon(Icons.warning_amber_rounded,
                  color: Colors.redAccent),
              title: Text(
                'Anomaly in ${anomalies.first.billingMonth}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${anomalies.first.percentDeviation > 0 ? '+' : ''}${anomalies.first.percentDeviation.toStringAsFixed(1)}% vs baseline average',
              ),
              trailing: TextButton(
                onPressed: () => onNavigateTab(3),
                child: const Text('Inspect'),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                title: 'Latest Bill',
                value: latestBill != null
                    ? '${latestBill.totalUnitsKwh.toStringAsFixed(0)} kWh'
                    : '—',
                subtitle: latestBill != null
                    ? '₹${latestBill.totalAmount.toStringAsFixed(0)} • ${latestBill.billingMonth}'
                    : 'No bill yet',
                icon: Icons.receipt_long,
                color: cs.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                title: 'Est. Appliances',
                value:
                    '${state.totalEstimatedApplianceKwh.toStringAsFixed(0)} kWh',
                subtitle: '${state.appliances.length} appliances tracked',
                icon: Icons.electrical_services,
                color: const Color(0xFF2E86AB),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (comparison != null)
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFF3E0),
                child: Icon(Icons.compare_arrows, color: Color(0xFFF18F01)),
              ),
              title: const Text('Unallocated Consumption',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                '${comparison.unallocatedKwh.toStringAsFixed(1)} kWh (${comparison.unallocatedPercent.toStringAsFixed(1)}% of ${comparison.bill.billingMonth})',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BillComparisonScreen()),
              ),
            ),
          ),
        const SizedBox(height: 20),
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.3,
          children: [
            _QuickActionTile(
              icon: Icons.document_scanner_outlined,
              label: 'Upload Bill (OCR)',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UploadBillScreen()),
              ),
            ),
            _QuickActionTile(
              icon: Icons.edit_note,
              label: 'Manual Bill Entry',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManualBillScreen()),
              ),
            ),
            _QuickActionTile(
              icon: Icons.add_circle_outline,
              label: 'Add Appliance',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const AddEditApplianceScreen()),
              ),
            ),
            _QuickActionTile(
              icon: Icons.pie_chart_outline,
              label: 'Usage Breakdown',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const ConsumptionBreakdownScreen()),
              ),
            ),
            _QuickActionTile(
              icon: Icons.tune,
              label: 'Savings Simulator',
              onTap: () => onNavigateTab(3),
            ),
            _QuickActionTile(
              icon: Icons.compare_arrows,
              label: 'Bill vs Estimated',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BillComparisonScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
