<?php

final class PublicReviewIntelligence
{
    public const VERSION = 'pri-v1';
    public const MIN_SIGNALS = 5;
    public const MIN_SOURCE_TYPES = 2;

    public static function sourceEligible(array $source): bool
    {
        return ($source['status'] ?? 'active') === 'active'
            && ($source['access_policy'] ?? 'pending_review') === 'permitted';
    }

    public static function calculate(array $rows, ?DateTimeImmutable $now = null): array
    {
        $now = $now ?: new DateTimeImmutable('now', new DateTimeZone('UTC'));
        $usable = [];
        foreach ($rows as $row) {
            if (!self::sourceEligible($row)) continue;
            if (!empty($row['duplicate_suspected']) || !empty($row['spam_suspected'])) continue;
            if (!isset($row['sentiment_score']) || !is_numeric($row['sentiment_score'])) continue;
            $usable[] = $row;
        }

        $sourceTypes = array_values(array_unique(array_filter(array_map(fn($r) => (string)($r['source_type'] ?? ''), $usable))));
        if (count($usable) < self::MIN_SIGNALS || count($sourceTypes) < self::MIN_SOURCE_TYPES) {
            return [
                'score_5' => null,
                'positive_sentiment_pct' => null,
                'confidence_score' => self::confidence($usable, count($sourceTypes), 0.0),
                'confidence_label' => 'insufficient',
                'sources_analyzed' => count($usable),
                'source_type_count' => count($sourceTypes),
                'insufficient_data' => true,
                'methodology_version' => self::VERSION,
            ];
        }

        $weighted = 0.0;
        $weightTotal = 0.0;
        $positiveWeight = 0.0;
        $sentiments = [];
        foreach ($usable as $row) {
            $sentiment = max(-1.0, min(1.0, (float)$row['sentiment_score']));
            $sentiments[] = $sentiment;
            $confidence = max(0.25, min(1.0, (float)($row['source_confidence'] ?? 0.5)));
            $recency = self::recencyWeight($row['source_published_at'] ?? null, $now);
            $weight = $confidence * $recency;
            $weighted += $sentiment * $weight;
            $weightTotal += $weight;
            if ($sentiment > 0.15) $positiveWeight += $weight;
        }

        $mean = $weightTotal > 0 ? $weighted / $weightTotal : 0.0;
        $score5 = round(($mean + 1.0) * 2.5, 2);
        $positivePct = $weightTotal > 0 ? round(($positiveWeight / $weightTotal) * 100, 2) : null;
        $consistency = self::consistency($sentiments);
        $confidence = self::confidence($usable, count($sourceTypes), $consistency);

        return [
            'score_5' => max(0.0, min(5.0, $score5)),
            'positive_sentiment_pct' => $positivePct,
            'confidence_score' => $confidence,
            'confidence_label' => self::confidenceLabel($confidence),
            'sources_analyzed' => count($usable),
            'source_type_count' => count($sourceTypes),
            'insufficient_data' => false,
            'methodology_version' => self::VERSION,
        ];
    }

    private static function recencyWeight($publishedAt, DateTimeImmutable $now): float
    {
        if (!$publishedAt) return 0.70;
        try {$date = new DateTimeImmutable((string)$publishedAt, new DateTimeZone('UTC'));}
        catch (Throwable $e) {return 0.70;}
        $days = max(0, (int)$date->diff($now)->format('%a'));
        // 365-day half-life, bounded so older public experience still contributes.
        return max(0.35, pow(0.5, $days / 365));
    }

    private static function consistency(array $sentiments): float
    {
        if (count($sentiments) < 2) return 0.0;
        $mean = array_sum($sentiments) / count($sentiments);
        $variance = array_sum(array_map(fn($x) => ($x - $mean) ** 2, $sentiments)) / count($sentiments);
        $sd = sqrt($variance);
        return max(0.0, min(1.0, 1.0 - ($sd / 1.0)));
    }

    private static function confidence(array $rows, int $sourceTypeCount, float $consistency): float
    {
        $n = count($rows);
        if ($n === 0) return 0.0;
        $avgSourceConfidence = array_sum(array_map(fn($r) => max(0.0, min(1.0, (float)($r['source_confidence'] ?? 0.0))), $rows)) / $n;
        $volume = 1.0 - exp(-$n / 12.0); // diminishing returns
        $diversity = min(1.0, $sourceTypeCount / 4.0);
        $score = (0.35 * $avgSourceConfidence) + (0.25 * $volume) + (0.25 * $diversity) + (0.15 * $consistency);
        return round(max(0.0, min(1.0, $score)), 3);
    }

    private static function confidenceLabel(float $confidence): string
    {
        if ($confidence >= 0.80) return 'high';
        if ($confidence >= 0.60) return 'medium';
        return 'low';
    }
}
