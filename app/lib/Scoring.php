<?php
final class Scoring {
  private const SUPPORT = [
    'supported'=>1.00,'enterprise_only'=>0.90,'plan_dependent'=>0.80,
    'custom_configuration'=>0.70,'partially_supported'=>0.65,'addon'=>0.60,
    'third_party_integration'=>0.55,'unknown'=>0.40,'not_yet_verified'=>0.40,
    'not_supported'=>0.00,
  ];
  private const PRIORITY = ['must_have'=>5.0,'important'=>3.0,'nice_to_have'=>1.0];
  public static function support(string $status): float { return self::SUPPORT[$status] ?? 0.40; }
  public static function priority(string $priority): float { return self::PRIORITY[$priority] ?? 1.0; }
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
    $weights=['functional'=>35,'mandatory'=>20,'integration'=>15,'deployment'=>10,'budget'=>10,'regional'=>5,'security'=>5];
    $sum=0; foreach($weights as $k=>$w)$sum+=($d[$k]??100)*$w/100;
    return round($sum,2);
  }
}
