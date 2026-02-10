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
  SignaturePadWidgetState createState() => SignaturePadWidgetState();
}

class SignaturePadWidgetState extends State<SignaturePadWidget> {
  final GlobalKey<SfSignaturePadState> _signatureKey = GlobalKey();
  Uint8List? _signatureImage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
      ],
    );
  }

  // ===== Public API =====

  void clear() {
    _signatureKey.currentState?.clear();
    setState(() => _signatureImage = null);
    widget.onSigned(null);
  }

  bool get hasSignature =>
      _signatureKey.currentState != null && _signatureKey.currentState != null;

  Future<Uint8List?> getSignature() async {
    if (!hasSignature) return null;

    final ui.Image image = await _signatureKey.currentState!.toImage(
      pixelRatio: 3.0,
    );

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData?.buffer.asUint8List();
  }
}
