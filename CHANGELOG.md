## 0.1.1

- `buildShortLink` sends Android, iOS, social, UTM, iTunes, and navigation fields
- `getDynamicLink` reads UTM and minimum-version from `GET /api/v1/links/:code`

## 0.1.0

- Firebase Dynamic Links–style Flutter API
- `buildLink` / `buildShortLink` with `DynamicLinkParameters`
- `getInitialLink` / `onLink` / `getDynamicLink` with `PendingDynamicLinkData`
- Backed by mlink HTTP API + `app_links` ^7.2.1
