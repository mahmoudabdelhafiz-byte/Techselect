# Admin Advertising / Google AdSense

TechSelectAI provides an Admin/Super Admin-only Advertising screen at `/admin_advertising.php`.

## Setup
1. Apply `db/mysql/059_advertising_settings.sql`.
2. Open **Admin → Advertising**.
3. Paste either Google's full AdSense loader snippet or only the `ca-pub-...` client ID.
4. Enable Advertising and Auto Ads.
5. Select the public page types where the AdSense loader may run.

For safety, the application extracts and stores only the AdSense `ca-pub-...` client ID. Arbitrary pasted JavaScript is not persisted or executed.

## Current page coverage
Advertising can be enabled independently for public:
- software pages
- category pages
- capability pages
- integration pages
- comparison pages

These routes share `crawlable_public_page.php`, which injects the AdSense loader only when the database setting is enabled for that page type.

## Neutrality boundary
Advertising is display-only. `AdvertisingSettings` must not be imported by scoring, evaluation, recommendation, shortlist, community-intelligence, ROI/TCO, RFP or Decision Pack logic. No sponsored signal changes product order or Fit Score.

## Deployment
The migration must run before the Admin setting can persist. Until then, advertising fails closed and public pages render without AdSense.
