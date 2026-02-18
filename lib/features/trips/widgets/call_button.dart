// lib/features/trips/widgets/call_button.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/utils/optional_permission_manager%20copy.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/widgets/message_overlay.dart';

class CallButton extends StatelessWidget {
  final String? phoneNumber;
  final String? contactName;
  final double iconSize;
  final double buttonSize;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback? onCallStart;
  final VoidCallback? onCallEnd;
  final bool showSnackbarOnSuccess;

  const CallButton({
    Key? key,
    required this.phoneNumber,
    this.contactName,
    this.iconSize = 16,
    this.buttonSize = 32,
    this.iconColor = Colors.green,
    this.backgroundColor = Colors.green,
    this.onCallStart,
    this.onCallEnd,
    this.showSnackbarOnSuccess = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool hasPhone =
        phoneNumber != null &&
        phoneNumber!.isNotEmpty &&
        phoneNumber != 'Unknown' &&
        phoneNumber != 'Not Assigned';

    if (!hasPhone) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.phone_disabled, size: 12, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(
              'No phone',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _makePhoneCall(context),
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: backgroundColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.phone, color: iconColor, size: iconSize),
      ),
    );
  }

  Future<void> _makePhoneCall(BuildContext context) async {
    if (phoneNumber == null) return;

    try {
      // Callback when call starts
      onCallStart?.call();

      // Clean the phone number
      String cleanedNumber = phoneNumber!.trim();

      // Validate phone number format
      if (cleanedNumber.isEmpty) {
        MessageOverlay.showError(
          context: context,
          message: 'Phone number is empty',
          position: OverlayPosition.top,
          showBackgroundOverlay: true,
          showOkButton: true,
        );
        return;
      }

      // Check if we have permission first
      final hasPermission =
          await OptionalPermissionManager.requestPhonePermission(
            context: context,
            rationaleMessage: 'Phone permission is required to make calls',
          );

      if (!hasPermission) {
        MessageOverlay.showError(
          context: context,
          message: 'Cannot make call without permission',
          position: OverlayPosition.top,
          showBackgroundOverlay: true,
          showOkButton: true,
        );
        return;
      }

      // Create URL with proper format
      final url = 'tel:$cleanedNumber';
      final uri = Uri.parse(url);

      print('📞 Attempting to call: $cleanedNumber');

      // Check if we can launch
      bool canLaunch = await canLaunchUrl(uri);

      if (canLaunch) {
        await launchUrl(uri);

        // Show success message
        if (showSnackbarOnSuccess) {
          MessageOverlay.showSuccess(
            context: context,
            message: contactName != null
                ? 'Calling $contactName...'
                : 'Opening dialer...',
            position: OverlayPosition.top,
            showBackgroundOverlay: true,
            duration: const Duration(seconds: 2),
          );
        }

        onCallEnd?.call();
      } else {
        // Fallback: Try to open dialer with number manually
        await _launchDialerFallback(context, cleanedNumber);
      }
    } catch (e, stackTrace) {
      print('❌ Error making call: $e');
      print('❌ Stack trace: $stackTrace');

      MessageOverlay.showError(
        context: context,
        message:
            'Unable to make call: ${e.toString().substring(0, min(50, e.toString().length))}',
        position: OverlayPosition.top,
        showBackgroundOverlay: true,
        showOkButton: true,
      );

      onCallEnd?.call();
    }
  }

  // Alternative method for opening dialer
  Future<void> _launchDialerFallback(
    BuildContext context,
    String phoneNumber,
  ) async {
    try {
      // Try different URL formats
      final String url = 'tel:$phoneNumber';
      final Uri uri = Uri.parse(url);

      // Try launching directly without checking first
      await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (showSnackbarOnSuccess) {
        MessageOverlay.showSuccess(
          context: context,
          message: 'Opening dialer...',
          position: OverlayPosition.top,
          showBackgroundOverlay: true,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      print('❌ Fallback also failed: $e');

      // Show dialog with options
      _showNoDialerDialog(context, phoneNumber);
    }
  }

  // Dialog when no dialer is found
  Future<void> _showNoDialerDialog(
    BuildContext context,
    String phoneNumber,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Cannot Make Call',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'No phone app found to make calls.\n\n'
            'Phone number: $phoneNumber\n\n'
            'You can manually dial this number.',
            style: TextStyle(color: Colors.grey[300]),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Copy Number',
                style: TextStyle(color: Color(0xFFF9C80E)),
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: phoneNumber));
                Navigator.of(context).pop();

                MessageOverlay.showSuccess(
                  context: context,
                  message: 'Phone number copied to clipboard',
                  position: OverlayPosition.top,
                  showBackgroundOverlay: true,
                  duration: const Duration(seconds: 2),
                );
              },
            ),
            TextButton(
              child: const Text('OK', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
