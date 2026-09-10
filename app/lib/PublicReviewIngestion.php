<?php

require_once __DIR__.'/PublicReviewIntelligence.php';

final class PublicReviewIngestion
{
    public const ANALYSIS_VERSION = 'pri-analysis-v1';

    public static function validateSource(array $source): void
    {
        if (($source['status'] ?? 'active') !== 'active') {
            throw new RuntimeException('Source is not active.');
        }
        if (($source['access_policy'] ?? 'pending_review') !== 'permitted') {
            throw new RuntimeException('Source is not permitted for Public Review Intelligence analysis.');
        }
    }

    public static function normalizeDerivedSignal(array $raw): array
    {
        if (!isset($raw['sentiment_score']) || !is_numeric($raw['sentiment_score'])) {
            throw new InvalidArgumentException('Missing or invalid sentiment_score.');
        }
        $sentiment = max(-1.0, min(1.0, (float)$raw['sentiment_score']));
        $label = $raw['sentiment_label'] ?? ($sentiment > 0.15 ? 'positive' : ($sentiment < -0.15 ? 'negative' : 'mixed'));
        $allowedLabels = ['positive','negative','neutral','mixed'];
        if (!in_array($label, $allowedLabels, true)) $label = 'mixed';

        $rating = null;
        $scale = null;
        if (isset($raw['public_rating']) && is_numeric($raw['public_rating'])) {
            $rating = (float)$raw['public_rating'];
            $scale = isset($raw['public_rating_scale']) && is_numeric($raw['public_rating_scale']) ? (float)$raw['public_rating_scale'] : 5.0;
            if ($scale <= 0 || $rating < 0 || $rating > $scale) {
                throw new InvalidArgumentException('Invalid public rating/scale.');
            }
        }

        $topics = self::normalizeStringList($raw['topics'] ?? []);
        $reviewerContext = is_array($raw['reviewer_context'] ?? null) ? $raw['reviewer_context'] : [];
        $sourceConfidence = isset($raw['source_confidence']) && is_numeric($raw['source_confidence'])
            ? max(0.0, min(1.0, (float)$raw['source_confidence'])) : 0.5;

        return [
            'sentiment_score' => $sentiment,
            'sentiment_label' => $label,
            'public_rating' => $rating,
            'public_rating_scale' => $scale,
            'topics' => $topics,
            'reviewer_context' => $reviewerContext,
            'source_confidence' => $sourceConfidence,
            'duplicate_suspected' => !empty($raw['duplicate_suspected']),
            'spam_suspected' => !empty($raw['spam_suspected']),
        ];
    }

    public static function analyzePermittedSources(array $sources, callable $analyzer, ?DateTimeImmutable $now = null): array
    {
        $rows = [];
        $excluded = 0;
        foreach ($sources as $source) {
            try {
                self::validateSource($source);
            } catch (Throwable $e) {
                $excluded++;
                continue;
            }

            $derived = self::normalizeDerivedSignal($analyzer($source));
            $rows[] = array_merge($source, $derived);
        }

        return [
            'analysis_version' => self::ANALYSIS_VERSION,
            'source_count' => count($sources),
            'eligible_source_count' => count($rows),
            'excluded_source_count' => $excluded,
            'signals' => $rows,
            'intelligence' => PublicReviewIntelligence::calculate($rows, $now),
        ];
    }

    public static function contentFingerprint(string $content): string
    {
        $normalized = mb_strtolower(trim(preg_replace('/\s+/u', ' ', $content)));
        return hash('sha256', $normalized, true);
    }

    public static function urlHash(string $url): string
    {
        return hash('sha256', trim($url), true);
    }

    private static function normalizeStringList($value): array
    {
        if (!is_array($value)) return [];
        $out = [];
        foreach ($value as $item) {
            if (!is_string($item)) continue;
            $item = trim($item);
            if ($item === '' || mb_strlen($item) > 120) continue;
            $out[$item] = true;
        }
        return array_slice(array_keys($out), 0, 20);
    }
}
