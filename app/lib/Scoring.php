<?php
final class Scoring {
  private const SUPPORT = [
    'supported'=>1.00,'enterprise_only'=>0.90,'plan_dependent'=>0.80,
    'custom_configuration'=>0.70,'partially_supported'=>0.65,'addon'=>0.60,
    'third_party_integration'=>0.55,'unknown'=>0.40,'not_yet_verified'=>0.40,
    'not_supported'=>0.00,
  ];
  private const REGIONAL = [
    'available'=>1.00,'limited_availability'=>0.65,
    'not_yet_verified'=>0.40,'not_available'=>0.00,
  ];
  private const PRIORITY = ['must_have'=>5.0,'important'=>3.0,'nice_to_have'=>1.0];

  // Approved TechSelectAI methodology. Fit and evidence confidence remain separate.
  // Commercial currently accepts the legacy `budget` input key for backward compatibility.
  private const WEIGHTS = [
    'functional'=>35.0,
    'mandatory'=>20.0,
    'integration'=>10.0,
    'security'=>10.0,
    'deployment'=>10.0,
    'commercial'=>7.0,
    'regional'=>5.0,
    'implementation'=>3.0,
  ];

  public static function support(string $status): float { return self::SUPPORT[$status] ?? 0.40; }
  public static function regional(string $status): float { return self::REGIONAL[$status] ?? 0.40; }
  public static function priority(string $priority): float { return self::PRIORITY[$priority] ?? 1.0; }
  public static function weights(): array { return self::WEIGHTS; }

  public static function weighted(array $requirements): float {
    $sum=0.0;$weight=0.0;
    foreach($requirements as $r){$w=self::priority($r['priority']);$sum+=self::support($r['support_status'])*$w;$weight+=$w;}
    return $weight>0?round(($sum/$weight)*100,2):100.0;
  }

  public static function mustHave(array $requirements): float {
    $vals=[]; foreach($requirements as $r){if(!empty($r['is_mandatory']))$vals[]=self::support($r['support_status']);}
    return $vals?round((array_sum($vals)/count($vals))*100,2):100.0;
  }

  public static function mandatoryGaps(array $requirements): int {
    $n=0; foreach($requirements as $r){if(!empty($r['is_mandatory']) && in_array($r['support_status'],['not_supported','unknown','not_yet_verified','partially_supported','addon','third_party_integration','custom_configuration'],true))$n++;}
    return $n;
  }

  public static function overall(array $d): float {
    // Keep old callers working while the API transitions from `budget` to `commercial`.
    if(!array_key_exists('commercial',$d) && array_key_exists('budget',$d)) $d['commercial']=$d['budget'];

    // Only score dimensions that were actually evaluated. Missing optional dimensions must
    // not silently become 100%, otherwise an omitted budget/implementation preference can
    // inflate a product's score. Available dimensions are re-normalized to 100%.
    $sum=0.0;$usedWeight=0.0;
    foreach(self::WEIGHTS as $k=>$w){
      if(!array_key_exists($k,$d) || $d[$k]===null || $d[$k]==='') continue;
      $value=max(0.0,min(100.0,(float)$d[$k]));
      $sum+=$value*$w;
      $usedWeight+=$w;
    }
    return $usedWeight>0?round($sum/$usedWeight,2):100.0;
  }
}
