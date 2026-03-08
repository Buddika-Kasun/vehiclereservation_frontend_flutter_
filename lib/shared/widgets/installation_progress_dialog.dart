import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/update_model.dart';

class InstallationProgressDialog extends StatefulWidget {
  final AppUpdate update;
  final VoidCallback? onCancel;

  const InstallationProgressDialog({
    super.key,
    required this.update,
    this.onCancel,
  });

  @override
  State<InstallationProgressDialog> createState() =>
      _InstallationProgressDialogState();
}

class _InstallationProgressDialogState
    extends State<InstallationProgressDialog> {
  String _status = 'Preparing installation...';
  double _progress = 0.0;
  bool _isInstalling = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Installing Update'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.system_update, size: 50, color: Colors.blue),
          const SizedBox(height: 16),
          Text(
            'Version ${widget.update.version}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(widget.update.updateTitle, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 16),
          Text(
            _status,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _isInstalling ? Colors.blue : Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (!_isInstalling) ...[
            const SizedBox(height: 16),
            const Icon(Icons.check_circle, size: 40, color: Colors.green),
          ],
        ],
      ),
      actions: [
        if (_isInstalling && widget.onCancel != null)
          TextButton(onPressed: widget.onCancel, child: const Text('Cancel')),
        if (!_isInstalling)
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
      ],
    );
  }

  void updateStatus(String status, double progress) {
    if (mounted) {
      setState(() {
        _status = status;
        _progress = progress;
      });
    }
  }

  void completeInstallation() {
    if (mounted) {
      setState(() {
        _isInstalling = false;
        _progress = 1.0;
        _status = 'Installation started successfully!';
      });
    }
  }
}
