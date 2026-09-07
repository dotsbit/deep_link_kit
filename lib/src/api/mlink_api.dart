import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../deep_link_kit_options.dart';
import '../exceptions.dart';
import '../parameters/dynamic_link_parameters.dart';
import '../parameters/short_dynamic_link_type.dart';

/// HTTP helpers for mlink create + resolve.
class MlinkApi {
  final DeepLinkKitOptions options;
  final http.Client _http;

  MlinkApi({required this.options, http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  Uri get _createEndpoint {
    final override = options.createLinkUrl?.trim();
    if (override != null && override.isNotEmpty) {
      return Uri.parse(override);
    }
    return Uri.parse('${options.normalizedApiBaseUrl}/api/v1/links');
  }

  Uri _resolveEndpoint(String code) =>
      Uri.parse('${options.normalizedApiBaseUrl}/api/v1/links/$code');

  /// Creates a short link via `POST /api/v1/links`.
  Future<({String url, String shortCode, String deepLinkPath})> createShortLink({
    required DynamicLinkParameters parameters,
    required String uriPrefix,
    ShortDynamicLinkType shortLinkType = ShortDynamicLinkType.short,
  }) async {
    final body = parameters.toCreateApiJson();
    if (shortLinkType == ShortDynamicLinkType.unguessable) {
      body['short_code'] = _unguessableCode();
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final key = options.apiKey?.trim();
    if (key != null && key.isNotEmpty) {
      headers['Authorization'] = 'Bearer $key';
    } else if (options.createLinkUrl == null ||
        options.createLinkUrl!.trim().isEmpty) {
      throw const DeepLinkKitException(
        'Provide apiKey or createLinkUrl to build short links.',
      );
    }

    late final http.Response response;
    try {
      response = await _http.post(
        _createEndpoint,
        headers: headers,
        body: jsonEncode(body),
      );
    } catch (e) {
      throw DeepLinkKitException('Failed to create short link', cause: e);
    }

    final map = _decodeMap(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw DeepLinkKitException(
        map?['error'] as String? ??
            'Create short link failed (${response.statusCode})',
        code: response.statusCode,
      );
    }

    final link = map?['link'];
    if (link is! Map<String, dynamic>) {
      throw DeepLinkKitException(
        'Unexpected create response',
        code: response.statusCode,
      );
    }

    return (
      url: link['url'] as String,
      shortCode: link['short_code'] as String,
      deepLinkPath: link['deep_link_path'] as String,
    );
  }

  /// Resolves `GET /api/v1/links/:code`.
  Future<
      ({
        String deepLinkPath,
        String? destinationUrl,
        String url,
        Map<String, String> utmParameters,
        int? androidMinimumVersion,
        String? iosMinimumVersion,
      })?> resolveShortCode(String code) async {
    late final http.Response response;
    try {
      response = await _http.get(
        _resolveEndpoint(code),
        headers: const {'Accept': 'application/json'},
      );
    } catch (e) {
      throw DeepLinkKitException('Failed to resolve short link', cause: e);
    }

    if (response.statusCode == 404) return null;
    final map = _decodeMap(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw DeepLinkKitException(
        map?['error'] as String? ??
            'Resolve failed (${response.statusCode})',
        code: response.statusCode,
      );
    }

    final link = map?['link'];
    if (link is! Map<String, dynamic>) return null;

    return (
      deepLinkPath: link['deep_link_path'] as String,
      destinationUrl: link['destination_url'] as String?,
      url: link['url'] as String,
      utmParameters: _utmFromLinkJson(link),
      androidMinimumVersion: _androidMinimumVersion(link),
      iosMinimumVersion: _iosMinimumVersion(link),
    );
  }

  void dispose() => _http.close();

  static Map<String, String> _utmFromLinkJson(Map<String, dynamic> link) {
    final out = <String, String>{};
    final nested = link['google_analytics'];
    final ga = nested is Map<String, dynamic> ? nested : const <String, dynamic>{};
    const keys = {
      'utm_source': 'source',
      'utm_medium': 'medium',
      'utm_campaign': 'campaign',
      'utm_term': 'term',
      'utm_content': 'content',
    };
    for (final entry in keys.entries) {
      final value = link[entry.key] ?? ga[entry.value] ?? ga[entry.key];
      if (value is String && value.isNotEmpty) {
        out[entry.key] = value;
      }
    }
    return out;
  }

  static int? _androidMinimumVersion(Map<String, dynamic> link) {
    final nested = link['android'];
    final raw = nested is Map<String, dynamic>
        ? (nested['minimum_version'] ?? link['android_minimum_version'])
        : link['android_minimum_version'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String && raw.isNotEmpty) return int.tryParse(raw);
    return null;
  }

  static String? _iosMinimumVersion(Map<String, dynamic> link) {
    final nested = link['ios'];
    final raw = nested is Map<String, dynamic>
        ? nested['minimum_version']
        : link['ios_minimum_version'];
    if (raw is String && raw.isNotEmpty) return raw;
    return null;
  }

  static String _unguessableCode() {
    const alphabet =
        'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(17, (_) => alphabet[rand.nextInt(alphabet.length)])
        .join();
  }

  static Map<String, dynamic>? _decodeMap(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}
