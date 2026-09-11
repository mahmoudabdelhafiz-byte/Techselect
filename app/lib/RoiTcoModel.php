<?php
final class RoiTcoModel {
  private const COSTS=['subscription_annual','implementation_cost','migration_cost','integration_cost','training_change_cost','infrastructure_annual','support_maintenance_annual','internal_manpower_cost'];
  private const BENEFITS=['productivity_savings_annual','avoided_legacy_cost_annual','revenue_uplift_annual','risk_reduction_annual'];

  public static function sanitize(array $input):array{
    $out=[];
    $users=(int)($input['user_count']??0);$out['user_count']=$users>0?$users:null;
    foreach(array_merge(self::COSTS,self::BENEFITS) as $k){$v=$input[$k]??null;$out[$k]=($v===''||$v===null)?null:max(0,(float)$v);}
    return $out;
  }

  public static function calculate(array $raw,int $years=3,float $costFactor=1.0,float $benefitFactor=1.0):array{
    $a=self::sanitize($raw);$years=max(1,min(5,$years));
    $oneTime=['implementation_cost','migration_cost','integration_cost','training_change_cost','internal_manpower_cost'];
    $annualCosts=['subscription_annual','infrastructure_annual','support_maintenance_annual'];
    $unknown=[];foreach(array_merge(self::COSTS,self::BENEFITS) as $k)if($a[$k]===null)$unknown[]=$k;
    $sum=function(array $keys)use($a){$n=0.0;foreach($keys as $k)if($a[$k]!==null)$n+=(float)$a[$k];return $n;};
    $initial=$sum($oneTime)*$costFactor;$annualCost=$sum($annualCosts)*$costFactor;$annualBenefit=$sum(self::BENEFITS)*$benefitFactor;
    $year1=$initial+$annualCost;$tco=$initial+($annualCost*$years);$benefitTotal=$annualBenefit*$years;$net=$benefitTotal-$tco;
    $roi=$tco>0?round(($net/$tco)*100,2):null;$netAnnual=$annualBenefit-$annualCost;
    $paybackMonths=$netAnnual>0?round(($initial/($netAnnual/12)),1):null;
    $users=$a['user_count'];$cpu=($users&&$tco>0)?round($tco/($users*$years*12),2):null;
    return ['horizon_years'=>$years,'year_1_cost'=>round($year1,2),'tco'=>round($tco,2),'cost_per_user_month'=>$cpu,'annual_benefit'=>round($annualBenefit,2),'total_benefit'=>round($benefitTotal,2),'net_benefit'=>round($net,2),'roi_percent'=>$roi,'payback_months'=>$paybackMonths,'break_even_year'=>$paybackMonths!==null?round($paybackMonths/12,2):null,'unknown_inputs'=>$unknown,'input_completeness_percent'=>round(((count(self::COSTS)+count(self::BENEFITS)-count($unknown))/(count(self::COSTS)+count(self::BENEFITS)))*100,1),'disclaimer'=>'Benefits are buyer assumptions or estimates, not guaranteed outcomes. Unknown values remain unmodeled.'];
  }

  public static function scenarios(array $assumptions,int $years):array{
    return [
      'conservative'=>self::calculate($assumptions,$years,1.10,.75),
      'base'=>self::calculate($assumptions,$years,1.00,1.00),
      'optimistic'=>self::calculate($assumptions,$years,.95,1.20),
    ];
  }

  public static function verifiedPricing(PDO $pdo,int $productId):?array{
    if($productId<=0)return null;$st=$pdo->prepare("SELECT amount_min,amount_max,currency,billing_period,pricing_model,source_url,verified_at FROM product_pricing WHERE product_id=? ORDER BY COALESCE(verified_at,updated_at) DESC, id DESC LIMIT 1");$st->execute([$productId]);$r=$st->fetch();
    if(!$r)return null;return ['amount_min'=>$r['amount_min']!==null?(float)$r['amount_min']:null,'amount_max'=>$r['amount_max']!==null?(float)$r['amount_max']:null,'currency'=>$r['currency'],'billing_period'=>$r['billing_period'],'pricing_model'=>$r['pricing_model'],'source_url'=>$r['source_url'],'verified_at'=>$r['verified_at'],'usage_note'=>'Reference evidence only. It is not automatically inserted into buyer assumptions.'];
  }
}
