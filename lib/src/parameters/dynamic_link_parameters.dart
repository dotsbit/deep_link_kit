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
}
