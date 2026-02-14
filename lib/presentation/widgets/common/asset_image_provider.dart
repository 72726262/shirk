import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

class AssetImageProvider extends ImageProvider<AssetImageProvider> {
  final String assetName;

  const AssetImageProvider(this.assetName);

  @override
  Future<AssetImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<AssetImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(AssetImageProvider key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
    );
  }

  Future<ui.Codec> _loadAsync(AssetImageProvider key, ImageDecoderCallback decode) async {
    // Return a simple 1x1 transparent image as fallback
    final data = Uint8List.fromList([0, 0, 0, 0]);
    final buffer = await ui.ImmutableBuffer.fromUint8List(data);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AssetImageProvider && runtimeType == other.runtimeType && assetName == other.assetName;

  @override
  int get hashCode => assetName.hashCode;

  @override
  String toString() => 'AssetImageProvider("$assetName")';
}
