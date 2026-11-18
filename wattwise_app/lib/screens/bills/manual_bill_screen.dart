import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/bill_model.dart';
import '../../state/app_state.dart';

class ManualBillScreen extends StatefulWidget {
  const ManualBillScreen({super.key});

  @override
  State<ManualBillScreen> createState() => _ManualBillScreenState();
}

class _ManualBillScreenState extends State<ManualBillScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedMonth = DateTime.now();
  final _periodCtrl = TextEditingController();
  final _unitsCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _syncDefaultPeriod();
  }

  void _syncDefaultPeriod() {
    final start = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final end = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final fmt = DateFormat('dd/MM/yyyy');
    _periodCtrl.text = '${fmt.format(start)} - ${fmt.format(end)}';
  }

  @override
  void dispose() {
    _periodCtrl.dispose();
    _unitsCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = picked;
        _syncDefaultPeriod();
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final state = AppScope.of(context);
    final userId = state.currentUser?.id;
    if (userId == null) return;

    setState(() => _saving = true);
    try {
      final monthLabel = DateFormat('MMM yyyy').format(_selectedMonth);
      final sortKey = DateFormat('yyyy-MM').format(_selectedMonth);

      await state.addBill(
        BillModel(
          userId: userId,
          billingMonth: monthLabel,
          billingMonthSortKey: sortKey,
          billingPeriod: _periodCtrl.text.trim(),
          totalUnitsKwh: double.parse(_unitsCtrl.text.trim()),
          totalAmount: double.parse(_amountCtrl.text.trim()),
          sourceType: 'manual',
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy').format(_selectedMonth);

    return Scaffold(
      appBar: AppBar(title: const Text('Manual Bill Entry')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: _pickMonth,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Billing Month',
                    prefixIcon: Icon(Icons.calendar_month),
                  ),
                  child: Text(monthLabel),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _periodCtrl,
                decoration: const InputDecoration(
                  labelText: 'Billing Period',
                  prefixIcon: Icon(Icons.date_range),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _unitsCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Total Units Consumed (kWh)',
                  prefixIcon: Icon(Icons.electric_meter_outlined),
                ),
                validator: (v) {
                  final val = double.tryParse(v ?? '');
                  if (val == null || val <= 0) return 'Enter valid kWh';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Total Bill Amount (₹)',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                validator: (v) {
                  final val = double.tryParse(v ?? '');
                  if (val == null || val <= 0) return 'Enter valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Electricity Bill'),
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
