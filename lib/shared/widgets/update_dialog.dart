import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/update_model.dart';

class UpdateDialog extends StatelessWidget {
  final AppUpdate update;
  final VoidCallback onUpdate;
  final VoidCallback? onLater;
  final bool isMandatory;

  const UpdateDialog({
    Key? key,
    required this.update,
    required this.onUpdate,
    this.onLater,
    this.isMandatory = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.update, color: Colors.blue),
          const SizedBox(width: 10),
          Text(
            update.updateTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Version Info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Version ${update.version} (Build ${update.buildNumber})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // File Size
            if (update.fileSize > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.sd_storage, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Size: ${update.fileSize.toStringAsFixed(1)} MB',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),

            // Description
            const Text(
              'What\'s New:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              update.updateDescription,
              style: const TextStyle(fontSize: 14),
            ),

            // Release Notes
            if (update.releaseNotes != null && update.releaseNotes!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Release Notes:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    update.releaseNotes!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),

            // Mandatory Warning
            if (isMandatory)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[100]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This is a mandatory update. You must update to continue using the app.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        if (!isMandatory && onLater != null)
          TextButton(onPressed: onLater, child: const Text('LATER')),
        ElevatedButton(
          onPressed: onUpdate,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            minimumSize: const Size(120, 48),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.download, size: 20),
              SizedBox(width: 8),
              Text('UPDATE NOW'),
            ],
          ),
        ),
      ],
    );
  }
}
