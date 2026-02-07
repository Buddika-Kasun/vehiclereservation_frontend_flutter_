import 'package:flutter/material.dart';

class DownloadProgressDialog extends StatefulWidget {
  final String fileName;
  final double fileSize;
  final Future<void> Function(Function(double) onProgress) downloadTask;

  const DownloadProgressDialog({
    Key? key,
    required this.fileName,
    required this.fileSize,
    required this.downloadTask,
  }) : super(key: key);

  @override
  _DownloadProgressDialogState createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
  double _progress = 0.0;
  bool _downloading = true;
  String _status = 'Preparing download...';

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      await widget.downloadTask((progress) {
        if (mounted) {
          setState(() {
            _progress = progress;
            _status = 'Downloading: ${(progress * 100).toStringAsFixed(1)}%';
          });
        }
      });

      if (mounted) {
        setState(() {
          _downloading = false;
          _status = 'Download complete!';
        });
      }

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _status = 'Download failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Downloading Update'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.fileName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 8,
          ),
          const SizedBox(height: 12),
          Text(_status, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(_progress * widget.fileSize).toStringAsFixed(1)} MB',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
                ),
              ),
              Text(
                ' / ${widget.fileSize.toStringAsFixed(1)} MB',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (_downloading)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('CANCEL'),
          ),
      ],
    );
  }
}
