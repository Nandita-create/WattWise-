import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../models/bill_model.dart';
import '../../services/ocr_service.dart';
import '../../state/app_state.dart';

class UploadBillScreen extends StatefulWidget {
  const UploadBillScreen({super.key});

  @override
  State<UploadBillScreen> createState() => _UploadBillScreenState();
}

class _UploadBillScreenState extends State<UploadBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _monthCtrl = TextEditingController();
  final _periodCtrl = TextEditingController();
  final _unitsCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _pasteTextCtrl = TextEditingController();

  bool _processingOcr = false;
  bool _hasExtracted = false;
  String? _selectedFilePath;
  String _sourceType = 'ocr_image';
  String _rawOcrText = '';
  String _sortKey = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void dispose() {
    _monthCtrl.dispose();
    _periodCtrl.dispose();
    _unitsCtrl.dispose();
    _amountCtrl.dispose();
    _pasteTextCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: source, imageQuality: 90);
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    await _runOcr(
      bytes: bytes,
      isPdf: false,
      filePath: kIsWeb ? null : xfile.path,
    );
  }

  Future<void> _pickPdfOrImageFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) return;
    final isPdf = file.name.toLowerCase().endsWith('.pdf');
    await _runOcr(
      bytes: bytes,
      isPdf: isPdf,
      filePath: kIsWeb ? null : file.path,
    );
  }

  Future<void> _runOcr({
    required Uint8List bytes,
    required bool isPdf,
    String? filePath,
  }) async {
    setState(() {
      _processingOcr = true;
      _selectedFilePath = filePath;
      _sourceType = isPdf ? 'ocr_pdf' : 'ocr_image';
    });

    try {
      final extracted = await OcrService.extractFromBytes(
        bytes: bytes,
        isPdf: isPdf,
        filePath: filePath,
      );
      if (!mounted) return;
      _applyExtracted(extracted);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            kIsWeb
                ? 'On-device OCR runs on Android/iOS. Confirm details below or paste bill text.'
                : 'OCR failed: $e. You can enter details below.',
          ),
        ),
      );
      setState(() {
        _hasExtracted = true;
        _monthCtrl.text = DateFormat('MMM yyyy').format(DateTime.now());
      });
    } finally {
      if (mounted) setState(() => _processingOcr = false);
    }
  }

  void _applyExtracted(ExtractedBillData extracted) {
    setState(() {
      _hasExtracted = true;
      _rawOcrText = extracted.rawText;
      _monthCtrl.text = extracted.billingMonth ??
          DateFormat('MMM yyyy').format(DateTime.now());
      _sortKey = extracted.billingMonthSortKey ??
          DateFormat('yyyy-MM').format(DateTime.now());
      _periodCtrl.text = extracted.billingPeriod ?? '';
      _unitsCtrl.text = extracted.totalUnitsKwh?.toStringAsFixed(1) ?? '';
      _amountCtrl.text = extracted.totalAmount?.toStringAsFixed(2) ?? '';
    });
  }

  Future<void> _confirmAndSave() async {
    if (!_formKey.currentState!.validate()) return;
    final state = AppScope.of(context);
    final userId = state.currentUser?.id;
    if (userId == null) return;

    await state.addBill(
      BillModel(
        userId: userId,
        billingMonth: _monthCtrl.text.trim(),
        billingMonthSortKey: _sortKey,
        billingPeriod: _periodCtrl.text.trim().isEmpty
            ? 'Monthly Cycle'
            : _periodCtrl.text.trim(),
        totalUnitsKwh: double.parse(_unitsCtrl.text.trim()),
        totalAmount: double.parse(_amountCtrl.text.trim()),
        sourceType: _sourceType,
        filePath: _selectedFilePath,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Electricity Bill (OCR)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Select Bill Image or PDF',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'OCR automatically extracts billing month, total units (kWh), bill amount, and billing period on Android/iOS.',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (!kIsWeb)
                          FilledButton.icon(
                            onPressed: _processingOcr
                                ? null
                                : () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Camera'),
                          ),
                        FilledButton.tonalIcon(
                          onPressed: _processingOcr
                              ? null
                              : () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Image'),
                        ),
                        OutlinedButton.icon(
                          onPressed:
                              _processingOcr ? null : _pickPdfOrImageFile,
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: const Text('PDF / File'),
                        ),
                      ],
                    ),
                    if (kIsWeb) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: _pasteTextCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Or paste bill text to test parser in Chrome',
                          hintText:
                              'e.g. Oct 2026 | 01/10/2026 - 31/10/2026 | Units Consumed: 342 kWh | Total Amount: Rs. 2890.00',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            final parsed =
                                OcrService.parseBillText(_pasteTextCtrl.text);
                            _applyExtracted(parsed);
                          },
                          icon: const Icon(Icons.auto_fix_high),
                          label: const Text('Parse Pasted Text'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_processingOcr) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 12),
              const Text('Scanning bill with on-device OCR...',
                  textAlign: TextAlign.center),
            ],
            if (_hasExtracted && !_processingOcr) ...[
              const SizedBox(height: 20),
              Text(
                'Confirm Extracted Details',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _monthCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Billing Month (e.g. Oct 2026)',
                        prefixIcon: Icon(Icons.calendar_month),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _periodCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Billing Period',
                        prefixIcon: Icon(Icons.date_range),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _confirmAndSave,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Confirm & Save Bill'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    if (_rawOcrText.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ExpansionTile(
                        title: const Text('View Raw OCR Text'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: SelectableText(
                              _rawOcrText,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
