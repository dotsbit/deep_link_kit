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

    test('toCreateApiJson sends nested SDK fields', () {
      final body = DynamicLinkParameters(
        link: Uri.parse('https://www.example.com/product/123?ref=1'),
        androidParameters: AndroidParameters(
          packageName: 'com.example.app',
          fallbackUrl: Uri.parse('https://play.google.com/store'),
          minimumVersion: 30,
        ),
        iosParameters: const IOSParameters(
          bundleId: 'com.example.app.ios',
          appStoreId: '123456789',
          customScheme: 'example',
          ipadBundleId: 'com.example.app.ipad',
          minimumVersion: '14.0',
        ),
        socialMetaTagParameters: SocialMetaTagParameters(
          title: 'Sale',
          description: 'Summer',
          imageUrl: Uri.parse('https://cdn.example.com/og.png'),
        ),
        googleAnalyticsParameters: const GoogleAnalyticsParameters(
          source: 'twitter',
          medium: 'social',
          campaign: 'promo',
        ),
        itunesConnectAnalyticsParameters: const ItunesConnectAnalyticsParameters(
          providerToken: 'pt1',
          campaignToken: 'ct1',
        ),
        navigationInfoParameters: const NavigationInfoParameters(
          forcedRedirectEnabled: true,
        ),
      ).toCreateApiJson();

      expect(body['deep_link_path'], '/product/123?ref=1');
      expect(body['destination_url'], 'https://www.example.com/product/123?ref=1');
      expect(body['title'], 'Sale');
      expect(body['android'], {
        'package_name': 'com.example.app',
        'fallback_url': 'https://play.google.com/store',
        'minimum_version': 30,
      });
      expect(body['ios']['bundle_id'], 'com.example.app.ios');
      expect(body['ios']['ipad_bundle_id'], 'com.example.app.ipad');
      expect(body['social']['image_url'], 'https://cdn.example.com/og.png');
      expect(body['google_analytics']['source'], 'twitter');
      expect(body['itunes']['provider_token'], 'pt1');
      expect(body['navigation']['forced_redirect_enabled'], isTrue);
    });
  });
}
