/// iTunes Connect analytics parameters (Firebase API parity).
class ItunesConnectAnalyticsParameters {
  final String? providerToken;
  final String? affiliateToken;
  final String? campaignToken;

  const ItunesConnectAnalyticsParameters({
    this.providerToken,
    this.affiliateToken,
    this.campaignToken,
  });
}
