import 'package:flutter/material.dart';

class NotificationHelper {
  static OverlayEntry? _currentOverlayEntry;

  static void showNotificationToast(BuildContext context, {
    required String title,
    required String body,
    IconData icon = Icons.notifications,
    Color backgroundColor = Colors.black,
    Color textColor = Colors.white,
    Duration duration = const Duration(seconds: 2),
  }) {
    // Remove existing notification if visible
    _currentOverlayEntry?.remove();
    _currentOverlayEntry = null;

    final overlay = Overlay.of(context);
    
    _currentOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 10,
        right: 10,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: backgroundColor.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.yellow[600],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.black, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        body,
                        style: TextStyle(
                          color: textColor.withOpacity(0.9),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: textColor.withOpacity(0.5), size: 18),
                  onPressed: () {
                    _currentOverlayEntry?.remove();
                    _currentOverlayEntry = null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(_currentOverlayEntry!);

    // Auto-remove after duration
    Future.delayed(duration, () {
      _currentOverlayEntry?.remove();
      _currentOverlayEntry = null;
    });
  }
}
