<?php
final class VerifiedReviewRewards{
    public const TYPES=['cardiq_pro_voucher','premium_report_access'];
    public const ELIGIBILITY=['pending','eligible','ineligible','cancelled'];
    public const ISSUANCE=['not_issued','issued','redeemed','expired','cancelled'];

    public static function list(PDO $pdo,string $status=''):array{
        $sql="SELECT r.id review_id,r.product_id,p.name product,r.overall_rating,r.moderation_status,r.published_at,
                     COALESCE(MAX(CASE WHEN v.verification_status='verified' THEN 1 ELSE 0 END),0) verified,
                     rw.id reward_id,rw.reward_type,rw.eligibility_status,rw.issuance_status,rw.issued_at,rw.redeemed_at,rw.expires_at
              FROM software_reviews r
              JOIN products p ON p.id=r.product_id
              LEFT JOIN software_review_verifications v ON v.review_id=r.id
              LEFT JOIN software_review_rewards rw ON rw.review_id=r.id
              WHERE r.moderation_status='approved' AND r.published_at IS NOT NULL
              GROUP BY r.id,r.product_id,p.name,r.overall_rating,r.moderation_status,r.published_at,rw.id,rw.reward_type,rw.eligibility_status,rw.issuance_status,rw.issued_at,rw.redeemed_at,rw.expires_at
              ORDER BY r.published_at DESC,r.id DESC";
        $rows=$pdo->query($sql)->fetchAll()?:[];
        if($status!=='')$rows=array_values(array_filter($rows,static fn($x)=>(string)($x['issuance_status']??'not_issued')===$status));
        return $rows;
    }

    public static function setEligible(PDO $pdo,int $reviewId,string $rewardType):void{
        if(!in_array($rewardType,self::TYPES,true))throw new InvalidArgumentException('unsupported_reward_type');
        self::assertApprovedVerified($pdo,$reviewId);
        $st=$pdo->prepare("INSERT INTO software_review_rewards(review_id,reward_type,eligibility_status,issuance_status) VALUES(?,?,'eligible','not_issued') ON DUPLICATE KEY UPDATE reward_type=VALUES(reward_type),eligibility_status='eligible',issuance_status=IF(issuance_status='not_issued','not_issued',issuance_status)");
        $st->execute([$reviewId,$rewardType]);
    }

    public static function issue(PDO $pdo,int $reviewId,string $reference,?string $expiresAt=null):void{
        self::assertApprovedVerified($pdo,$reviewId);
        $st=$pdo->prepare("SELECT id,eligibility_status,issuance_status FROM software_review_rewards WHERE review_id=? LIMIT 1");$st->execute([$reviewId]);$rw=$st->fetch();
        if(!$rw||$rw['eligibility_status']!=='eligible')throw new RuntimeException('reward_not_eligible');
        if($rw['issuance_status']!=='not_issued')throw new RuntimeException('reward_already_issued');
        $ref=trim($reference);if($ref==='')throw new InvalidArgumentException('reward_reference_required');
        $hash=hash('sha256',$ref,true);
        $up=$pdo->prepare("UPDATE software_review_rewards SET issuance_status='issued',reward_reference_hash=?,issued_at=NOW(),expires_at=? WHERE review_id=? AND issuance_status='not_issued'");
        $up->execute([$hash,$expiresAt,$reviewId]);if($up->rowCount()!==1)throw new RuntimeException('reward_already_issued');
    }

    public static function mark(PDO $pdo,int $reviewId,string $status):void{
        if(!in_array($status,['redeemed','expired','cancelled'],true))throw new InvalidArgumentException('invalid_reward_status');
        $st=$pdo->prepare("SELECT issuance_status FROM software_review_rewards WHERE review_id=? LIMIT 1");$st->execute([$reviewId]);$rw=$st->fetch();if(!$rw)throw new RuntimeException('reward_not_found');
        if($status==='redeemed' && $rw['issuance_status']!=='issued')throw new RuntimeException('reward_not_issued');
        $sql=$status==='redeemed'?"UPDATE software_review_rewards SET issuance_status='redeemed',redeemed_at=NOW() WHERE review_id=?":"UPDATE software_review_rewards SET issuance_status=? WHERE review_id=?";
        $q=$pdo->prepare($sql);$status==='redeemed'?$q->execute([$reviewId]):$q->execute([$status,$reviewId]);
    }

    private static function assertApprovedVerified(PDO $pdo,int $reviewId):void{
        $st=$pdo->prepare("SELECT r.id,EXISTS(SELECT 1 FROM software_review_verifications v WHERE v.review_id=r.id AND v.verification_status='verified') verified FROM software_reviews r WHERE r.id=? AND r.moderation_status='approved' AND r.published_at IS NOT NULL LIMIT 1");$st->execute([$reviewId]);$r=$st->fetch();
        if(!$r)throw new RuntimeException('review_not_approved');
        if(empty($r['verified']))throw new RuntimeException('review_not_verified');
    }
}
