<?php
final class VendorRelationshipClaim {
  public const RELATIONSHIPS=['authorized_reseller','distributor','implementation_partner','referral_partner','local_agent','other_verified_partner'];
  public const EVIDENCE_TYPES=['partner_directory','authorization_letter','agreement_reference','company_domain_document','manufacturer_email','other'];
  public const TERRITORY_TYPES=['country','region','global'];

  public static function normalizeTerritories(array $rows): array {
    $out=[];
    foreach($rows as $r){
      if(!is_array($r))continue;
      $type=strtolower(trim((string)($r['type']??'')));
      $code=strtoupper(trim((string)($r['code']??'')));
      $name=trim((string)($r['name']??''));
      if(!in_array($type,self::TERRITORY_TYPES,true)||$code===''||$name==='')continue;
      $key=$type.'|'.$code;
      $out[$key]=['type'=>$type,'code'=>$code,'name'=>$name];
    }
    ksort($out);
    return array_values($out);
  }

  public static function fingerprint(array $territories): string {
    $parts=[];foreach(self::normalizeTerritories($territories) as $t)$parts[]=$t['type'].'|'.$t['code'];
    return hash('sha256',implode(';',$parts));
  }

  public static function create(PDO $pdo,array $input): array {
    $vendorId=(int)($input['vendor_id']??0);$productId=(int)($input['product_id']??0);
    $relationship=(string)($input['relationship_type']??'');
    $evidenceType=(string)($input['evidence_type']??'');
    $email=trim((string)($input['submitter_email']??''));
    $territories=self::normalizeTerritories(is_array($input['territories']??null)?$input['territories']:[]);
    if($vendorId<1||$productId<1)throw new InvalidArgumentException('vendor_and_product_required');
    if(!in_array($relationship,self::RELATIONSHIPS,true))throw new InvalidArgumentException('invalid_relationship_type');
    if(!$territories)throw new InvalidArgumentException('territory_required');
    if(!in_array($evidenceType,self::EVIDENCE_TYPES,true))throw new InvalidArgumentException('invalid_evidence_type');
    if(!filter_var($email,FILTER_VALIDATE_EMAIL))throw new InvalidArgumentException('valid_submitter_email_required');
    $url=trim((string)($input['evidence_url']??''));if($url!==''&&!filter_var($url,FILTER_VALIDATE_URL))throw new InvalidArgumentException('invalid_evidence_url');
    $fp=self::fingerprint($territories);
    $q=$pdo->prepare("SELECT id,status FROM vendor_relationship_claims WHERE vendor_id=? AND product_id=? AND relationship_type=? AND territory_fingerprint=? AND status IN ('pending','under_review','needs_information','verified') ORDER BY id DESC LIMIT 1");
    $q->execute([$vendorId,$productId,$relationship,$fp]);
    if($dup=$q->fetch(PDO::FETCH_ASSOC))return ['duplicate'=>true,'id'=>(int)$dup['id'],'status'=>$dup['status']];
    $st=$pdo->prepare("INSERT INTO vendor_relationship_claims(vendor_id,product_id,relationship_type,territories_json,territory_fingerprint,evidence_type,evidence_url,evidence_reference,evidence_note,submitter_email,valid_from,valid_until,ip_hash) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?)");
    $st->execute([$vendorId,$productId,$relationship,json_encode($territories),$fp,$evidenceType,$url?:null,trim((string)($input['evidence_reference']??''))?:null,trim((string)($input['evidence_note']??''))?:null,$email,($input['valid_from']??'')?:null,($input['valid_until']??'')?:null,hash('sha256',$_SERVER['REMOTE_ADDR']??'',true)]);
    return ['duplicate'=>false,'id'=>(int)$pdo->lastInsertId(),'status'=>'pending'];
  }

  public static function approve(PDO $pdo,array $claim,int $reviewerId,string $note=''): int {
    $territories=json_decode((string)$claim['territories_json'],true);if(!is_array($territories)||!$territories)throw new RuntimeException('claim_has_no_territories');
    $pdo->beginTransaction();
    try{
      $q=$pdo->prepare("SELECT id FROM vendor_product_relationships WHERE vendor_id=? AND product_id=? AND relationship_type=? LIMIT 1 FOR UPDATE");
      $q->execute([$claim['vendor_id'],$claim['product_id'],$claim['relationship_type']]);
      $relationshipId=(int)($q->fetchColumn()?:0);
      if($relationshipId){
        $u=$pdo->prepare("UPDATE vendor_product_relationships SET status='approved',verification_status='verified',valid_from=?,valid_until=?,evidence_source_url=?,evidence_note=?,verified_at=NOW(),verified_by_user_id=? WHERE id=?");
        $u->execute([$claim['valid_from']?:null,$claim['valid_until']?:null,$claim['evidence_url']?:null,trim($note.' '.($claim['evidence_note']??''))?:null,$reviewerId,$relationshipId]);
      }else{
        $i=$pdo->prepare("INSERT INTO vendor_product_relationships(vendor_id,product_id,relationship_type,status,verification_status,valid_from,valid_until,evidence_source_url,evidence_note,verified_at,verified_by_user_id) VALUES(?,?,?,'approved','verified',?,?,?,?,NOW(),?)");
        $i->execute([$claim['vendor_id'],$claim['product_id'],$claim['relationship_type'],$claim['valid_from']?:null,$claim['valid_until']?:null,$claim['evidence_url']?:null,trim($note.' '.($claim['evidence_note']??''))?:null,$reviewerId]);
        $relationshipId=(int)$pdo->lastInsertId();
      }
      $ti=$pdo->prepare("INSERT INTO vendor_relationship_territories(relationship_id,territory_type,territory_code,territory_name) VALUES(?,?,?,?) ON DUPLICATE KEY UPDATE territory_name=VALUES(territory_name)");
      foreach(self::normalizeTerritories($territories) as $t)$ti->execute([$relationshipId,$t['type'],$t['code'],$t['name']]);
      $pdo->prepare("UPDATE vendor_relationship_claims SET status='verified',reviewer_notes=?,reviewed_by_user_id=?,reviewed_at=NOW(),relationship_id=? WHERE id=?")->execute([$note?:null,$reviewerId,$relationshipId,$claim['id']]);
      $pdo->commit();return $relationshipId;
    }catch(Throwable $e){if($pdo->inTransaction())$pdo->rollBack();throw $e;}
  }
}
