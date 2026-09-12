<?php
/**
 * Small mail transport wrapper for account/security email.
 *
 * Authentication itself (SPF/DKIM/DMARC signing) is performed by the hosting MTA.
 * This class keeps the visible From header and SMTP envelope sender aligned to the
 * same TechSelectAI domain so the MTA can authenticate/sign consistently.
 */
final class Mailer {
    public static function send(array $config, string $to, string $subject, string $body): bool {
        $from = strtolower(trim((string)($config['mail_from'] ?? 'no-reply@techselectai.com')));
        $returnPath = strtolower(trim((string)($config['mail_return_path'] ?? $from)));
        $senderName = trim((string)($config['mail_sender_name'] ?? 'TechSelectAI')) ?: 'TechSelectAI';

        if (!filter_var($to, FILTER_VALIDATE_EMAIL) || !filter_var($from, FILTER_VALIDATE_EMAIL)) {
            return false;
        }
        if (!filter_var($returnPath, FILTER_VALIDATE_EMAIL)) {
            $returnPath = $from;
        }

        // Prevent header injection from configuration values.
        $senderName = str_replace(["\r", "\n"], '', $senderName);
        $subject = str_replace(["\r", "\n"], ' ', $subject);

        $headers = [
            'From: '.$senderName.' <'.$from.'>',
            'Reply-To: '.$from,
            'MIME-Version: 1.0',
            'Content-Type: text/plain; charset=UTF-8',
            'Content-Transfer-Encoding: 8bit',
            'X-Mailer: TechSelectAI',
        ];

        // The -f envelope sender is important for SPF/DMARC alignment on standard
        // cPanel/Exim hosting. DKIM still needs to be enabled in Email Deliverability.
        $params = '-f'.escapeshellarg($returnPath);
        return @mail($to, $subject, $body, implode("\r\n", $headers), $params);
    }
}
