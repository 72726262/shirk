import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

class TransparentImageProvider extends ImageProvider<TransparentImageProvider> {
  const TransparentImageProvider();

  @override
  Future<TransparentImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<TransparentImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(TransparentImageProvider key, ImageDecoderCallback decode) {
    return OneFrameImageStreamCompleter(_loadAsync(key, decode));
  }

  Future<ImageInfo> _loadAsync(TransparentImageProvider key, ImageDecoderCallback decode) async {
    // Create a simple 1x1 transparent PNG
    final transparentPng = Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
      0x00, 0x00, 0x00, 0x0D, // IHDR chunk length
      0x49, 0x48, 0x44, 0x52, // IHDR
      0x00, 0x00, 0x00, 0x01, // width: 1
      0x00, 0x00, 0x00, 0x01, // height: 1
      0x08, 0x06, 0x00, 0x00, // bit depth: 8, color type: RGBA
      0x00, 0x00, 0x00, 0x00, // compression: 0, filter: 0, interlace: 0
      0x73, 0x65, 0x6E, 0x64, // CRC
      0x4A, 0x4E, 0x8B, 0x52, // IDAT
      0x00, 0x00, 0x00, 0x0C, // IDAT chunk length
      0x08, 0x99, 0x98, 0x96, // compressed data
      0x00, 0x00, 0x00, 0x00, // more compressed data
      0x00, 0x00, 0x00, 0x00, // more compressed data
      0x00, 0x00, 0x00, 0x00, // more compressed data
      0x00, 0x00, 0x00, 0x00, // IDAT CRC
      0x00, 0x00, 0x00, 0x00, // IEND chunk length
      0x49, 0x45, 0x4E, 0x44, // IEND
      0xAE, 0x42, 0x60, 0x82, // IEND CRC
    ]);

    final buffer = await ui.ImmutableBuffer.fromUint8List(transparentPng);
    final codec = await decode(buffer);
    final frame = await codec.getNextFrame();
    return ImageInfo(image: frame.image, scale: 1.0);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TransparentImageProvider;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'TransparentImageProvider()';
}
