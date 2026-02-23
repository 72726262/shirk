/// Stub implementation for platforms that don't support download
Future<void> downloadImageToDevice(String url, String fileName) {
  throw UnsupportedError('Download not supported on this platform');
}
