import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import: web vs mobile
import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart'
    if (dart.library.io) 'download_helper_mobile.dart';

class FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final String? fileName;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    this.fileName,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late TransformationController _transformationController;
  TapDownDetails? _doubleTapDetails;
  bool _isAppBarVisible = true;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    if (!kIsWeb) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    if (!kIsWeb) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  void _onDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _onDoubleTap() {
    if (_doubleTapDetails == null) return;
    final position = _doubleTapDetails!.localPosition;
    final currentScale = _transformationController.value.getMaxScaleOnAxis();

    if (currentScale > 1.0) {
      _transformationController.value = Matrix4.identity();
    } else {
      final x = -position.dx * 1.5;
      final y = -position.dy * 1.5;
      _transformationController.value = Matrix4.identity()
        ..translate(x, y)
        ..scale(2.5);
    }
  }

  void _toggleAppBar() {
    setState(() => _isAppBarVisible = !_isAppBarVisible);
  }

  Future<void> _downloadImage() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    // Build a clean file name
    final rawName = widget.fileName ?? 'image';
    final hasExt = rawName.contains('.');
    final fileName = hasExt ? rawName : '$rawName.jpg';

    try {
      await downloadImageToDevice(widget.imageUrl, fileName);
      _showSnack('تم التنزيل بنجاح ✅', isError: false);
    } catch (e) {
      _showSnack('فشل التنزيل: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _isAppBarVisible
          ? AppBar(
              backgroundColor: Colors.black.withOpacity(0.6),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(
                widget.fileName ?? 'صورة',
                style: const TextStyle(color: Colors.white, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                _isDownloading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(
                          Icons.download_rounded,
                          color: Colors.white,
                        ),
                        tooltip: 'تنزيل',
                        onPressed: _downloadImage,
                      ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: _toggleAppBar,
        onDoubleTapDown: _onDoubleTapDown,
        onDoubleTap: _onDoubleTap,
        child: Center(
          child: InteractiveViewer(
            transformationController: _transformationController,
            panEnabled: true,
            scaleEnabled: true,
            minScale: 0.5,
            maxScale: 5.0,
            child: Image.network(
              widget.imageUrl,
              fit: BoxFit.contain,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'جاري التحميل...',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                );
              },
              errorBuilder: (ctx, err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.broken_image_rounded,
                      color: Colors.white38,
                      size: 72,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'تعذّر تحميل الصورة',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() {}),
                      child: const Text(
                        'إعادة المحاولة',
                        style: TextStyle(color: Colors.lightBlue),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _isAppBarVisible
          ? Container(
              color: Colors.black.withOpacity(0.6),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: const Text(
                'ازدواج النقر للتكبير • اسحب للتحريك',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            )
          : null,
    );
  }
}
