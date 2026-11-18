import 'package:flutter/material.dart';

import '../../state/app_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _tariffCtrl;
  late TextEditingController _householdCtrl;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final user = AppScope.of(context).currentUser;
      _nameCtrl = TextEditingController(text: user?.fullName ?? '');
      _tariffCtrl = TextEditingController(
        text: (user?.tariffRatePerKwh ?? 8.0).toStringAsFixed(2),
      );
      _householdCtrl = TextEditingController(
        text: (user?.householdSize ?? 3).toString(),
      );
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _tariffCtrl.dispose();
    _householdCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    await AppScope.of(context).updateProfile(
      fullName: _nameCtrl.text,
      tariffRatePerKwh: double.tryParse(_tariffCtrl.text) ?? 8.0,
      householdSize: int.tryParse(_householdCtrl.text) ?? 3,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.currentUser;
    final cs = Theme.of(context).colorScheme;

    if (user == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: cs.primaryContainer,
                  child: Text(
                    user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : 'W',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text('@${user.username} • ${user.email}',
                          style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Account & Tariff Settings',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _tariffCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Electricity Tariff (₹ / kWh)',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    validator: (v) =>
                        (double.tryParse(v ?? '') == null) ? 'Invalid' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _householdCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Household Members',
                      prefixIcon: Icon(Icons.group_outlined),
                    ),
                    validator: (v) =>
                        (int.tryParse(v ?? '') == null) ? 'Invalid' : null,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _saveProfile,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save Changes'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (state.bills.isEmpty || state.appliances.isEmpty)
          OutlinedButton.icon(
            onPressed: () async {
              await state.seedSampleDataForCurrentUser();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sample bills and appliances loaded!'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.dataset_outlined),
            label: const Text('Load Sample Bills & Appliances'),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => state.logout(),
          icon: const Icon(Icons.logout, color: Colors.redAccent),
          label: const Text('Logout',
              style: TextStyle(color: Colors.redAccent)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.redAccent),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }
}
