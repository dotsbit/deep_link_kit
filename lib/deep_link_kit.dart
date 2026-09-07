/// Flutter SDK for DeepLinkKit — Firebase Dynamic Links–style API backed by mlink.
///
/// Create:
/// ```dart
/// final short = await DeepLinkKit.instance.buildShortLink(
///   DynamicLinkParameters(
///     link: Uri.parse('https://example.com/product/123'),
///     uriPrefix: 'https://yourapp.deeplinkkit.com',
///   ),
/// );
/// ```
///
/// Receive:
/// ```dart
/// final initial = await DeepLinkKit.instance.getInitialLink();
/// DeepLinkKit.instance.onLink.listen((data) {
///   Navigator.pushNamed(context, data.link.path);
/// });
/// ```
library;

export 'src/deep_link_kit.dart';
export 'src/deep_link_kit_options.dart';
export 'src/exceptions.dart';
export 'src/models/pending_dynamic_link_data.dart';
export 'src/models/short_dynamic_link.dart';
export 'src/parameters/android_parameters.dart';
export 'src/parameters/dynamic_link_parameters.dart';
export 'src/parameters/google_analytics_parameters.dart';
export 'src/parameters/ios_parameters.dart';
export 'src/parameters/itunes_connect_analytics_parameters.dart';
export 'src/parameters/navigation_info_parameters.dart';
export 'src/parameters/short_dynamic_link_type.dart';
export 'src/parameters/social_meta_tag_parameters.dart';
