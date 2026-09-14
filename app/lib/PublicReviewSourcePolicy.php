<?php

final class PublicReviewSourcePolicy
{
    public const VERSION = 'pri-source-policy-v2';
    private const BLOCKED_TYPES = ['g2','capterra'];
    private const BLOCKED_HOSTS = ['g2.com','capterra.com'];

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
            'g2' => self::row('G2','blocked','TechSelectAI does not ingest or publish G2-derived Public Review Intelligence.','Blocked by product policy; do not override in admin source review.'),
            'capterra' => self::row('Capterra','blocked','TechSelectAI does not ingest or publish Capterra-derived Public Review Intelligence.','Blocked by product policy; do not override in admin source review.'),
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
        // Governance presets are advisory only; every non-blocked source still requires an explicit human policy decision.
        return false;
    }

    public static function isBlocked(string $sourceType, string $url=''): bool
    {
        if (in_array(strtolower(trim($sourceType)), self::BLOCKED_TYPES, true)) return true;
        $host = strtolower((string)parse_url(trim($url), PHP_URL_HOST));
        $host = preg_replace('/^www\./', '', $host);
        foreach (self::BLOCKED_HOSTS as $blocked) {
            if ($host === $blocked || str_ends_with($host, '.' . $blocked)) return true;
        }
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
