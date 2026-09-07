import 'package:deep_link_kit/deep_link_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const options = DeepLinkKitOptions(
    apiBaseUrl: 'https://deeplinkkit.com',
    uriPrefix: 'https://demo.deeplinkkit.com',
    customScheme: 'demo',
    apiKey: 'dk_live_test_key_for_unit_tests',
  );

  setUp(() async {
    await DeepLinkKit.initialize(options: options);
  });

  tearDown(() async {
    await DeepLinkKit.instance.dispose();
  });

  group('buildLink', () {
    test('encodes Firebase-style long Dynamic Link query params', () {
      final long = DeepLinkKit.instance.buildLink(
        DynamicLinkParameters(
          link: Uri.parse('https://www.example.com/product/123'),
          uriPrefix: 'https://demo.deeplinkkit.com',
          androidParameters: const AndroidParameters(
            packageName: 'com.example.app',
            minimumVersion: 30,
          ),
          iosParameters: const IOSParameters(
            bundleId: 'com.example.app.ios',
            appStoreId: '123456789',
          ),
          socialMetaTagParameters: const SocialMetaTagParameters(
            title: 'Sale',
            description: 'Summer',
          ),
          googleAnalyticsParameters: const GoogleAnalyticsParameters(
            source: 'twitter',
            medium: 'social',
            campaign: 'promo',
          ),
        ),
      );

      expect(long.scheme, 'https');
      expect(long.host, 'demo.deeplinkkit.com');
      expect(
        long.queryParameters['link'],
        'https://www.example.com/product/123',
      );
      expect(long.queryParameters['apn'], 'com.example.app');
      expect(long.queryParameters['ibi'], 'com.example.app.ios');
      expect(long.queryParameters['st'], 'Sale');
      expect(long.queryParameters['utm_source'], 'twitter');
    });
  });

  group('getDynamicLink', () {
    test('parses long link ?link= parameter locally', () async {
      final long = DeepLinkKit.instance.buildLink(
        DynamicLinkParameters(
          link: Uri.parse('https://www.example.com/invite?ref=1'),
          googleAnalyticsParameters: const GoogleAnalyticsParameters(
            source: 'email',
          ),
        ),
      );

      final pending = await DeepLinkKit.instance.getDynamicLink(long);
      expect(pending, isNotNull);
      expect(pending!.link.toString(), 'https://www.example.com/invite?ref=1');
      expect(pending.utmParameters['utm_source'], 'email');
    });

    test('parses custom scheme into PendingDynamicLinkData.link.path', () async {
      final pending = await DeepLinkKit.instance.getDynamicLink(
        Uri.parse('demo://product/123'),
      );
      expect(pending, isNotNull);
      expect(pending!.link.path, '/product/123');
    });
  });

  group('DynamicLinkParameters mapping', () {
    test('options expose appHost from uriPrefix', () {
      expect(options.appHost, 'demo.deeplinkkit.com');
    });
  });
}
