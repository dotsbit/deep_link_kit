import 'android_parameters.dart';
import 'google_analytics_parameters.dart';
import 'ios_parameters.dart';
import 'itunes_connect_analytics_parameters.dart';
import 'navigation_info_parameters.dart';
import 'social_meta_tag_parameters.dart';

/// Parameters for building a Dynamic Link (Firebase [DynamicLinkParameters] parity).
class DynamicLinkParameters {
  /// The deep link your app opens (content URL / payload).
  final Uri link;

  /// Dynamic Link URL prefix, e.g. `https://yourapp.deeplinkkit.com`.
  ///
  /// Falls back to [DeepLinkKitOptions.uriPrefix] when null.
  final String? uriPrefix;

  final AndroidParameters? androidParameters;
  final IOSParameters? iosParameters;
  final SocialMetaTagParameters? socialMetaTagParameters;
  final GoogleAnalyticsParameters? googleAnalyticsParameters;
  final ItunesConnectAnalyticsParameters? itunesConnectAnalyticsParameters;
  final NavigationInfoParameters? navigationInfoParameters;

  const DynamicLinkParameters({
    required this.link,
    this.uriPrefix,
    this.androidParameters,
    this.iosParameters,
    this.socialMetaTagParameters,
    this.googleAnalyticsParameters,
    this.itunesConnectAnalyticsParameters,
    this.navigationInfoParameters,
  });

  /// Path (+ query) sent to mlink as `deep_link_path`.
  String get deepLinkPath {
    final path = link.path.isEmpty ? '/' : link.path;
    if (!link.hasQuery) return path.startsWith('/') ? path : '/$path';
    final withQuery = '$path?${link.query}';
    return withQuery.startsWith('/') ? withQuery : '/$withQuery';
  }

  /// Web destination: the http(s) content URL, else Android/iOS fallback.
  String? get destinationUrl {
    if (link.isScheme('http') || link.isScheme('https')) {
      return link.toString();
    }
    return androidParameters?.fallbackUrl?.toString() ??
        iosParameters?.fallbackUrl?.toString();
  }

  /// JSON body for `POST /api/v1/links` (nested groups + flat social title).
  Map<String, dynamic> toCreateApiJson() {
    final body = <String, dynamic>{
      'deep_link_path': deepLinkPath,
      'destination_url': ?destinationUrl,
    };

    final social = socialMetaTagParameters;
    if (social != null) {
      body.addAll({
        'title': ?social.title,
        'description': ?social.description,
      });
      final nested = <String, dynamic>{
        'title': ?social.title,
        'description': ?social.description,
        'image_url': ?social.imageUrl?.toString(),
      };
      if (nested.isNotEmpty) body['social'] = nested;
    }

    final android = androidParameters;
    if (android != null) {
      body['android'] = <String, dynamic>{
        'package_name': android.packageName,
        'fallback_url': ?android.fallbackUrl?.toString(),
        'minimum_version': ?android.minimumVersion,
      };
    }

    final ios = iosParameters;
    if (ios != null) {
      body['ios'] = <String, dynamic>{
        'bundle_id': ios.bundleId,
        'app_store_id': ?ios.appStoreId,
        'fallback_url': ?ios.fallbackUrl?.toString(),
        'custom_scheme': ?ios.customScheme,
        'ipad_fallback_url': ?ios.ipadFallbackUrl?.toString(),
        'ipad_bundle_id': ?ios.ipadBundleId,
        'minimum_version': ?ios.minimumVersion,
      };
    }

    final ga = googleAnalyticsParameters;
    if (ga != null) {
      final nested = <String, dynamic>{
        'source': ?ga.source,
        'medium': ?ga.medium,
        'campaign': ?ga.campaign,
        'term': ?ga.term,
        'content': ?ga.content,
      };
      if (nested.isNotEmpty) body['google_analytics'] = nested;
    }

    final itunes = itunesConnectAnalyticsParameters;
    if (itunes != null) {
      final nested = <String, dynamic>{
        'provider_token': ?itunes.providerToken,
        'affiliate_token': ?itunes.affiliateToken,
        'campaign_token': ?itunes.campaignToken,
      };
      if (nested.isNotEmpty) body['itunes'] = nested;
    }

    if (navigationInfoParameters?.forcedRedirectEnabled == true) {
      body['navigation'] = const {'forced_redirect_enabled': true};
    }

    return body;
  }
}
