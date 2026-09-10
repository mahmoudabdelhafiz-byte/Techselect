<?php
final class AiReferralAnalytics {
  private const HOSTS = [
    'chatgpt.com'=>'chatgpt',
    'chat.openai.com'=>'chatgpt',
    'claude.ai'=>'claude',
    'perplexity.ai'=>'perplexity',
    'www.perplexity.ai'=>'perplexity',
    'gemini.google.com'=>'gemini',
    'copilot.microsoft.com'=>'copilot',
  ];

  public static function classify(?string $referrer): ?array {
    $referrer=trim((string)$referrer);
    if($referrer==='') return null;
    $parts=@parse_url($referrer);
    if(!is_array($parts) || empty($parts['host'])) return null;
    $host=strtolower(rtrim((string)$parts['host'],'.'));
    $provider=self::HOSTS[$host]??null;
    if(!$provider) return null;
    $path=self::cleanPath((string)($parts['path']??'/'));
    return ['source_provider'=>$provider,'referrer_host'=>$host,'referrer_path'=>$path];
  }

  public static function isPublicKnowledgePath(string $path): bool {
    return (bool)preg_match('#^/(software/[a-z0-9-]+|categories/[a-z0-9-]+|capabilities/[a-z0-9-]+|integrations/[a-z0-9-]+|compare/[a-z0-9-]+-vs-[a-z0-9-]+)/?$#',$path);
  }

  public static function record(PDO $pdo,string $landingPath,?string $referrer): bool {
    if(($_SERVER['REQUEST_METHOD']??'GET')!=='GET') return false;
    $landingPath=self::cleanPath($landingPath);
    if(!self::isPublicKnowledgePath($landingPath)) return false;
    $source=self::classify($referrer);
    if(!$source) return false;
    try{
      $st=$pdo->prepare('INSERT INTO ai_referral_events(source_provider,referrer_host,referrer_path,landing_path) VALUES(?,?,?,?)');
      $st->execute([$source['source_provider'],$source['referrer_host'],$source['referrer_path'],$landingPath]);
      return true;
    }catch(Throwable $e){
      return false;
    }
  }

  public static function summary(PDO $pdo,int $days=30): array {
    $days=max(1,min(365,$days));
    $since=(new DateTimeImmutable('now'))->modify('-'.($days-1).' days')->format('Y-m-d 00:00:00');
    $bySource=$pdo->prepare('SELECT source_provider,COUNT(*) hits,COUNT(DISTINCT landing_path) landing_pages,MAX(occurred_at) last_seen FROM ai_referral_events WHERE occurred_at>=? GROUP BY source_provider ORDER BY hits DESC,source_provider');
    $bySource->execute([$since]);
    $byLanding=$pdo->prepare('SELECT landing_path,source_provider,COUNT(*) hits,MAX(occurred_at) last_seen FROM ai_referral_events WHERE occurred_at>=? GROUP BY landing_path,source_provider ORDER BY hits DESC,last_seen DESC LIMIT 100');
    $byLanding->execute([$since]);
    $daily=$pdo->prepare('SELECT DATE(occurred_at) day,source_provider,COUNT(*) hits FROM ai_referral_events WHERE occurred_at>=? GROUP BY DATE(occurred_at),source_provider ORDER BY day DESC,source_provider');
    $daily->execute([$since]);
    return ['days'=>$days,'by_source'=>$bySource->fetchAll(),'by_landing'=>$byLanding->fetchAll(),'daily'=>$daily->fetchAll()];
  }

  private static function cleanPath(string $path): string {
    $path=parse_url($path,PHP_URL_PATH)?:'/';
    if($path==='' || $path[0]!=='/') $path='/'.$path;
    return mb_substr($path,0,512);
  }
}
