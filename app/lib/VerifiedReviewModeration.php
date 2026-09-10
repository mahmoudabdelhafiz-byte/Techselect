<?php
require_once __DIR__.'/VerifiedReviewRating.php';

final class VerifiedReviewModeration
{
    public const STATUSES=['pending','approved','rejected','needs_more_verification'];
    public const VERIFICATION_LEVELS=['email_verified','business_domain_verified','proof_of_use_verified','admin_verified'];
    public const VERIFICATION_STATUSES=['pending','verified','rejected','expired'];

    public static function list(PDO $pdo, ?string $status=null): array
    {
        $sql="SELECT r.*,p.name product,p.slug product_slug,u.full_name reviewer_name,
          (SELECT sv.verification_level FROM software_review_verifications sv WHERE sv.review_id=r.id AND sv.verification_status='verified'
           ORDER BY FIELD(sv.verification_level,'admin_verified','proof_of_use_verified','business_domain_verified','email_verified') LIMIT 1) verification_level,
          (SELECT COUNT(*) FROM software_review_risk_flags rf WHERE rf.review_id=r.id AND rf.status='open') open_risk_flags
          FROM software_reviews r JOIN products p ON p.id=r.product_id JOIN users u ON u.id=r.user_id";
        $args=[];
        if($status && in_array($status,self::STATUSES,true)){$sql.=' WHERE r.moderation_status=?';$args[]=$status;}
        $sql.=' ORDER BY CASE r.moderation_status WHEN \'pending\' THEN 0 WHEN \'needs_more_verification\' THEN 1 ELSE 2 END,r.submitted_at ASC';
        $st=$pdo->prepare($sql);$st->execute($args);return $st->fetchAll();
    }

    public static function get(PDO $pdo,int $id): array
    {
        $st=$pdo->prepare("SELECT r.*,p.name product,p.slug product_slug,u.full_name reviewer_name FROM software_reviews r JOIN products p ON p.id=r.product_id JOIN users u ON u.id=r.user_id WHERE r.id=?");$st->execute([$id]);$r=$st->fetch();if(!$r)throw new RuntimeException('review_not_found');
        $v=$pdo->prepare("SELECT id,verification_level,verification_status,verified_at,expires_at,created_at FROM software_review_verifications WHERE review_id=? ORDER BY created_at");$v->execute([$id]);$r['verifications']=$v->fetchAll();
        $f=$pdo->prepare("SELECT id,flag_type,severity,status,details_json,created_at,resolved_at FROM software_review_risk_flags WHERE review_id=? ORDER BY created_at DESC");$f->execute([$id]);$r['risk_flags']=$f->fetchAll();return $r;
    }

    public static function moderate(PDO $pdo,int $id,string $status,?string $notes): array
    {
        if(!in_array($status,self::STATUSES,true))throw new InvalidArgumentException('invalid_moderation_status');
        $old=self::get($pdo,$id);$published=$status==='approved'?'NOW()':'NULL';
        $pdo->prepare("UPDATE software_reviews SET moderation_status=?,moderation_notes=?,moderated_at=NOW(),published_at={$published} WHERE id=?")->execute([$status,$notes,$id]);
        self::recalculate($pdo,(int)$old['product_id']);return self::get($pdo,$id);
    }

    public static function setVerification(PDO $pdo,int $reviewId,string $level,string $status): array
    {
        if(!in_array($level,self::VERIFICATION_LEVELS,true))throw new InvalidArgumentException('invalid_verification_level');
        if(!in_array($status,self::VERIFICATION_STATUSES,true))throw new InvalidArgumentException('invalid_verification_status');
        self::get($pdo,$reviewId);
        $verified=$status==='verified'?'NOW()':'NULL';
        $st=$pdo->prepare("INSERT INTO software_review_verifications(review_id,verification_level,verification_status,verified_at) VALUES(?,?,?,{$verified}) ON DUPLICATE KEY UPDATE verification_status=VALUES(verification_status),verified_at={$verified}");$st->execute([$reviewId,$level,$status]);
        $r=self::get($pdo,$reviewId);self::recalculate($pdo,(int)$r['product_id']);return $r;
    }

    public static function addRiskFlag(PDO $pdo,int $reviewId,string $type,string $severity='medium',?array $details=null): array
    {
        self::get($pdo,$reviewId);if(!in_array($severity,['low','medium','high','critical'],true))throw new InvalidArgumentException('invalid_severity');
        $type=trim($type);if($type==='')throw new InvalidArgumentException('flag_type_required');
        $pdo->prepare("INSERT INTO software_review_risk_flags(review_id,flag_type,severity,details_json) VALUES(?,?,?,?)")->execute([$reviewId,substr($type,0,50),$severity,$details?json_encode($details,JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES):null]);return self::get($pdo,$reviewId);
    }

    public static function recalculate(PDO $pdo,int $productId): array
    {
        $st=$pdo->prepare("SELECT r.overall_rating,r.moderation_status,r.published_at,r.submitted_at,
          COALESCE((SELECT sv.verification_level FROM software_review_verifications sv WHERE sv.review_id=r.id AND sv.verification_status='verified' ORDER BY FIELD(sv.verification_level,'admin_verified','proof_of_use_verified','business_domain_verified','email_verified') LIMIT 1),'email_verified') verification_level
          FROM software_reviews r WHERE r.product_id=? AND r.moderation_status='approved'");$st->execute([$productId]);$score=VerifiedReviewRating::calculate($st->fetchAll());
        $up=$pdo->prepare("INSERT INTO product_verified_review_ratings(product_id,rating_5,approved_review_count,weighted_review_count,verification_confidence,methodology_version,last_calculated_at) VALUES(?,?,?,?,?,?,NOW()) ON DUPLICATE KEY UPDATE rating_5=VALUES(rating_5),approved_review_count=VALUES(approved_review_count),weighted_review_count=VALUES(weighted_review_count),verification_confidence=VALUES(verification_confidence),methodology_version=VALUES(methodology_version),last_calculated_at=NOW()");
        $up->execute([$productId,$score['rating_5'],$score['approved_review_count'],$score['weighted_review_count'],$score['verification_confidence'],$score['methodology_version']]);return $score;
    }
}
