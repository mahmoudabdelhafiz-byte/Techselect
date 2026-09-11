<?php
require_once __DIR__.'/VendorPortfolio.php';

final class PartnerDiscovery {
    public const SERVICE_TYPES = [
        'authorized_reseller'=>'Authorized reseller',
        'distributor'=>'Distributor',
        'implementation_partner'=>'Implementation partner',
        'local_agent'=>'Local agent',
        'referral_partner'=>'Referral partner',
        'other_verified_partner'=>'Other verified partner',
    ];

    public static function find(PDO $pdo,int $productId,string $countryCode='',array $serviceTypes=[]): array {
        $countryCode=strtoupper(trim($countryCode));
        $allowed=array_keys(self::SERVICE_TYPES);
        $serviceTypes=array_values(array_intersect($allowed,$serviceTypes));
        $rows=VendorPortfolio::partnersForProduct($pdo,$productId,null);
        $matches=[];
        foreach($rows as $row){
            if($serviceTypes && !in_array($row['relationship_type'],$serviceTypes,true))continue;
            $tier=self::matchTier($row['territories']??[],$countryCode);
            if($countryCode!=='' && $tier===null)continue;
            $row['match_tier']=$tier??'unscoped';
            $row['match_label']=self::tierLabel($row['match_tier']);
            $row['freshness']=self::freshness($row);
            $row['provider_score']=self::providerScore($row);
            $matches[]=$row;
        }
        usort($matches,static function($a,$b){
            $tier=['exact'=>0,'regional'=>1,'global'=>2,'unscoped'=>3];
            $ta=$tier[$a['match_tier']]??9;$tb=$tier[$b['match_tier']]??9;
            if($ta!==$tb)return $ta<=>$tb;
            if($a['provider_score']!==$b['provider_score'])return $b['provider_score']<=>$a['provider_score'];
            return strcasecmp((string)$a['vendor_name'],(string)$b['vendor_name']);
        });
        return $matches;
    }

    public static function matchTier(array $territories,string $countryCode): ?string {
        $countryCode=strtoupper(trim($countryCode));
        if($countryCode==='')return 'unscoped';
        $regional=[];$global=false;
        foreach($territories as $t){
            $code=strtoupper((string)($t['territory_code']??''));
            if($code===$countryCode)return 'exact';
            if($code==='GLOBAL')$global=true;
            if($code==='GCC'&&in_array($countryCode,['SA','AE','BH','KW','OM','QA'],true))$regional[]='GCC';
            if($code==='MENA'&&in_array($countryCode,['SA','AE','BH','KW','OM','QA','EG','JO','LB','MA','TN','DZ','IQ'],true))$regional[]='MENA';
        }
        if($regional)return 'regional';
        return $global?'global':null;
    }

    public static function tierLabel(string $tier): string {
        return ['exact'=>'Exact country match','regional'=>'Regional coverage','global'=>'Global / remote coverage','unscoped'=>'Verified relationship'][$tier]??'Verified relationship';
    }

    private static function providerScore(array $row): int {
        $score=0;
        if(($row['vendor_verification']??'')==='verified')$score+=20;
        if(($row['verification_status']??'')==='verified')$score+=40;
        if(!empty($row['evidence_source_url']))$score+=10;
        if(!empty($row['verified_at']))$score+=10;
        $score+=min(20,count($row['territories']??[])*5);
        return $score;
    }

    public static function freshness(array $row): array {
        if(!empty($row['valid_until'])){
            $days=(int)floor((strtotime((string)$row['valid_until'])-time())/86400);
            if($days<0)return ['status'=>'expired','label'=>'Expired'];
            if($days<=60)return ['status'=>'expiring','label'=>'Verification expires soon'];
        }
        if(!empty($row['verified_at'])){
            $age=(int)floor((time()-strtotime((string)$row['verified_at']))/86400);
            if($age>365)return ['status'=>'aging','label'=>'Verification older than 12 months'];
        }
        return ['status'=>'current','label'=>'Current verified relationship'];
    }
}
