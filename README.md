# deep_link_kit

Firebase Dynamic Links–style Flutter SDK for **DeepLinkKit (mlink)**.

Drop-in familiar API for teams migrating from [`firebase_dynamic_links`](https://firebase.google.com/docs/dynamic-links/flutter/create):

| Firebase | DeepLinkKit |
|----------|-------------|
| `FirebaseDynamicLinks.instance` | `DeepLinkKit.instance` |
| `DynamicLinkParameters` | `DynamicLinkParameters` |
| `buildLink` / `buildShortLink` | same |
| `getInitialLink` / `onLink` / `getDynamicLink` | same |
| `PendingDynamicLinkData` | same |

Uses [`app_links`](https://pub.dev/packages/app_links) `^7.2.1` and [`http`](https://pub.dev/packages/http).

## Example app

A full Flutter sample lives in [`example/`](example/):

```bash
cd example
flutter run \
  --dart-define=DLK_API_BASE=https://deeplinkkit.com \
  --dart-define=DLK_URI_PREFIX=https://yourapp.deeplinkkit.com \
  --dart-define=DLK_API_KEY=dk_live_YOUR_SECRET \
  --dart-define=DLK_CUSTOM_SCHEME=yourapp
```

It demonstrates `buildLink` / `buildShortLink` and `getInitialLink` / `onLink`.

## Install

```yaml
dependencies:
  deep_link_kit: ^0.1.0
```

```dart
await DeepLinkKit.initialize(
  options: const DeepLinkKitOptions(
    apiBaseUrl: 'https://deeplinkkit.com',
    uriPrefix: 'https://yourapp.deeplinkkit.com',
    apiKey: 'dk_live_YOUR_SECRET', // prefer createLinkUrl proxy in production
    customScheme: 'yourapp',
  ),
);
```

## Create Dynamic Links

Same shape as [Firebase create docs](https://firebase.google.com/docs/dynamic-links/flutter/create):

```dart
final dynamicLinkParams = DynamicLinkParameters(
  link: Uri.parse('https://www.example.com/product/123'),
  uriPrefix: 'https://yourapp.deeplinkkit.com',
  androidParameters: const AndroidParameters(
    packageName: 'com.example.app.android',
    minimumVersion: 30,
  ),
  iosParameters: const IOSParameters(
    bundleId: 'com.example.app.ios',
    appStoreId: '123456789',
    minimumVersion: '1.0.1',
  ),
  socialMetaTagParameters: SocialMetaTagParameters(
    title: 'Example of a Dynamic Link',
    description: 'This link works whether the app is installed or not',
    imageUrl: Uri.parse('https://example.com/image.png'),
  ),
  googleAnalyticsParameters: const GoogleAnalyticsParameters(
    source: 'twitter',
    medium: 'social',
    campaign: 'example-promo',
  ),
);

// Long link (local, no network)
final Uri longLink = DeepLinkKit.instance.buildLink(dynamicLinkParams);

// Short link (calls mlink POST /api/v1/links)
final ShortDynamicLink short =
    await DeepLinkKit.instance.buildShortLink(dynamicLinkParams);

print(short.shortUrl); // https://yourapp.deeplinkkit.com/l/abc12xyz

// Unguessable 17-char suffix
final ShortDynamicLink safe = await DeepLinkKit.instance.buildShortLink(
  dynamicLinkParams,
  shortLinkType: ShortDynamicLinkType.unguessable,
);
```

## Receive Dynamic Links

Same shape as [Firebase receive docs](https://firebase.google.com/docs/dynamic-links/flutter/receive):

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DeepLinkKit.initialize(
    options: const DeepLinkKitOptions(
      apiBaseUrl: 'https://deeplinkkit.com',
      uriPrefix: 'https://yourapp.deeplinkkit.com',
      customScheme: 'yourapp',
    ),
  );

  final PendingDynamicLinkData? initialLink =
      await DeepLinkKit.instance.getInitialLink();

  if (initialLink != null) {
    final Uri deepLink = initialLink.link;
    // Navigator.pushNamed(context, deepLink.path);
  }

  DeepLinkKit.instance.onLink.listen((PendingDynamicLinkData data) {
    final Uri deepLink = data.link;
    // Navigator.pushNamed(context, deepLink.path);
  }).onError((error) {
    // Handle errors
  });

  runApp(MyApp(initialLink: initialLink));
}
```

Resolve an exact short URL:

```dart
final PendingDynamicLinkData? data =
    await DeepLinkKit.instance.getDynamicLink(
  Uri.parse('https://yourapp.deeplinkkit.com/l/ke2Qa'),
);
```

## Platform setup

### Android (`AndroidManifest.xml`)

```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="https" android:host="yourapp.deeplinkkit.com" android:pathPrefix="/l"/>
</intent-filter>
```

### iOS

- Associated Domains: `applinks:yourapp.deeplinkkit.com`
- Custom URL scheme matching `customScheme` / dashboard setting

## How it maps to mlink

| SDK call | Backend |
|----------|---------|
| `buildShortLink` | `POST /api/v1/links` |
| `getDynamicLink` on `/l/{code}` | `GET /api/v1/links/{code}` |
| `buildLink` | Local query encoding (no network) |
| `getInitialLink` / `onLink` | `app_links` |

## License

MIT
