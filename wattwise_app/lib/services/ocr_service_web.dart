import 'dart:typed_data';

Future<String> extractTextFromBytesImpl({
  required Uint8List bytes,
  required bool isPdf,
  String? filePath,
}) async {
  throw UnsupportedError(
    'On-device ML Kit OCR is only supported on Android/iOS. '
    'You can paste bill text or enter the extracted fields manually.',
  );
}
