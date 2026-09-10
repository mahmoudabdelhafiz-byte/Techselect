<?php

final class PublicReviewAiAnalyzer
{
    public const ANALYZER_VERSION = 'pri-openai-v1';

    public static function analyze(string $content, array $source = []): array
    {
        $apiKey = trim((string)getenv('OPENAI_API_KEY'));
        $model = trim((string)getenv('TECHSELECT_PRI_MODEL'));
        if ($apiKey === '' || $model === '') {
            throw new RuntimeException('PRI AI analyzer is not configured. Set OPENAI_API_KEY and TECHSELECT_PRI_MODEL on the server.');
        }
        $content = trim($content);
        if ($content === '') throw new InvalidArgumentException('Review content snapshot is required.');
        if (mb_strlen($content) > 30000) $content = mb_substr($content, 0, 30000);

        $schema = [
            'type' => 'object',
            'additionalProperties' => false,
            'properties' => [
                'sentiment_score' => ['type' => 'number', 'minimum' => -1, 'maximum' => 1],
                'sentiment_label' => ['type' => 'string', 'enum' => ['positive','negative','neutral','mixed']],
                'public_rating' => ['type' => ['number','null']],
                'public_rating_scale' => ['type' => ['number','null']],
                'topics' => ['type' => 'array', 'items' => ['type' => 'string'], 'maxItems' => 12],
                'reviewer_context' => ['type' => 'object', 'additionalProperties' => ['type' => ['string','number','boolean','null']]],
                'source_confidence' => ['type' => 'number', 'minimum' => 0, 'maximum' => 1],
                'duplicate_suspected' => ['type' => 'boolean'],
                'spam_suspected' => ['type' => 'boolean'],
            ],
            'required' => ['sentiment_score','sentiment_label','public_rating','public_rating_scale','topics','reviewer_context','source_confidence','duplicate_suspected','spam_suspected'],
        ];

        $input = "Analyze the following permitted public software-review/commentary content for TechSelectAI Public Review Intelligence.\n"
            . "Extract sentiment and concise recurring topics only. Do not quote or reproduce the review body. "
            . "Use source confidence to reflect how clearly the text represents actual product-user experience. "
            . "Set duplicate_suspected or spam_suspected only when the supplied content itself gives a meaningful indication.\n\n"
            . "Source type: ".($source['source_type'] ?? 'unknown')."\n"
            . "Source name: ".($source['source_name'] ?? '')."\n\nContent:\n".$content;

        $payload = [
            'model' => $model,
            'input' => $input,
            'text' => [
                'format' => [
                    'type' => 'json_schema',
                    'name' => 'public_review_signal',
                    'strict' => true,
                    'schema' => $schema,
                ],
            ],
        ];

        $ch = curl_init('https://api.openai.com/v1/responses');
        curl_setopt_array($ch, [
            CURLOPT_POST => true,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => 60,
            CURLOPT_HTTPHEADER => [
                'Authorization: Bearer '.$apiKey,
                'Content-Type: application/json',
            ],
            CURLOPT_POSTFIELDS => json_encode($payload, JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE),
        ]);
        $raw = curl_exec($ch);
        $status = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err = curl_error($ch);
        curl_close($ch);
        if ($raw === false || $status < 200 || $status >= 300) {
            throw new RuntimeException('PRI AI analyzer request failed'.($err ? ': '.$err : ' (HTTP '.$status.')'));
        }
        $json = json_decode($raw, true);
        if (!is_array($json)) throw new RuntimeException('PRI AI analyzer returned invalid JSON.');

        $text = null;
        foreach (($json['output'] ?? []) as $item) {
            foreach (($item['content'] ?? []) as $part) {
                if (($part['type'] ?? '') === 'output_text' && isset($part['text'])) { $text = $part['text']; break 2; }
            }
        }
        if (!is_string($text) || trim($text) === '') throw new RuntimeException('PRI AI analyzer returned no structured output.');
        $result = json_decode($text, true);
        if (!is_array($result)) throw new RuntimeException('PRI AI analyzer structured output is invalid.');
        return $result;
    }
}
