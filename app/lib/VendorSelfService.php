<?php
final class VendorSelfService {
  public const CLAIM_METHODS=['company_domain_email','official_website_evidence','manufacturer_directory','admin_documentation'];
  public const UPDATE_TYPES=['company_profile','product_url','pricing','documentation','security','integrations','territory','compliance','acquisition','feature_removal','broken_url','other_fact'];
  private const BLOCKED_FIELDS=['overall_score','community_intelligence','pros','cons','fit_score','ranking','evidence_status','recommendation'];

  public static function memberships(PDO $pdo,int $userId): array {
    $st=$pdo->prepare("SELECT vm.*,v.name vendor_name,v.slug vendor_slug,v.verification_status FROM vendor_memberships vm JOIN vendors v ON v.id=vm.vendor_id WHERE vm.user_id=? AND vm.status='active' ORDER BY v.name");
    $st->execute([$userId]);return $st->fetchAll(PDO::FETCH_ASSOC);
  }

  public static function canManageVendor(PDO $pdo,int $userId,int $vendorId): bool {
    $st=$pdo->prepare("SELECT 1 FROM vendor_memberships WHERE user_id=? AND vendor_id=? AND status='active' LIMIT 1");$st->execute([$userId,$vendorId]);return (bool)$st->fetchColumn();
  }

  public static function claim(PDO $pdo,int $userId,array $in): int {
    $vendorId=(int)($in['vendor_id']??0);$method=(string)($in['verification_method']??'');
    if(!$vendorId||!in_array($method,self::CLAIM_METHODS,true))throw new InvalidArgumentException('invalid_claim');
    $email=trim((string)($in['company_email']??''));if($email!==''&&!filter_var($email,FILTER_VALIDATE_EMAIL))throw new InvalidArgumentException('invalid_email');
    $url=trim((string)($in['evidence_url']??''));if($url!==''&&!filter_var($url,FILTER_VALIDATE_URL))throw new InvalidArgumentException('invalid_evidence_url');
    $note=trim((string)($in['evidence_note']??''));if($email===''&&$url===''&&$note==='')throw new InvalidArgumentException('verification_evidence_required');
    $st=$pdo->prepare("INSERT INTO vendor_profile_claims(vendor_id,user_id,verification_method,company_email,evidence_url,evidence_note,status) VALUES(?,?,?,?,?,?,'pending_review') ON DUPLICATE KEY UPDATE verification_method=VALUES(verification_method),company_email=VALUES(company_email),evidence_url=VALUES(evidence_url),evidence_note=VALUES(evidence_note),status='pending_review',reviewer_notes=NULL,reviewed_at=NULL,reviewed_by_user_id=NULL");
    $st->execute([$vendorId,$userId,$method,$email?:null,$url?:null,$note?:null]);
    $q=$pdo->prepare('SELECT id FROM vendor_profile_claims WHERE vendor_id=? AND user_id=?');$q->execute([$vendorId,$userId]);return (int)$q->fetchColumn();
  }

  public static function requestUpdate(PDO $pdo,int $userId,array $in): int {
    $vendorId=(int)($in['vendor_id']??0);if(!self::canManageVendor($pdo,$userId,$vendorId))throw new RuntimeException('vendor_membership_required');
    $type=(string)($in['update_type']??'');if(!in_array($type,self::UPDATE_TYPES,true))throw new InvalidArgumentException('invalid_update_type');
    $field=trim((string)($in['field_key']??''));if($field!==''&&in_array(strtolower($field),self::BLOCKED_FIELDS,true))throw new RuntimeException('editorial_field_blocked');
    $productId=!empty($in['product_id'])?(int)$in['product_id']:null;
    if($productId){$q=$pdo->prepare("SELECT 1 FROM vendor_product_relationships WHERE vendor_id=? AND product_id=? AND status='approved' AND verification_status='verified' LIMIT 1");$q->execute([$vendorId,$productId]);if(!$q->fetchColumn())throw new RuntimeException('product_not_in_verified_portfolio');}
    $proposed=trim((string)($in['proposed_value']??''));if($proposed==='')throw new InvalidArgumentException('proposed_value_required');
    $url=trim((string)($in['evidence_url']??''));if($url!==''&&!filter_var($url,FILTER_VALIDATE_URL))throw new InvalidArgumentException('invalid_evidence_url');
    $st=$pdo->prepare("INSERT INTO vendor_update_requests(vendor_id,product_id,requested_by_user_id,update_type,field_key,current_value,proposed_value,evidence_url,notes) VALUES(?,?,?,?,?,?,?,?,?)");
    $st->execute([$vendorId,$productId,$userId,$type,$field?:null,trim((string)($in['current_value']??''))?:null,$proposed,$url?:null,trim((string)($in['notes']??''))?:null]);return (int)$pdo->lastInsertId();
  }

  public static function approveClaim(PDO $pdo,array $claim,int $reviewerId): void {
    $pdo->beginTransaction();
    $pdo->prepare("UPDATE vendor_profile_claims SET status='verified',reviewed_by_user_id=?,reviewed_at=NOW() WHERE id=?")->execute([$reviewerId,$claim['id']]);
    $pdo->prepare("INSERT INTO vendor_memberships(vendor_id,user_id,status,source_claim_id,verified_at) VALUES(?,?,'active',?,NOW()) ON DUPLICATE KEY UPDATE status='active',source_claim_id=VALUES(source_claim_id),verified_at=NOW(),revoked_at=NULL")->execute([$claim['vendor_id'],$claim['user_id'],$claim['id']]);
    $pdo->prepare("UPDATE vendors SET verification_status='verified',verified_at=COALESCE(verified_at,NOW()),verified_by_user_id=COALESCE(verified_by_user_id,?) WHERE id=?")->execute([$reviewerId,$claim['vendor_id']]);
    $pdo->commit();
  }
}
