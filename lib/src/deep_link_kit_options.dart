/// Configuration for [DeepLinkKit], similar to Firebase project options.
class DeepLinkKitOptions {
  /// Apex API host, e.g. `https://deeplinkkit.com` (not `dashboard.…`).
  final String apiBaseUrl;

  /// App API secret (`dk_live_…`). Prefer a backend [createLinkUrl] proxy in production.
  final String? apiKey;

  /// Optional backend proxy that creates links (forwards to mlink with a server-side key).
  final String? createLinkUrl;

  /// Default Dynamic Links URI prefix / tenant host, e.g. `https://yourapp.deeplinkkit.com`.
  ///
  /// Used when [DynamicLinkParameters.uriPrefix] is omitted and to recognize
  /// incoming Universal / App Links.
  final String uriPrefix;

  /// Custom URL scheme for landing-page handoff (e.g. `yourapp`).
  final String? customScheme;

  const DeepLinkKitOptions({
    required this.apiBaseUrl,
    required this.uriPrefix,
    this.apiKey,
    this.createLinkUrl,
    this.customScheme,
  });

  String get normalizedApiBaseUrl {
    final t = apiBaseUrl.trim();
    return t.endsWith('/') ? t.substring(0, t.length - 1) : t;
  }

  String get normalizedUriPrefix {
    final t = uriPrefix.trim();
    return t.endsWith('/') ? t.substring(0, t.length - 1) : t;
  }

  /// Host portion of [uriPrefix] (e.g. `yourapp.deeplinkkit.com`).
  String get appHost => Uri.parse(normalizedUriPrefix).host;
}
