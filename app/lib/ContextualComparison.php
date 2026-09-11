<?php
require_once __DIR__.'/Db.php';
require_once __DIR__.'/ProductEvaluation.php';
require_once __DIR__.'/Scoring.php';

final class ContextualComparison {
    public static function allowedContext(array $input): array {
        $size=in_array(($input['company_size']??''),['small','mid','enterprise'],true)?$input['company_size']:'mid';
        $implementation=in_array(($input['implementation_capacity']??''),['low','medium','high'],true)?$input['implementation_capacity']:'medium';
        return [
            'company_size'=>$size,
            'industry'=>mb_substr(trim((string)($input['industry']??'')),0,80),
            'geography'=>mb_substr(trim((string)($input['geography']??'')),0,80),
            'use_case'=>mb_substr(trim((string)($input['use_case']??'')),0,120),
            'security_priority'=>!empty($input['security_priority']),
            'integration_priority'=>!empty($input['integration_priority']),
            'budget_priority'=>!empty($input['budget_priority']),
            'implementation_capacity'=>$implementation,
        ];
    }

    public static function compare(PDO $pdo,array $slugs,array $context): array {
        $context=self::allowedContext($context);
        $out=[];
        foreach($slugs as $slug){
            $st=$pdo->prepare("SELECT id,name,slug,last_reviewed_at FROM products WHERE slug=? AND status='active' LIMIT 1");
            $st->execute([$slug]);$p=$st->fetch(PDO::FETCH_ASSOC);if(!$p)continue;
            $ev=ProductEvaluation::publishedForProduct($pdo,(int)$p['id']);
            $dims=$ev['dimensions']??[];
            $dimensionScores=[];$reasons=[];$tradeoffs=[];
            $put=function(string $key,?float $score,string $reason) use (&$dimensionScores,&$reasons){if($score===null)return;$dimensionScores[$key]=max(0,min(100,$score));$reasons[]=$reason;};
            $d=static fn($k)=>isset($dims[$k]['score'])&&$dims[$k]['score']!==null?(float)$dims[$k]['score']*10:null;
            $functional=[];foreach(['usability','product_maturity'] as $k){$v=$d($k);if($v!==null)$functional[]=$v;}$put('functional',$functional?array_sum($functional)/count($functional):null,'Published product evaluation is used as the baseline functional signal.');
            if($context['company_size']==='enterprise')$put('mandatory',$d('enterprise_suitability'),'Enterprise suitability is weighted for the selected company size.');
            elseif($context['company_size']==='small')$put('mandatory',$d('smb_suitability'),'SMB suitability is weighted for the selected company size.');
            else {$vals=array_filter([$d('enterprise_suitability'),$d('smb_suitability')],fn($v)=>$v!==null);$put('mandatory',$vals?array_sum($vals)/count($vals):null,'Mid-market fit uses available SMB and enterprise suitability evidence.');}
            $put('integration',$d('integration_depth'),'Integration depth reflects the published TechSelectAI product evaluation.');
            $put('security',$d('security_compliance'),'Security/compliance reflects the published TechSelectAI product evaluation.');
            $put('commercial',$d('value'),'Value is used as the current public commercial-fit proxy; buyer-specific pricing still needs confirmation.');
            $complex=$d('implementation_complexity');if($complex!==null){$implementationScore=100-$complex;if($context['implementation_capacity']==='high')$implementationScore=min(100,$implementationScore+15);elseif($context['implementation_capacity']==='low')$implementationScore=max(0,$implementationScore-15);$put('implementation',$implementationScore,'Implementation fit adjusts the published complexity signal for the buyer’s stated implementation capacity.');if($implementationScore<60)$tradeoffs[]='Implementation effort may be high for the stated internal capacity.';}
            $weights=Scoring::weights();
            if(!$context['integration_priority'])$dimensionScores['integration']=isset($dimensionScores['integration'])?$dimensionScores['integration']:null;
            if(!$context['security_priority'])$dimensionScores['security']=isset($dimensionScores['security'])?$dimensionScores['security']:null;
            if(!$context['budget_priority'])$dimensionScores['commercial']=isset($dimensionScores['commercial'])?$dimensionScores['commercial']:null;
            $score=Scoring::overall($dimensionScores);
            if($context['integration_priority'] && (($dimensionScores['integration']??100)<65))$tradeoffs[]='Integration depth is a notable trade-off for this buyer context.';
            if($context['security_priority'] && (($dimensionScores['security']??100)<65))$tradeoffs[]='Security/compliance evidence is weaker than the selected priority suggests.';
            if($context['budget_priority'] && (($dimensionScores['commercial']??100)<65))$tradeoffs[]='Value may be a concern when budget sensitivity is high.';
            $out[]=['product'=>$p,'fit_score'=>$score,'dimensions'=>$dimensionScores,'reasons'=>array_values(array_unique($reasons)),'tradeoffs'=>array_values(array_unique($tradeoffs)),'evaluation'=>$ev];
        }
        usort($out,fn($a,$b)=>$b['fit_score']<=>$a['fit_score']);
        return ['context'=>$context,'results'=>$out,'scoring_version'=>'contextual-public-v1','weights'=>$weights??Scoring::weights()];
    }
}
