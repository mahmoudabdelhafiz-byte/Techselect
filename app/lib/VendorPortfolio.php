<?php
final class VendorPortfolio {
    public const RELATIONSHIP_TYPES = [
        'software_owner'=>'Software owner',
        'developer'=>'Developer',
        'authorized_reseller'=>'Authorized reseller',
        'distributor'=>'Distributor',
        'implementation_partner'=>'Implementation partner',
        'referral_partner'=>'Referral partner',
        'local_agent'=>'Local agent',
        'other_verified_partner'=>'Other verified partner',
    ];

    public static function vendorProfile(PDO $pdo,string $slug): ?array {
        $st=$pdo->prepare("SELECT id,name,slug,legal_name,website_url,description,headquarters_country_code,company_type,verification_status,verified_at,status FROM vendors WHERE slug=? AND status='active' LIMIT 1");
        $st->execute([$slug]);
        $vendor=$st->fetch(PDO::FETCH_ASSOC);
        if(!$vendor)return null;
        $vendor['owned_products']=self::relationshipsForVendor($pdo,(int)$vendor['id'],['software_owner','developer']);
        $vendor['partner_products']=self::relationshipsForVendor($pdo,(int)$vendor['id'],['authorized_reseller','distributor','implementation_partner','referral_partner','local_agent','other_verified_partner']);
        return $vendor;
    }

    public static function relationshipsForVendor(PDO $pdo,int $vendorId,array $types=[]): array {
        $params=[$vendorId];
        $where="r.vendor_id=? AND r.status='approved'";
        if($types){$marks=implode(',',array_fill(0,count($types),'?'));$where.=" AND r.relationship_type IN ($marks)";$params=array_merge($params,$types);}
        $sql="SELECT r.id,r.relationship_type,r.verification_status,r.valid_from,r.valid_until,r.evidence_source_url,r.evidence_note,r.verified_at,p.id product_id,p.name product_name,p.slug product_slug,p.short_description,c.name category_name FROM vendor_product_relationships r JOIN products p ON p.id=r.product_id LEFT JOIN categories c ON c.id=p.category_id WHERE $where ORDER BY p.name,r.relationship_type";
        $st=$pdo->prepare($sql);$st->execute($params);$rows=$st->fetchAll(PDO::FETCH_ASSOC);
        foreach($rows as &$row){$row['relationship_label']=self::RELATIONSHIP_TYPES[$row['relationship_type']]??ucwords(str_replace('_',' ',$row['relationship_type']));$row['territories']=self::territories($pdo,(int)$row['id']);}unset($row);
        return $rows;
    }

    public static function partnersForProduct(PDO $pdo,int $productId,?string $territoryCode=null): array {
        $sql="SELECT r.id,r.relationship_type,r.verification_status,r.valid_from,r.valid_until,r.evidence_source_url,r.evidence_note,r.verified_at,v.id vendor_id,v.name vendor_name,v.slug vendor_slug,v.website_url,v.verification_status vendor_verification FROM vendor_product_relationships r JOIN vendors v ON v.id=r.vendor_id WHERE r.product_id=? AND r.status='approved' AND r.verification_status='verified' AND (r.valid_until IS NULL OR r.valid_until>=CURRENT_DATE) AND r.relationship_type NOT IN ('software_owner','developer') AND v.status='active'";
        $st=$pdo->prepare($sql);$st->execute([$productId]);$rows=$st->fetchAll(PDO::FETCH_ASSOC);$out=[];
        foreach($rows as $row){$row['territories']=self::territories($pdo,(int)$row['id']);if($territoryCode!==null&&!self::matchesTerritory($row['territories'],$territoryCode))continue;$row['relationship_label']=self::RELATIONSHIP_TYPES[$row['relationship_type']]??ucwords(str_replace('_',' ',$row['relationship_type']));$out[]=$row;}
        return $out;
    }

    public static function territories(PDO $pdo,int $relationshipId): array {
        $st=$pdo->prepare("SELECT territory_type,territory_code,territory_name FROM vendor_relationship_territories WHERE relationship_id=? ORDER BY territory_type,territory_name");$st->execute([$relationshipId]);return $st->fetchAll(PDO::FETCH_ASSOC);
    }

    public static function matchesTerritory(array $territories,string $code): bool {
        $code=strtoupper(trim($code));if($code==='')return true;
        foreach($territories as $t){$tc=strtoupper((string)($t['territory_code']??''));if($tc==='GLOBAL'||$tc===$code)return true;if($tc==='GCC'&&in_array($code,['SA','AE','BH','KW','OM','QA'],true))return true;if($tc==='MENA'&&in_array($code,['SA','AE','BH','KW','OM','QA','EG','JO','LB','MA','TN','DZ','IQ'],true))return true;}
        return false;
    }
}
