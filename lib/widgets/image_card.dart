import 'package:flutter/material.dart';
import '../models/image_item.dart';

class ImageCard extends StatelessWidget {
  final ImageItem item;
  final VoidCallback onCompressMore;
  final VoidCallback onUndo;
  final VoidCallback onPreview;
  final VoidCallback onRemove;

  const ImageCard({
    super.key,
    required this.item,
    required this.onCompressMore,
    required this.onUndo,
    required this.onPreview,
    required this.onRemove,
  });

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final percent = item.compressionPercent;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onPreview,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  item.currentBytes,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'আগে: ${_formatSize(item.originalSize)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    'এখন: ${_formatSize(item.currentSize)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                  ),
                  if (item.isCompressed) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${percent.toStringAsFixed(1)}% কমেছে',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: percent > 50
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      if (item.canUndo)
                        _smallBtn(
                          icon: Icons.undo,
                          label: 'আগের',
                          color: Colors.orange,
                          onTap: onUndo,
                        ),
                      _smallBtn(
                        icon: Icons.compress,
                        label: 'আরও',
                        color: Colors.blue,
                        onTap: onCompressMore,
                      ),
                      _smallBtn(
                        icon: Icons.remove_red_eye,
                        label: 'দেখুন',
                        color: Colors.purple,
                        onTap: onPreview,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onRemove,
              tooltip: 'বাদ দিন',
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
