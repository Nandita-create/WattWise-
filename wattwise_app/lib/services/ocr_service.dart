import 'dart:typed_data';

import 'ocr_service_web.dart'
    if (dart.library.io) 'ocr_service_io.dart' as impl;

class ExtractedBillData {
  final String rawText;
  final String? billingMonth;
  final String? billingMonthSortKey;
  final double? totalUnitsKwh;
  final double? totalAmount;
  final String? billingPeriod;

  const ExtractedBillData({
    required this.rawText,
    this.billingMonth,
    this.billingMonthSortKey,
    this.totalUnitsKwh,
    this.totalAmount,
    this.billingPeriod,
  });
}

class OcrService {
  static Future<ExtractedBillData> extractFromBytes({
    required Uint8List bytes,
    required bool isPdf,
    String? filePath,
  }) async {
    final text = await impl.extractTextFromBytesImpl(
      bytes: bytes,
      isPdf: isPdf,
      filePath: filePath,
    );
    return parseBillText(text);
  }

  static ExtractedBillData parseBillText(String text) {
    final normalized = text.replaceAll('\r', '\n');

    final monthInfo = _extractMonth(normalized);
    final units = _extractUnits(normalized);
    final amount = _extractAmount(normalized);
    final period = _extractBillingPeriod(normalized);

    return ExtractedBillData(
      rawText: normalized.trim(),
      billingMonth: monthInfo.$1,
      billingMonthSortKey: monthInfo.$2,
      totalUnitsKwh: units,
      totalAmount: amount,
      billingPeriod: period,
    );
  }

  static (String?, String?) _extractMonth(String text) {
    const months = {
      'jan': ('Jan', '01'),
      'january': ('Jan', '01'),
      'feb': ('Feb', '02'),
      'february': ('Feb', '02'),
      'mar': ('Mar', '03'),
      'march': ('Mar', '03'),
      'apr': ('Apr', '04'),
      'april': ('Apr', '04'),
      'may': ('May', '05'),
      'jun': ('Jun', '06'),
      'june': ('Jun', '06'),
      'jul': ('Jul', '07'),
      'july': ('Jul', '07'),
      'aug': ('Aug', '08'),
      'august': ('Aug', '08'),
      'sep': ('Sep', '09'),
      'sept': ('Sep', '09'),
      'september': ('Sep', '09'),
      'oct': ('Oct', '10'),
      'october': ('Oct', '10'),
      'nov': ('Nov', '11'),
      'november': ('Nov', '11'),
      'dec': ('Dec', '12'),
      'december': ('Dec', '12'),
    };

    final regex = RegExp(
      r'\b(jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?|sep(?:t|tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\s*[-/,]?\s*(20\d{2})\b',
      caseSensitive: false,
    );
    final match = regex.firstMatch(text);
    if (match != null) {
      final rawMonth = match.group(1)!.toLowerCase();
      final year = match.group(2)!;
      final info = months[rawMonth];
      if (info != null) {
        return ('${info.$1} $year', '$year-${info.$2}');
      }
    }
    return (null, null);
  }

  static double? _extractUnits(String text) {
    final patterns = [
      RegExp(
        r'(?:total\s*units|units\s*consumed|consumption|billed\s*units|energy\s*consumed)\s*[:\-]?\s*(\d+(?:[.,]\d+)?)\s*(?:kwh|units)?',
        caseSensitive: false,
      ),
      RegExp(r'(\d+(?:[.,]\d+)?)\s*kwh\b', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final raw = match.group(1)!.replaceAll(',', '');
        final parsed = double.tryParse(raw);
        if (parsed != null && parsed > 0 && parsed < 50000) {
          return parsed;
        }
      }
    }
    return null;
  }

  static double? _extractAmount(String text) {
    final patterns = [
      RegExp(
        r'(?:total\s*(?:bill\s*)?amount|amount\s*payable|net\s*payable|bill\s*amount|total\s*due)\s*[:\-]?\s*(?:rs\.?|inr|₹|\$)?\s*(\d[\d,]*(?:\.\d{1,2})?)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:rs\.?|inr|₹|\$)\s*(\d[\d,]*(?:\.\d{1,2})?)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final raw = match.group(1)!.replaceAll(',', '');
        final parsed = double.tryParse(raw);
        if (parsed != null && parsed > 0) {
          return parsed;
        }
      }
    }
    return null;
  }

  static String? _extractBillingPeriod(String text) {
    final periodRegex = RegExp(
      r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\s*(?:to|-|–)\s*\d{1,2}[/-]\d{1,2}[/-]\d{2,4})',
      caseSensitive: false,
    );
    final match = periodRegex.firstMatch(text);
    if (match != null) {
      return match.group(1)?.trim();
    }
    return null;
  }
}
