/// iOS-specific Dynamic Link parameters (Firebase API parity).
class IOSParameters {
  final String bundleId;
  final String? appStoreId;
  final Uri? fallbackUrl;
  final String? customScheme;
  final Uri? ipadFallbackUrl;
  final String? ipadBundleId;
  final String? minimumVersion;

  const IOSParameters({
    required this.bundleId,
    this.appStoreId,
    this.fallbackUrl,
    this.customScheme,
    this.ipadFallbackUrl,
    this.ipadBundleId,
    this.minimumVersion,
  });
}
