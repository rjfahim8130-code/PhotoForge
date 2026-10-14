import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/image_item.dart';

class PreviewScreen extends StatefulWidget {
  final ImageItem item;

  const PreviewScreen({super.key, required this.item});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  late int _versionIndex;

  @override
  void initState() {
    super.initState();
    _versionIndex = widget.item.versions.isEmpty
        ? -1
        : widget.item.versions.length - 1;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Uint8List get _displayBytes {
    if (_versionIndex == -1) return widget.item.originalBytes;
    return widget.item.versions[_versionIndex];
  }

  String get _versionLabel {
    if (_versionIndex == -1) return 'অরিজিনাল';
    return 'লেভেল ${widget.item.levelHistory[_versionIndex] + 1}';
  }

  @override
  Widget build(BuildContext context) {
    final size = _displayBytes.length;
    final originalSize = widget.item.originalSize;
    final saved = originalSize - size;
    final percent = originalSize == 0 ? 0.0 : (saved / originalSize) * 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('প্রিভিউ'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('অরিজিনাল: ${_formatSize(originalSize)}'),
                    Text('এখন: ${_formatSize(size)}'),
                    Text(
                      '${percent.toStringAsFixed(1)}% কমেছে',
                      style: TextStyle(
                        color: percent > 50
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: Container(
                color: Colors.grey.shade100,
                child: Center(
                  child: Image.memory(
                    _displayBytes,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ),
          ),
          if (widget.item.versions.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                children: [
                  Text(
                    'ভার্সন: $_versionLabel',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Slider(
                    value: _versionIndex.toDouble(),
                    min: -1,
                    max: (widget.item.versions.length - 1).toDouble(),
                    divisions: widget.item.versions.length,
                    label: _versionLabel,
                    onChanged: (v) {
                      setState(() {
                        _versionIndex = v.round();
                      });
                    },
                  ),
                  const Text(
                    'বাম দিকে অরিজিনাল, ডান দিকে সর্বোচ্চ কমপ্রেশন',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
