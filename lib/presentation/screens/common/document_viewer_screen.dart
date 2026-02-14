import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:mmm/core/constants/colors.dart';

enum DocumentViewerType { image, pdf }

class DocumentViewerScreen extends StatelessWidget {
  final String url;
  final DocumentViewerType type;
  final String title;

  const DocumentViewerScreen({
    super.key,
    required this.url,
    required this.type,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: type == DocumentViewerType.image
          ? PhotoView(
              imageProvider: NetworkImage(url),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, color: Colors.white, size: 48),
                      SizedBox(height: 16),
                      Text(
                        'فشل تحميل الصورة',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                );
              },
            )
          : SfPdfViewer.network(
              url,
              onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('فشل تحميل ملف PDF: ${details.error}'),
                    backgroundColor: AppColors.error,
                  ),
                );
              },
            ),
    );
  }
}
