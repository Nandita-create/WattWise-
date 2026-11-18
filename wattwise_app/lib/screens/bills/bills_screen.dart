import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import 'manual_bill_screen.dart';
import 'upload_bill_screen.dart';

class BillsScreen extends StatelessWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final bills = state.bills.reversed.toList();

    return Scaffold(
      body: bills.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long_outlined,
                        size: 64, color: Colors.black38),
                    const SizedBox(height: 12),
                    const Text(
                      'No electricity bills yet',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Upload a PDF/image bill using OCR or enter your monthly bill manually.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const UploadBillScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.document_scanner_outlined),
                          label: const Text('Upload Bill (OCR)'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ManualBillScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.edit_note),
                          label: const Text('Manual Entry'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: bills.length,
              itemBuilder: (context, index) {
                final bill = bills[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    leading: CircleAvatar(
                      child: Icon(
                        bill.sourceType == 'manual'
                            ? Icons.edit_document
                            : Icons.document_scanner,
                      ),
                    ),
                    title: Text(
                      bill.billingMonth,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${bill.totalUnitsKwh.toStringAsFixed(1)} kWh • ${bill.billingPeriod}\n'
                      'Source: ${bill.sourceType.toUpperCase()}',
                    ),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${bill.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 20, color: Colors.redAccent),
                          onPressed: () => state.deleteBill(bill.id!),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'upload_bill_fab',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const UploadBillScreen()),
            ),
            icon: const Icon(Icons.document_scanner_outlined),
            label: const Text('OCR Upload'),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'manual_bill_fab',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ManualBillScreen()),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Manual Entry'),
          ),
        ],
      ),
    );
  }
}
