import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

Future<String> extractTextFromBytesImpl({
  required Uint8List bytes,
  required bool isPdf,
  String? filePath,
}) async {
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    String combinedText = '';
    final tempDir = await getTemporaryDirectory();

    if (isPdf) {
      int pageIndex = 0;
      await for (final page in Printing.raster(bytes, dpi: 180)) {
        final Uint8List pngBytes = await page.toPng();
        final tempImgPath = p.join(
          tempDir.path,
          'ocr_pdf_page_${DateTime.now().millisecondsSinceEpoch}_$pageIndex.png',
        );
        final tempFile = File(tempImgPath);
        await tempFile.writeAsBytes(pngBytes);
        final inputImage = InputImage.fromFilePath(tempImgPath);
        final recognized = await textRecognizer.processImage(inputImage);
        combinedText += '${recognized.text}\n';
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
        pageIndex++;
        if (pageIndex >= 2) break;
      }
    } else {
      String imgPath = filePath ?? '';
      File? tempFile;
      if (imgPath.isEmpty) {
        imgPath = p.join(
          tempDir.path,
          'ocr_img_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        tempFile = File(imgPath);
        await tempFile.writeAsBytes(bytes);
      }
      final inputImage = InputImage.fromFilePath(imgPath);
      final recognized = await textRecognizer.processImage(inputImage);
      combinedText = recognized.text;
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
    }

    return combinedText;
  } finally {
    await textRecognizer.close();
  }
}
