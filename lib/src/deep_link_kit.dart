import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:http/http.dart' as http;

import 'api/mlink_api.dart';
import 'deep_link_kit_options.dart';
import 'exceptions.dart';
import 'models/pending_dynamic_link_data.dart';
import 'models/short_dynamic_link.dart';
import 'parameters/dynamic_link_parameters.dart';
import 'parameters/short_dynamic_link_type.dart';

/// DeepLinkKit Dynamic Links SDK — drop-in style API for Firebase Dynamic Links.
///
/// ```dart
/// await DeepLinkKit.initialize(options: DeepLinkKitOptions(...));
///
/// final short = await DeepLinkKit.instance.buildShortLink(params);
/// final initial = await DeepLinkKit.instance.getInitialLink();
/// DeepLinkKit.instance.onLink.listen((data) { ... });
/// ```
class DeepLinkKit {
  static DeepLinkKit? _instance;

  final DeepLinkKitOptions options;
  final MlinkApi _api;
  final AppLinks _appLinks;
  final bool _ownsHttp;

  StreamController<PendingDynamicLinkData>? _onLinkController;
  StreamSubscription<Uri>? _uriSub;
  PendingDynamicLinkData? _cachedInitial;
  bool _initialResolved = false;

  DeepLinkKit._({
    required this.options,
    required this._api,
    required this._appLinks,
    required this._ownsHttp,
  });

  /// Shared singleton (like `FirebaseDynamicLinks.instance`).
  static DeepLinkKit get instance {
    final current = _instance;
    if (current == null) {
      throw StateError(
        'DeepLinkKit is not initialized. Call DeepLinkKit.initialize() first.',
      );
    }
    return current;
  }

  static bool get isInitialized => _instance != null;

  /// Initialize once at app startup (after `WidgetsFlutterBinding.ensureInitialized`).
  static Future<DeepLinkKit> initialize({
    required DeepLinkKitOptions options,
    http.Client? httpClient,
    AppLinks? appLinks,
  }) async {
    await _instance?.dispose();

    final ownsHttp = httpClient == null;
    final kit = DeepLinkKit._(
      options: options,
      api: MlinkApi(options: options, httpClient: httpClient),
      appLinks: appLinks ?? AppLinks(),
      ownsHttp: ownsHttp,
    );
    _instance = kit;
    return kit;
  }

  // ── Create (Firebase create docs) ─────────────────────────────────────────

  /// Builds a **long** Dynamic Link locally (no network).
  ///
  /// Encodes parameters as query args on [uriPrefix], similar to Firebase long links.
  Uri buildLink(DynamicLinkParameters parameters) {
    final prefix = _resolvePrefix(parameters);
    return _buildLongLinkUri(parameters, prefix);
  }

  /// Builds a **short** Dynamic Link via the mlink API (network call).
  Future<ShortDynamicLink> buildShortLink(
    DynamicLinkParameters parameters, {
    ShortDynamicLinkType shortLinkType = ShortDynamicLinkType.short,
  }) async {
    final prefix = _resolvePrefix(parameters);
    final created = await _api.createShortLink(
      parameters: parameters,
      uriPrefix: prefix,
      shortLinkType: shortLinkType,
    );
    return ShortDynamicLink(
      shortUrl: Uri.parse(created.url),
      previewLink: _buildLongLinkUri(parameters, prefix),
    );
  }

  // ── Receive (Firebase receive docs) ───────────────────────────────────────

  /// Returns the Dynamic Link that opened the app from a terminated state.
  Future<PendingDynamicLinkData?> getInitialLink() async {
    if (_initialResolved) return _cachedInitial;
    _initialResolved = true;

    try {
      final uri = await _appLinks.getInitialLink();
      if (uri == null) {
        _cachedInitial = null;
        return null;
      }
      _cachedInitial = await getDynamicLink(uri);
      return _cachedInitial;
    } catch (e) {
      throw DeepLinkKitException('getInitialLink failed', cause: e);
    }
  }

