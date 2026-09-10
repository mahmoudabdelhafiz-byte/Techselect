<?php

final class PublicReviewSourcePolicy
{
    public const VERSION = 'pri-source-policy-v1';

    public static function catalog(): array
    {
        return [
            'reddit' => self::row('Reddit / public discussions','permitted_with_review','Manual/admin-supplied public snapshots only. Respect platform terms, rate limits, attribution and copyright; no bulk copying of review text.','Review terms before first use and again on material policy changes.'),
            'public_forum' => self::row('Public forums / communities','permitted_with_review','Use only publicly accessible pages where analysis/reuse is allowed. Manual snapshot first; do not bypass authentication, paywalls or technical controls.','Check site terms and robots/access rules before approval.'),
            'app_store' => self::row('Public app-store reviews','permitted_with_review','Prefer official APIs/feeds where available. Manual snapshot is acceptable only where public access and intended analysis are permitted.','Re-check store API/terms before automation.'),
            'vendor_community' => self::row('Vendor community / public forum','permitted_with_review','Use public user commentary only when vendor community terms permit analysis. Distinguish vendor-authored marketing from user feedback.','Document the policy basis in source notes.'),
            'independent_blog' => self::row('Independent blog / implementation commentary','permitted_with_review','Analyze public commentary without republishing long copyrighted passages. Keep source URL and derived signals only.','Prefer identifiable original publications over scraped mirrors.'),
            'public_case_study' => self::row('Public case study / implementation story','permitted_with_review','Useful as implementation evidence, but treat vendor-sponsored case studies as lower-independence context rather than neutral user reviews.','Record sponsorship/vendor authorship in notes.'),
            'review_aggregator' => self::row('Commercial review aggregator','restricted_pending_legal_check','Do not ingest by default. Many commercial review platforms restrict scraping, copying or derivative reuse. Use only with an API/license or explicit terms basis that permits the intended use.','Legal/terms review required before any source can be marked permitted.'),
            'g2' => self::row('G2','restricted_pending_legal_check','Restricted by default. Do not scrape or use AI to bypass platform restrictions. Require an approved API/license/terms basis for the intended analysis/reuse.','Keep restricted unless written policy review documents permission.'),
            'capterra' => self::row('Capterra','restricted_pending_legal_check','Restricted by default. Do not scrape or use AI to bypass platform restrictions. Require an approved API/license/terms basis for the intended analysis/reuse.','Keep restricted unless written policy review documents permission.'),
            'other_public' => self::row('Other public source','restricted_pending_legal_check','Unknown source types require a manual terms/access review before approval. Public availability alone does not make reuse automatically permitted.','Reviewer must document why the specific source is allowed.'),
        ];
    }

    public static function guidanceFor(string $sourceType): array
    {
        $catalog = self::catalog();
        return $catalog[$sourceType] ?? $catalog['other_public'];
    }

    public static function mayAutoPermit(string $sourceType): bool
    {
        // Governance presets are advisory only; every source still requires an explicit human policy decision.
        return false;
    }

    private static function row(string $label, string $preset, string $basis, string $review): array
    {
        return [
            'label' => $label,
            'preset' => $preset,
            'policy_basis' => $basis,
            'review_requirement' => $review,
            'auto_permit' => false,
            'policy_version' => self::VERSION,
        ];
    }
}
