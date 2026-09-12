<?php
final class AdvertisingSettings {
    public const PAGE_TYPES=['software','category','capability','integration','comparison'];

    public static function get(PDO $pdo): array {
        $defaults=['enabled'=>false,'adsense_client_id'=>'','auto_ads_enabled'=>true,'page_types'=>self::PAGE_TYPES,'updated_at'=>null];
        try{
            $r=$pdo->query('SELECT enabled,adsense_client_id,auto_ads_enabled,page_types_json,updated_at FROM advertising_settings WHERE id=1')->fetch(PDO::FETCH_ASSOC);
            if(!$r)return $defaults;
            $types=json_decode((string)($r['page_types_json']??'[]'),true);
            if(!is_array($types))$types=[];
            $types=array_values(array_intersect(self::PAGE_TYPES,array_map('strval',$types)));
            return [
                'enabled'=>(bool)$r['enabled'],
                'adsense_client_id'=>(string)($r['adsense_client_id']??''),
                'auto_ads_enabled'=>(bool)$r['auto_ads_enabled'],
                'page_types'=>$types,
                'updated_at'=>$r['updated_at']??null,
            ];
        }catch(Throwable $e){return $defaults;}
    }

    public static function extractClientId(string $input): string {
        $input=trim($input);
        if($input==='')return '';
        if(preg_match('/\b(ca-pub-\d{10,24})\b/i',$input,$m))return strtolower($m[1]);
        throw new InvalidArgumentException('adsense_client_id_not_found');
    }

    public static function save(PDO $pdo,array $input,int $userId): array {
        $client=self::extractClientId((string)($input['adsense_code']??$input['adsense_client_id']??''));
        $enabled=!empty($input['enabled']);
        if($enabled&&$client==='')throw new InvalidArgumentException('adsense_client_id_required');
        $auto=!empty($input['auto_ads_enabled']);
        $types=is_array($input['page_types']??null)?$input['page_types']:[];
        $types=array_values(array_intersect(self::PAGE_TYPES,array_map('strval',$types)));
        $stmt=$pdo->prepare("INSERT INTO advertising_settings(id,enabled,adsense_client_id,auto_ads_enabled,page_types_json,updated_by_user_id) VALUES(1,?,?,?,?,?) ON DUPLICATE KEY UPDATE enabled=VALUES(enabled),adsense_client_id=VALUES(adsense_client_id),auto_ads_enabled=VALUES(auto_ads_enabled),page_types_json=VALUES(page_types_json),updated_by_user_id=VALUES(updated_by_user_id),updated_at=NOW()");
        $stmt->execute([$enabled?1:0,$client!==''?$client:null,$auto?1:0,json_encode($types),$userId]);
        return self::get($pdo);
    }

    public static function headScript(PDO $pdo,string $pageType): string {
        $s=self::get($pdo);
        if(!$s['enabled']||!in_array($pageType,$s['page_types'],true))return '';
        $client=(string)$s['adsense_client_id'];
        if(!preg_match('/^ca-pub-\d{10,24}$/',$client))return '';
        $clientEsc=htmlspecialchars($client,ENT_QUOTES|ENT_SUBSTITUTE,'UTF-8');
        return '<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client='.$clientEsc.'" crossorigin="anonymous"></script>';
    }
}
