import 'dart:html' as html;
import 'dart:typed_data';

/// Web-only download function
void downloadFileWeb(Uint8List fileBytes, String fileName, String format) {
  // Determine MIME type based on format
  final mimeType = format == 'pdf'
      ? 'application/pdf'
      : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  // Create a blob from the bytes
  final blob = html.Blob([fileBytes], mimeType);

  // Create a URL for the blob
  final url = html.Url.createObjectUrlFromBlob(blob);

  // Create an anchor element and trigger download
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();

  // Clean up the URL after download
  html.Url.revokeObjectUrl(url);
}
