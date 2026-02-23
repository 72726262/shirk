import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

/// Download image on Mobile: saves to app documents and opens it
Future<void> downloadImageToDevice(String url, String fileName) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    throw Exception('فشل جلب الصورة: HTTP ${response.statusCode}');
  }

  final dir = await getApplicationDocumentsDirectory();
  final filePath = '${dir.path}/$fileName';
  final file = File(filePath);
  await file.writeAsBytes(response.bodyBytes);

  // Open file so user can save/share it
  await OpenFilex.open(filePath);
}
