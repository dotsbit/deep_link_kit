/// Android-specific Dynamic Link parameters (Firebase API parity).
class AndroidParameters {
  final String packageName;
  final Uri? fallbackUrl;
  final int? minimumVersion;

  const AndroidParameters({
    required this.packageName,
    this.fallbackUrl,
    this.minimumVersion,
  });
}
