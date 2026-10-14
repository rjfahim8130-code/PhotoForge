import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class CompressionLevel {
  final int maxDimension;
  final int quality;
  final String label;

  const CompressionLevel({
    required this.maxDimension,
    required this.quality,
    required this.label,
  });
}

const List<CompressionLevel> compressionLevels = [
  CompressionLevel(maxDimension: 2400, quality: 90, label: 'L1 (2400px)'),
  CompressionLevel(maxDimension: 1920, quality: 85, label: 'L2 (1920px)'),
  CompressionLevel(maxDimension: 1600, quality: 80, label: 'L3 (1600px)'),
  CompressionLevel(maxDimension: 1280, quality: 75, label: 'L4 (1280px)'),
  CompressionLevel(maxDimension: 1080, quality: 70, label: 'L5 (1080px)'),
  CompressionLevel(maxDimension: 900, quality: 65, label: 'L6 (900px)'),
  CompressionLevel(maxDimension: 720, quality: 60, label: 'L7 (720px)'),
  CompressionLevel(maxDimension: 600, quality: 55, label: 'L8 (600px)'),
  CompressionLevel(maxDimension: 480, quality: 50, label: 'L9 (480px)'),
  CompressionLevel(maxDimension: 360, quality: 45, label: 'L10 (360px)'),
];

class CompressorService {
  static Future<Uint8List?> compressAtLevel(
    Uint8List inputBytes,
    CompressionLevel level,
  ) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        inputBytes,
        minWidth: level.maxDimension,
        minHeight: level.maxDimension,
        quality: level.quality,
        format: CompressFormat.png,
      );
      return Uint8List.fromList(result);
    } catch (e) {
      return null;
    }
  }

  static Future<Uint8List?> compressInIsolate(
    Uint8List inputBytes,
    CompressionLevel level,
  ) async {
    return await Isolate.run(() => compressAtLevel(inputBytes, level));
  }
}
