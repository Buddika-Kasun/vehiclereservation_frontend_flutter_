import 'dart:typed_data';

/// Stub for mobile platforms
void downloadFileWeb(Uint8List fileBytes, String fileName, String format) {
  // No-op for mobile
  throw UnsupportedError('Web download is not supported on this platform');
}
