import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/image_item.dart';
import '../services/compressor_service.dart';
import '../widgets/image_card.dart';
import 'preview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<ImageItem> _images = [];

  bool _isProcessing = false;
  int _processedCount = 0;
  int _totalCount = 0;

  Future<void> _pickImages() async {
    try {
      final picked = await _picker.pickMultiImage();
      if (picked.isEmpty) return;

      final List<ImageItem> newItems = [];
      for (final file in picked) {
        final bytes = await file.readAsBytes();
        newItems.add(ImageItem(
          id: DateTime.now().microsecondsSinceEpoch.toString() + file.name,
          fileName: file.name,
          originalBytes: bytes,
        ));
      }

      setState(() {
        _images.addAll(newItems);
      });

      if (mounted) {
        _showSnack('${newItems.length} টি ছবি যোগ হয়েছে');
      }
    } catch (e) {
      _showSnack('ছবি সিলেক্ট করা যায়নি: $e');
    }
  }

  Future<void> _autoCompressAll() async {
    if (_images.isEmpty || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _processedCount = 0;
      _totalCount = _images.length;
    });

    for (int i = 0; i < _images.length; i++) {
      await _autoCompressOne(_images[i]);
      if (mounted) {
        setState(() {
          _processedCount = i + 1;
        });
      }
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
      _showSnack('সব ছবি কমপ্রেস করা হয়েছে');
    }
  }

  Future<void> _autoCompressOne(ImageItem item) async {
    Uint8List working = item.originalBytes;
    int lastGoodSize = item.originalSize;
    int levelIndex = -1;

    // প্রতিটা লেভেল চেক করো, অরিজিনাল থেকে কমপ্রেস করো,
    // সবচেয়ে ছোট যেটা পাওয়া যায় সেটা রাখো।
    for (int l = 0; l < compressionLevels.length; l++) {
      final result = await CompressorService.compressInIsolate(
        item.originalBytes,
        compressionLevels[l],
      );

      if (result == null) continue;

      if (result.length < lastGoodSize) {
        lastGoodSize = result.length;
        working = result;
        levelIndex = l;
      }

      // ৯০KB এর নিচে চলে গেলে থামো
      if (result.length < 90 * 1024) break;
    }

    if (levelIndex >= 0) {
      if (mounted) {
        setState(() {
          final idx = _images.indexWhere((e) => e.id == item.id);
          if (idx != -1) {
            _images[idx].addVersion(working, levelIndex);
          }
        });
      }
    }
  }

  Future<void> _compressMore(ImageItem item) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final currentLevel =
        item.levelHistory.isEmpty ? -1 : item.levelHistory.last;
    final nextLevel = currentLevel + 1;

    if (nextLevel >= compressionLevels.length) {
      _showSnack('সর্বোচ্চ কমপ্রেশন লেভেলে পৌঁছে গেছে');
      setState(() => _isProcessing = false);
      return;
    }

    final result = await CompressorService.compressInIsolate(
      item.originalBytes,
      compressionLevels[nextLevel],
    );

    if (result != null && result.length < item.currentSize) {
      setState(() {
        final idx = _images.indexWhere((e) => e.id == item.id);
        if (idx != -1) {
          _images[idx].addVersion(result, nextLevel);
        }
      });
    } else {
      _showSnack('এই লেভেলে আর কমছে না');
    }

    setState(() => _isProcessing = false);
  }

  void _undo(ImageItem item) {
    setState(() {
      final idx = _images.indexWhere((e) => e.id == item.id);
      if (idx != -1) _images[idx].undoLastVersion();
    });
  }

  void _openPreview(ImageItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PreviewScreen(item: item)),
    );
  }

  void _remove(ImageItem item) {
    setState(() {
      _images.removeWhere((e) => e.id == item.id);
    });
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalOriginal = _images.fold<int>(0, (s, e) => s + e.originalSize);
    final totalCurrent = _images.fold<int>(0, (s, e) => s + e.currentSize);
    final totalSaved = totalOriginal - totalCurrent;
    final totalPercent =
        totalOriginal == 0 ? 0.0 : (totalSaved / totalOriginal) * 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PhotoForge'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Column(
        children: [
          if (_images.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_images.length} টি ছবি',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${totalPercent.toStringAsFixed(1)}% কমেছে',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: totalPercent > 50
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),

          if (_isProcessing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value:
                        _totalCount == 0 ? null : _processedCount / _totalCount,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'প্রসেস হচ্ছে $_processedCount / $_totalCount',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _images.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: _images.length,
                    itemBuilder: (_, i) => ImageCard(
                      item: _images[i],
                      onCompressMore: () => _compressMore(_images[i]),
                      onUndo: () => _undo(_images[i]),
                      onPreview: () => _openPreview(_images[i]),
                      onRemove: () => _remove(_images[i]),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: _images.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _isProcessing ? null : _autoCompressAll,
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('অটো কমপ্রেস'),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isProcessing ? null : _pickImages,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('ছবি যোগ করুন'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'এখনো কোনো ছবি নেই',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'নিচের বাটন থেকে ছবি সিলেক্ট করুন',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
