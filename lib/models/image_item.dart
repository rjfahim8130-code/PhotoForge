import 'dart:typed_data';

class ImageItem {
  final String id;
  final String fileName;
  final Uint8List originalBytes;
  final List<Uint8List> versions;
  final List<int> levelHistory;

  ImageItem({
    required this.id,
    required this.fileName,
    required this.originalBytes,
    List<Uint8List>? versions,
    List<int>? levelHistory,
  })  : versions = versions ?? [],
        levelHistory = levelHistory ?? [];

  Uint8List get currentBytes =>
      versions.isEmpty ? originalBytes : versions.last;

  int get originalSize => originalBytes.length;
  int get currentSize => currentBytes.length;

  double get compressionPercent {
    if (originalSize == 0) return 0;
    return ((originalSize - currentSize) / originalSize) * 100;
  }

  bool get isCompressed => versions.isNotEmpty;
  bool get canUndo => versions.isNotEmpty;

  void addVersion(Uint8List bytes, int level) {
    versions.add(bytes);
    levelHistory.add(level);
  }

  void undoLastVersion() {
    if (versions.isNotEmpty) {
      versions.removeLast();
      levelHistory.removeLast();
    }
  }
}
