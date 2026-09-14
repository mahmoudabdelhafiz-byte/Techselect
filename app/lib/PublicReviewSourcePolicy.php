<?php

final class PublicReviewSourcePolicy
{
    public const VERSION = 'pri-source-policy-v3';
    private const BLOCKED_TYPES = ['g2','capterra'];
    private const BLOCKED_HOSTS = ['g2.com','capterra.com'];

    public static function catalog(): array
    {
        return [
            'reddit' => self::row('Reddit / public discussions','trusted_feed_only','Automatic collection is permitted only through TechSelectAI configured public RSS/search feeds with conservative rates. No authentication bypass or bulk republication of review text.','Machine policy verifies the Reddit host; unsupported Reddit acquisition methods remain restricted.',true),
            'public_forum' => self::row('Public forums / communities','trusted_api_only','Automatic collection is permitted for TechSelectAI trusted public APIs such as Stack Exchange. Other forums remain restricted until a supported collector and policy basis exist.','Machine policy verifies the connector and host.',true),
            'app_store' => self::row('Public app-store reviews','official_api_or_feed','Automatic collection is permitted through official/authorized APIs and Apple public customer-review feeds configured by TechSelectAI.','Machine policy verifies app-store hosts and connector types.',true),
            'vendor_community' => self::row('Vendor community / public forum','restricted_pending_policy','Vendor-community terms vary; do not auto-collect unless a dedicated trusted collector is added.','Document the access basis before collection.',false),
            'independent_blog' => self::row('Independent blog / implementation commentary','restricted_pending_policy','Analyze public commentary only through a dedicated supported collector with a documented reuse basis.','Prefer original publications over mirrors.',false),
            'public_case_study' => self::row('Public case study / implementation story','restricted_pending_policy','Treat case studies as implementation context, not neutral review evidence, unless a dedicated source policy permits automated analysis.','Record sponsorship/vendor authorship.',false),
            'review_aggregator' => self::row('Commercial review aggregator','restricted_pending_legal_check','Do not ingest by default. Use only with an API/license or explicit terms basis that permits the intended use.','Legal/terms review required before any connector is supported.',false),
            'g2' => self::row('G2','blocked','TechSelectAI does not ingest or publish G2-derived Public Review Intelligence.','Blocked by product policy; do not override.',false),
            'capterra' => self::row('Capterra','blocked','TechSelectAI does not ingest or publish Capterra-derived Public Review Intelligence.','Blocked by product policy; do not override.',false),
            'other_public' => self::row('Other public source','trusted_collector_only','Unknown public sources remain restricted. Hacker News is permitted only through the configured public Algolia-backed collector and public item links.','Machine policy verifies the exact trusted hosts.',false),
        ];
    }

    public static function guidanceFor(string $sourceType): array
    {
        $catalog = self::catalog();
        return $catalog[$sourceType] ?? $catalog['other_public'];
    }

    public static function mayAutoPermit(string $sourceType): bool
    {
        return !empty(self::guidanceFor($sourceType)['auto_permit']);
    }

    public static function machineDecision(string $sourceType,string $url,string $connectorType=''): string
    {
        if(self::isBlocked($sourceType,$url))return 'blocked';
        $host=strtolower((string)parse_url(trim($url),PHP_URL_HOST));$host=preg_replace('/^www\./','',$host);
        $connectorType=strtolower(trim($connectorType));$sourceType=strtolower(trim($sourceType));
        if($sourceType==='app_store'&&in_array($host,['play.google.com','apps.apple.com','itunes.apple.com','androidpublisher.googleapis.com'],true))return 'permitted';
        if($sourceType==='reddit'&&($host==='reddit.com'||str_ends_with($host,'.reddit.com')))return 'permitted';
        if($sourceType==='public_forum'&&($host==='stackoverflow.com'||str_ends_with($host,'.stackoverflow.com')||$host==='stackexchange.com'||str_ends_with($host,'.stackexchange.com')||($connectorType==='stackexchange_api'&&$host==='api.stackexchange.com')))return 'permitted';
        if($sourceType==='other_public'&&in_array($host,['hn.algolia.com','news.ycombinator.com'],true))return 'permitted';
        return 'restricted';
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

    private static function row(string $label,string $preset,string $basis,string $review,bool $autoPermit): array
    {
        return ['label'=>$label,'preset'=>$preset,'policy_basis'=>$basis,'review_requirement'=>$review,'auto_permit'=>$autoPermit,'policy_version'=>self::VERSION];
    }
}
