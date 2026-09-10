<?php
final class CategoryGuard {
  private const ALIASES = [
    'crm'=>['crm','customer relationship management','sales crm','crm system','crm software'],
    'hr-hcm'=>['hrms','hcm','hris','human resources management','human capital management','hr system','hr software'],
    'itsm'=>['itsm','it service management','service desk','help desk','helpdesk'],
    'erp'=>['erp','enterprise resource planning'],
    'project-management'=>['project management','project-management','work management','ppm','project software'],
    'corporate-identity-digital-business-cards'=>['digital business card','digital business cards','corporate identity','employee identity','identity verification','email signature','meeting background','business card platform'],
  ];

  public static function detectExplicit(array $context,string $message,array $allowedCategories): ?string {
    $texts=[];
    foreach($context as $row){
      if(($row['sender_type']??'')==='user' && !empty($row['message_text'])) $texts[]=(string)$row['message_text'];
    }
    $texts[]=$message;
    $allowed=array_fill_keys($allowedCategories,true);
    foreach($texts as $text){
      $normalized=self::normalize($text);
      foreach(self::ALIASES as $slug=>$aliases){
        if(!isset($allowed[$slug])) continue;
        foreach($aliases as $alias){
          if(self::containsPhrase($normalized,self::normalize($alias))) return $slug;
        }
      }
    }
    return null;
  }

  public static function capabilityCategoryMap(PDO $pdo): array {
    $rows=$pdo->query("SELECT c.slug capability_slug,cat.slug category_slug FROM capabilities c JOIN modules m ON m.id=c.module_id JOIN categories cat ON cat.id=m.category_id WHERE c.is_active=1 AND cat.is_active=1")->fetchAll();
    $map=[];foreach($rows as $r)$map[$r['capability_slug']]=$r['category_slug'];return $map;
  }

  public static function filterRequirementsToCategory(array $requirements,?string $categorySlug,array $capabilityCategoryMap): array {
    if(!$categorySlug) return $requirements;
    return array_values(array_filter($requirements,function($r)use($categorySlug,$capabilityCategoryMap){
      $slug=$r['capability_slug']??null;
      if(!$slug) return true;
      return ($capabilityCategoryMap[$slug]??null)===$categorySlug;
    }));
  }

  private static function normalize(string $text): string {
    $text=strtolower($text);
    $text=preg_replace('/[^a-z0-9]+/',' ',$text)??$text;
    return trim(preg_replace('/\s+/',' ',$text)??$text);
  }

  private static function containsPhrase(string $text,string $phrase): bool {
    return preg_match('/(?:^|\s)'.preg_quote($phrase,'/').'(?:$|\s)/',$text)===1;
  }
}