  /// Stream of Dynamic Links while the app is in background / foreground.
  Stream<PendingDynamicLinkData> get onLink {
    _ensureListening();
    return _onLinkController!.stream;
  }

  /// Resolves a Dynamic Link URL (short `/l/{code}`, long query, or custom scheme).
  Future<PendingDynamicLinkData?> getDynamicLink(Uri link) async {
    // Long link: ?link=https://...
    final embedded = link.queryParameters['link'];
    if (embedded != null && embedded.isNotEmpty) {
      final deep = Uri.tryParse(embedded);
      if (deep != null) {
        return PendingDynamicLinkData(
          link: deep,
          shortLink: _isShortPath(link) ? link : null,
          utmParameters: _utmFrom(link),
          minimumAppVersion: int.tryParse(link.queryParameters['amv'] ?? ''),
          iosMinimumVersion: link.queryParameters['imv'],
        );
      }
    }

    // HTTPS short: https://{host}/l/{code}
    if (_isOurHost(link) && _isShortPath(link)) {
      final code = link.pathSegments.length >= 2 ? link.pathSegments[1] : null;
      if (code == null || code.isEmpty) return null;

      final resolved = await _api.resolveShortCode(code);
      if (resolved == null) return null;

      return PendingDynamicLinkData(
        link: _uriFromDeepLinkPath(
          resolved.deepLinkPath,
          fallback: resolved.destinationUrl,
        ),
        shortLink: Uri.parse(resolved.url),
        utmParameters: {
          ..._utmFrom(link),
          ...resolved.utmParameters,
        },
        minimumAppVersion: resolved.androidMinimumVersion,
        iosMinimumVersion: resolved.iosMinimumVersion,
      );
    }

    // Custom scheme handoff: yourapp://product/123
    final scheme = options.customScheme?.toLowerCase();
    if (scheme != null &&
        scheme.isNotEmpty &&
        link.scheme.toLowerCase() == scheme) {
      final path = _pathFromCustomScheme(link);
      return PendingDynamicLinkData(
        link: _uriFromDeepLinkPath(path),
        utmParameters: link.queryParameters,
      );
    }

    // Fallback: treat path as deep link if on our host
    if (_isOurHost(link) && link.path.isNotEmpty && link.path != '/') {
      return PendingDynamicLinkData(
        link: link,
        utmParameters: _utmFrom(link),
      );
    }

    return null;
  }

