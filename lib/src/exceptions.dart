/// Errors thrown by DeepLinkKit.
class DeepLinkKitException implements Exception {
  final String message;
  final int? code;
  final Object? cause;

  const DeepLinkKitException(this.message, {this.code, this.cause});

  @override
  String toString() =>
      'DeepLinkKitException${code != null ? ' ($code)' : ''}: $message';
}
