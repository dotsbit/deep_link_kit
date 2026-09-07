/// Data from an opened Dynamic Link (Firebase [PendingDynamicLinkData] parity).
class PendingDynamicLinkData {
  /// The deep link your app should navigate with (`link` parameter).
  final Uri link;

  /// The short / Universal Link URL when known.
  final Uri? shortLink;

  /// UTM / analytics parameters when present.
  final Map<String, String> utmParameters;

  /// Minimum Android versionCode requested by the link, if any.
  final int? minimumAppVersion;

  /// iOS minimum version string, if any.
  final String? iosMinimumVersion;

  const PendingDynamicLinkData({
    required this.link,
    this.shortLink,
    this.utmParameters = const {},
    this.minimumAppVersion,
    this.iosMinimumVersion,
  });

  @override
  String toString() =>
      'PendingDynamicLinkData(link: $link, shortLink: $shortLink)';
}
