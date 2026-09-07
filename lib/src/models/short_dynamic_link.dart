/// Result of [DeepLinkKit.buildShortLink] (Firebase [ShortDynamicLink] parity).
class ShortDynamicLink {
  /// Short shareable URL, e.g. `https://yourapp.deeplinkkit.com/l/abc12xyz`.
  final Uri shortUrl;

  /// Equivalent long Dynamic Link (query-encoded parameters).
  final Uri previewLink;

  /// Warnings from the builder (empty for mlink).
  final List<String> warnings;

  const ShortDynamicLink({
    required this.shortUrl,
    required this.previewLink,
    this.warnings = const [],
  });
}
