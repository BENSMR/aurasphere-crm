// lib/services/ocr_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OcrService {
  static String get _apiKey => dotenv.env['OCR_API_KEY'] ?? '';

  // Map your languages to OCR.space codes
  static String getOcrLanguage(String userLang) {
    switch(userLang) {
      case 'fr': return 'fre';
      case 'it': return 'ita';
      case 'de': return 'ger';
      case 'es': return 'spa';
      case 'mt': return 'mlt';
      case 'ar': 
      case 'ar_MA':
      case 'ar_EG': return 'ara';
      default: return 'eng';
    }
  }

  static Future<Map<String, dynamic>?> parseReceipt(dynamic imageInput, String userLang) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.ocr.space/parse/image'),
      );
      request.headers.addAll({'apikey': _apiKey});
      request.fields['language'] = getOcrLanguage(userLang);
      request.fields['isOverlayRequired'] = 'false';
      request.fields[' filetype'] = 'jpg';
      
      // Handle both File and Uint8List
      if (imageInput is File) {
        request.files.add(await http.MultipartFile.fromPath('file', imageInput.path));
      } else if (imageInput is Uint8List) {
        request.files.add(http.MultipartFile.fromBytes('file', imageInput, filename: 'receipt.jpg'));
      } else {
        throw ArgumentError('imageInput must be File or Uint8List');
      }

      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      final json = jsonDecode(respStr);

      if (json['IsErroredOnProcessing'] == false && json['ParsedResults'] != null) {
        final parsedText = json['ParsedResults'][0]['ParsedText'] as String;
        return _extractStructuredData(parsedText);
      }
      return null;
    } catch (e) {
      print('OCR error: $e');
      return null;
    }
  }

  static Map<String, dynamic> _extractStructuredData(String text) {
    final lines = text.split('\n').map((line) => line.trim()).toList();
    String? vendor, dateStr;
    double? total;

    // Simple heuristics (you can improve this later)
    if (lines.isNotEmpty) vendor = lines[0];

    // Look for date (common formats)
    final datePattern = RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}');
    for (final line in lines) {
      if (datePattern.hasMatch(line)) {
        dateStr = line;
        break;
      }
    }

    // Look for total (line with highest number)
    double maxVal = 0;
    for (final line in lines) {
      final numPattern = RegExp(r'(\d+\.?\d*)');
      final match = numPattern.firstMatch(line);
      if (match != null) {
        final val = double.tryParse(match.group(1)!) ?? 0;
        if (val > maxVal && val < 10000) {
          maxVal = val;
          total = val;
        }
      }
    }

    return {
      'vendor': vendor,
      'date': dateStr,
      'total': total,
      'raw_text': text,
    };
  }
}
