/// Navigation / preview-page parameters (Firebase API parity).
class NavigationInfoParameters {
  /// When true, skip the app preview page and open the app/store directly (iOS).
  final bool forcedRedirectEnabled;

  const NavigationInfoParameters({
    this.forcedRedirectEnabled = false,
  });
}
