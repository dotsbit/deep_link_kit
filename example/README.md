# deep_link_kit example

Flutter demo for creating and receiving Dynamic Links with `deep_link_kit`.

## Run

```bash
cd example
flutter pub get
flutter run \
  --dart-define=DLK_API_BASE=https://deeplinkkit.com \
  --dart-define=DLK_URI_PREFIX=https://yourapp.deeplinkkit.com \
  --dart-define=DLK_API_KEY=dk_live_YOUR_SECRET \
  --dart-define=DLK_CUSTOM_SCHEME=yourapp
```

## What it shows

1. **Create** — `buildLink`, `buildShortLink`, `ShortDynamicLinkType.unguessable`
2. **Receive** — `getInitialLink` (cold start) + `onLink` (warm)

## Platform notes

- **Android**: intent filters for `https://yourapp.deeplinkkit.com/l/*` and `yourapp://` are in `AndroidManifest.xml` — change the host/scheme to match your dashboard app.
- **iOS**: custom scheme `yourapp` is in `Info.plist`. Add Associated Domains `applinks:yourapp.deeplinkkit.com` in Xcode for Universal Links.
