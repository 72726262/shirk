import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/cubits/documents/documents_cubit.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class DocumentViewerScreen extends StatefulWidget {
  final String documentId;

  const DocumentViewerScreen({super.key, required this.documentId});

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DocumentsCubit>().loadDocument(widget.documentId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('عرض المستند'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadDocument(),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareDocument(),
          ),
        ],
      ),
      body: BlocBuilder<DocumentsCubit, DocumentsState>(
        builder: (context, state) {
          if (state is DocumentsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DocumentLoaded) {
            final document = state.document;

            // Check if PDF
            if (document.fileUrl.endsWith('.pdf')) {
              return PDFView(
                filePath: document.localPath,
                enableSwipe: true,
                swipeHorizontal: false,
                autoSpacing: true,
                pageFling: true,
                onError: (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ: $error')),
                  );
                },
              );
            }

            // If image
            return Center(
              child: InteractiveViewer(
                child: Image.network(
                  document.fileUrl,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Text('فشل تحميل الصورة'));
                  },
                ),
              ),
            );
          }

          return const Center(child: Text('فشل تحميل المستند'));
        },
      ),
    );
  }

  Future<void> _downloadDocument() async {
    await context.read<DocumentsCubit>().downloadDocument(widget.documentId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم التنزيل بنجاح'), backgroundColor: AppColors.success),
      );
    }
  }

  Future<void> _shareDocument() async {
    await context.read<DocumentsCubit>().shareDocument(widget.documentId);
  }
}