  Future<void> dispose() async {
    await _uriSub?.cancel();
    _uriSub = null;
    await _onLinkController?.close();
    _onLinkController = null;
    if (_ownsHttp) {
      _api.dispose();
    }
    if (identical(_instance, this)) {
      _instance = null;
    }
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  void _ensureListening() {
    if (_onLinkController != null) return;
    _onLinkController = StreamController<PendingDynamicLinkData>.broadcast(
      onListen: () {
        _uriSub ??= _appLinks.uriLinkStream.listen(
          (uri) async {
            try {
              final data = await getDynamicLink(uri);
              if (data != null && !(_onLinkController?.isClosed ?? true)) {
                _onLinkController!.add(data);
              }
            } catch (e, st) {
              if (!(_onLinkController?.isClosed ?? true)) {
                _onLinkController!.addError(e, st);
              }
            }
          },
          onError: (Object e, StackTrace st) {
            if (!(_onLinkController?.isClosed ?? true)) {
              _onLinkController!.addError(e, st);
            }
          },
        );
      },
    );
  }

  String _resolvePrefix(DynamicLinkParameters parameters) {
    final raw = parameters.uriPrefix?.trim();
    if (raw != null && raw.isNotEmpty) {
      return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
    }
    return options.normalizedUriPrefix;
  }

  Uri _buildLongLinkUri(DynamicLinkParameters p, String prefix) {
    final qp = <String, String>{
      'link': p.link.toString(),
    };

    final android = p.androidParameters;
    if (android != null) {
      qp['apn'] = android.packageName;
      if (android.fallbackUrl != null) {
        qp['afl'] = android.fallbackUrl.toString();
      }
      if (android.minimumVersion != null) {
        qp['amv'] = '${android.minimumVersion}';
      }
    }

    final ios = p.iosParameters;
    if (ios != null) {
      qp['ibi'] = ios.bundleId;
      if (ios.appStoreId != null) qp['isi'] = ios.appStoreId!;
      if (ios.fallbackUrl != null) qp['ifl'] = ios.fallbackUrl.toString();
      if (ios.customScheme != null) qp['ius'] = ios.customScheme!;
      if (ios.ipadFallbackUrl != null) {
        qp['ipfl'] = ios.ipadFallbackUrl.toString();
      }
      if (ios.ipadBundleId != null) qp['ipbi'] = ios.ipadBundleId!;
      if (ios.minimumVersion != null) qp['imv'] = ios.minimumVersion!;
    }

    final social = p.socialMetaTagParameters;
    if (social != null) {
      if (social.title != null) qp['st'] = social.title!;
      if (social.description != null) qp['sd'] = social.description!;
      if (social.imageUrl != null) qp['si'] = social.imageUrl.toString();
    }

    final ga = p.googleAnalyticsParameters;
    if (ga != null) {
      if (ga.source != null) qp['utm_source'] = ga.source!;
      if (ga.medium != null) qp['utm_medium'] = ga.medium!;
      if (ga.campaign != null) qp['utm_campaign'] = ga.campaign!;
      if (ga.term != null) qp['utm_term'] = ga.term!;
      if (ga.content != null) qp['utm_content'] = ga.content!;
    }

    final iTunes = p.itunesConnectAnalyticsParameters;
    if (iTunes != null) {
      if (iTunes.providerToken != null) qp['pt'] = iTunes.providerToken!;
      if (iTunes.affiliateToken != null) qp['at'] = iTunes.affiliateToken!;
      if (iTunes.campaignToken != null) qp['ct'] = iTunes.campaignToken!;
    }

    if (p.navigationInfoParameters?.forcedRedirectEnabled == true) {
      qp['efr'] = '1';
    }

    return Uri.parse(prefix).replace(queryParameters: qp);
  }

  bool _isOurHost(Uri uri) {
    final host = uri.host.toLowerCase();
    if (host.isEmpty) return false;
    return host == options.appHost.toLowerCase();
  }

  bool _isShortPath(Uri uri) {
    final segments = uri.pathSegments;
    return segments.length >= 2 && segments.first == 'l' && segments[1].isNotEmpty;
  }

  Map<String, String> _utmFrom(Uri uri) {
    final out = <String, String>{};
    for (final key in [
      'utm_source',
      'utm_medium',
      'utm_campaign',
      'utm_term',
      'utm_content',
    ]) {
      final v = uri.queryParameters[key];
      if (v != null) out[key] = v;
    }
    return out;
  }

  Uri _uriFromDeepLinkPath(String path, {String? fallback}) {
    if (fallback != null) {
      final dest = Uri.tryParse(fallback);
      if (dest != null && (dest.isScheme('http') || dest.isScheme('https'))) {
        return dest;
      }
    }

    final split = path.split('?');
    final purePath = split.first.isEmpty ? '/' : split.first;
    final query = split.length > 1 ? split[1] : null;

    // Synthetic https URI so callers can use `.path` like Firebase examples.
    return Uri(
      scheme: 'https',
      host: 'link.local',
      path: purePath.startsWith('/') ? purePath : '/$purePath',
      query: query,
    );
  }

  String _pathFromCustomScheme(Uri uri) {
    final buffer = StringBuffer();
    if (uri.host.isNotEmpty) {
      buffer.write('/${uri.host}');
    }
    if (uri.path.isNotEmpty && uri.path != '/') {
      final path = uri.path.startsWith('/') ? uri.path : '/${uri.path}';
      buffer.write(buffer.isEmpty ? path : path);
    }
    final result = buffer.toString();
    if (result.isEmpty) return '/';
    if (!uri.hasQuery) return result;
    return '$result?${uri.query}';
  }
}
