/// Google Analytics / UTM parameters (Firebase API parity).
class GoogleAnalyticsParameters {
  final String? source;
  final String? medium;
  final String? campaign;
  final String? term;
  final String? content;

  const GoogleAnalyticsParameters({
    this.source,
    this.medium,
    this.campaign,
    this.term,
    this.content,
  });
}
