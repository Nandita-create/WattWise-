import 'package:flutter/material.dart';

import '../../models/appliance_model.dart';
import '../../services/energy_calculator.dart';
import '../../state/app_state.dart';

class AddEditApplianceScreen extends StatefulWidget {
  final ApplianceModel? existing;

  const AddEditApplianceScreen({super.key, this.existing});

  @override
  State<AddEditApplianceScreen> createState() => _AddEditApplianceScreenState();
}

class _AddEditApplianceScreenState extends State<AddEditApplianceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _wattsCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _hoursCtrl = TextEditingController(text: '4.0');
  final _daysCtrl = TextEditingController(text: '30');

  String _category = 'Cooling';
  static const _categories = [
    'Cooling',
    'Kitchen',
    'Heating',
    'Laundry',
    'Entertainment',
    'Work & Study',
    'Lighting',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _category = _categories.contains(e.category) ? e.category : 'Other';
      _wattsCtrl.text = e.ratedPowerWatts.toStringAsFixed(0);
      _qtyCtrl.text = e.quantity.toString();
      _hoursCtrl.text = e.dailyUsageHours.toString();
      _daysCtrl.text = e.daysPerMonth.toString();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _wattsCtrl.dispose();
    _qtyCtrl.dispose();
    _hoursCtrl.dispose();
    _daysCtrl.dispose();
    super.dispose();
  }

  double get _livePreviewKwh {
    final p = double.tryParse(_wattsCtrl.text) ?? 0;
    final n = int.tryParse(_qtyCtrl.text) ?? 0;
    final h = double.tryParse(_hoursCtrl.text) ?? 0;
    final d = int.tryParse(_daysCtrl.text) ?? 0;
    return EnergyCalculator.calculateApplianceKwh(
      ratedPowerWatts: p,
      dailyUsageHours: h,
      daysPerMonth: d,
      quantity: n,
    );
  }

  void _applyPredefined(PredefinedAppliance item) {
    setState(() {
      _nameCtrl.text = item.name;
      _category = item.category;
      _wattsCtrl.text = item.defaultWatts.toStringAsFixed(0);
      _hoursCtrl.text = item.defaultHours.toString();
      _daysCtrl.text = item.defaultDays.toString();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final state = AppScope.of(context);
    final userId = state.currentUser?.id;
    if (userId == null) return;

    final model = ApplianceModel(
      id: widget.existing?.id,
      userId: userId,
      name: _nameCtrl.text.trim(),
      category: _category,
      ratedPowerWatts: double.parse(_wattsCtrl.text.trim()),
      quantity: int.parse(_qtyCtrl.text.trim()),
      dailyUsageHours: double.parse(_hoursCtrl.text.trim()),
      daysPerMonth: int.parse(_daysCtrl.text.trim()),
    );

    if (widget.existing == null) {
      await state.addAppliance(model);
    } else {
      await state.updateAppliance(model);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEditing = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Appliance' : 'Add Appliance'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          onChanged: () => setState(() {}),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isEditing) ...[
                const Text(
                  'Quick Select Predefined Appliance',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: PredefinedAppliance.catalog.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final item = PredefinedAppliance.catalog[i];
                      return ActionChip(
                        label: Text(item.name),
                        onPressed: () => _applyPredefined(item),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
              ],
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Appliance Name',
                  prefixIcon: Icon(Icons.electrical_services),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _category = v);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _wattsCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Rated Power (W)',
                      ),
                      validator: (v) {
                        final val = double.tryParse(v ?? '');
                        if (val == null || val <= 0) return 'Invalid W';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Units (N)',
                      ),
                      validator: (v) {
                        final val = int.tryParse(v ?? '');
                        if (val == null || val <= 0) return 'Invalid N';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hoursCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Daily Usage (hrs)',
                      ),
                      validator: (v) {
                        final val = double.tryParse(v ?? '');
                        if (val == null || val < 0 || val > 24) {
                          return '0 - 24 hrs';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _daysCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Days / Month',
                      ),
                      validator: (v) {
                        final val = int.tryParse(v ?? '');
                        if (val == null || val < 1 || val > 31) {
                          return '1 - 31 days';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                color: cs.secondaryContainer,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Estimated Monthly Usage\nE = (P × H × D × N) / 1000',
                        style: TextStyle(fontSize: 13),
                      ),
                      Text(
                        '${_livePreviewKwh.toStringAsFixed(2)} kWh',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onSecondaryContainer,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(isEditing ? 'Update Appliance' : 'Save Appliance'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
