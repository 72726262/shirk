import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';

class SignaturePadWidget extends StatefulWidget {
  final ValueChanged<Uint8List?> onSigned;
  final double width;
  final double height;
  final Color penColor;
  final double strokeWidth;
  final Color backgroundColor;

  const SignaturePadWidget({
    super.key,
    required this.onSigned,
    this.width = double.infinity,
    this.height = 200,
    this.penColor = AppColors.primary,
    this.strokeWidth = 3.0,
    this.backgroundColor = AppColors.white,
  });

  @override
  State<SignaturePadWidget> createState() => _SignaturePadWidgetState();
}

class _SignaturePadWidgetState extends State<SignaturePadWidget> {
  final GlobalKey<SfSignaturePadState> _signatureKey = GlobalKey();
  Uint8List? _signatureImage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Signature Pad
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusM),
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.radiusM),
            child: SfSignaturePad(
              key: _signatureKey,
              backgroundColor: widget.backgroundColor,
              strokeColor: widget.penColor,
              minimumStrokeWidth: widget.strokeWidth,
              maximumStrokeWidth: widget.strokeWidth,
            ),
          ),
        ),

        const SizedBox(height: Dimensions.spaceL),

        // Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton.icon(
              onPressed: _clearSignature,
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('مسح'),
            ),

            if (_signatureImage != null)
              Image.memory(_signatureImage!, width: 80, height: 40),

            ElevatedButton.icon(
              onPressed: _saveSignature,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('حفظ'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _saveSignature() async {
    if (_signatureKey.currentState == null ||
        _signatureKey.currentState != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى التوقيع أولاً')));
      return;
    }

    final ui.Image image = await _signatureKey.currentState!.toImage(
      pixelRatio: 3.0,
    );

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) return;

    final bytes = byteData.buffer.asUint8List();

    setState(() {
      _signatureImage = bytes;
    });

    widget.onSigned(bytes);
  }

  void _clearSignature() {
    _signatureKey.currentState?.clear();
    setState(() => _signatureImage = null);
    widget.onSigned(null);
  }
}
