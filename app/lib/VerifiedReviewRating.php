<?php

final class VerifiedReviewRating
{
    public const VERSION = 'verified-reviews-v1';
    public const PRIOR_MEAN = 3.75;
    public const PRIOR_WEIGHT = 5.0;

    public static function calculate(array $reviews): array
    {
        $weightedSum = 0.0;
        $weightTotal = 0.0;
        $approvedCount = 0;
        $verificationWeightSum = 0.0;

        foreach ($reviews as $review) {
            if (($review['moderation_status'] ?? '') !== 'approved') continue;
            if (!isset($review['overall_rating']) || !is_numeric($review['overall_rating'])) continue;

            $rating = (float)$review['overall_rating'];
            if ($rating < 1 || $rating > 5) continue;

            $verificationWeight = self::verificationWeight($review['verification_level'] ?? 'email_verified');
            $recencyWeight = self::recencyWeight($review['published_at'] ?? $review['submitted_at'] ?? null);
            $weight = $verificationWeight * $recencyWeight;

            $weightedSum += $rating * $weight;
            $weightTotal += $weight;
            $verificationWeightSum += $verificationWeight;
            $approvedCount++;
        }

        if ($approvedCount === 0 || $weightTotal <= 0) {
            return [
                'rating_5' => null,
                'approved_review_count' => 0,
                'weighted_review_count' => 0.0,
                'verification_confidence' => 0.0,
                'methodology_version' => self::VERSION,
            ];
        }

        $bayesian = (($weightedSum) + (self::PRIOR_MEAN * self::PRIOR_WEIGHT)) / ($weightTotal + self::PRIOR_WEIGHT);
        $confidence = min(1.0, ($weightTotal / 12.0)) * min(1.0, ($verificationWeightSum / max(1, $approvedCount)));

        return [
            'rating_5' => round(max(1.0, min(5.0, $bayesian)), 2),
            'approved_review_count' => $approvedCount,
            'weighted_review_count' => round($weightTotal, 3),
            'verification_confidence' => round($confidence, 3),
            'methodology_version' => self::VERSION,
        ];
    }

    public static function verificationWeight(string $level): float
    {
        return match ($level) {
            'admin_verified' => 1.00,
            'proof_of_use_verified' => 0.95,
            'business_domain_verified' => 0.85,
            'email_verified' => 0.70,
            default => 0.60,
        };
    }

    private static function recencyWeight($date): float
    {
        if (!$date) return 0.75;
        try {
            $published = new DateTimeImmutable((string)$date, new DateTimeZone('UTC'));
            $now = new DateTimeImmutable('now', new DateTimeZone('UTC'));
        } catch (Throwable $e) {
            return 0.75;
        }
        $days = max(0, (int)$published->diff($now)->format('%a'));
        return max(0.50, pow(0.5, $days / 730));
    }
}
