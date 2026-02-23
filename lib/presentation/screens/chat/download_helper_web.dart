// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:http/http.dart' as http;

/// Download image on Flutter Web by triggering a browser download
Future<void> downloadImageToDevice(String url, String fileName) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    throw Exception('فشل جلب الصورة: HTTP ${response.statusCode}');
  }

  final blob = html.Blob([response.bodyBytes]);
  final objectUrl = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.document.createElement('a') as html.AnchorElement
    ..href = objectUrl
    ..download = fileName
    ..style.display = 'none';

  html.document.body!.append(anchor);
  anchor.click();
  anchor.remove();

  html.Url.revokeObjectUrl(objectUrl);
}
