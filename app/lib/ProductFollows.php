<?php

final class ProductFollows {
    public static function productBySlug(PDO $pdo, string $slug): ?array {
        $st=$pdo->prepare("SELECT p.id,p.name,p.slug,p.last_reviewed_at,p.updated_at,v.name vendor_name,c.name category_name FROM products p LEFT JOIN vendors v ON v.id=p.vendor_id LEFT JOIN categories c ON c.id=p.category_id WHERE p.slug=? AND p.status='active' LIMIT 1");
        $st->execute([$slug]);
        return $st->fetch()?:null;
    }

    private static function missingCommunityNotifications(Throwable $e): bool {
        $m=strtolower($e->getMessage());
        return strpos($m,'community_notifications')!==false
            && (strpos($m,'unknown column')!==false || strpos($m,'doesn\'t exist')!==false);
    }

    public static function listForUser(PDO $pdo,int $userId,int $limit=100):array {
        $limit=max(1,min(200,$limit));
        $base="SELECT pf.id,pf.product_id,pf.followed_at,pf.last_notified_at,%s,p.name,p.slug,p.last_reviewed_at,p.updated_at,v.name vendor_name,c.name category_name FROM product_follows pf JOIN products p ON p.id=pf.product_id LEFT JOIN vendors v ON v.id=p.vendor_id LEFT JOIN categories c ON c.id=p.category_id WHERE pf.user_id=? AND pf.status='active' AND p.status='active' ORDER BY COALESCE(pf.last_notified_at,pf.followed_at) DESC,p.name ASC LIMIT {$limit}";
        try {
            $st=$pdo->prepare(sprintf($base,'pf.community_notifications,1 AS community_notifications_available'));
            $st->execute([$userId]);
        } catch (Throwable $e) {
            if(!self::missingCommunityNotifications($e)) throw $e;
            $st=$pdo->prepare(sprintf($base,'0 AS community_notifications,0 AS community_notifications_available'));
            $st->execute([$userId]);
        }
        return $st->fetchAll()?:[];
    }

    public static function state(PDO $pdo, int $userId, int $productId): array {
        try {
            $st=$pdo->prepare("SELECT id,status,followed_at,last_notified_at,community_notifications,1 AS community_notifications_available FROM product_follows WHERE user_id=? AND product_id=? LIMIT 1");
            $st->execute([$userId,$productId]);
            $row=$st->fetch()?:null;
        } catch (Throwable $e) {
            if(!self::missingCommunityNotifications($e)) throw $e;
            $st=$pdo->prepare("SELECT id,status,followed_at,last_notified_at,0 AS community_notifications,0 AS community_notifications_available FROM product_follows WHERE user_id=? AND product_id=? LIMIT 1");
            $st->execute([$userId,$productId]);
            $row=$st->fetch()?:null;
        }
        return [
            'followed'=>$row!==null && ($row['status']??'')==='active',
            'community_notifications'=>$row!==null && (int)($row['community_notifications']??0)===1,
            'community_notifications_available'=>$row===null || (int)($row['community_notifications_available']??1)===1,
            'follow'=>$row,
        ];
    }

    public static function follow(PDO $pdo, int $userId, int $productId): array {
        $token=bin2hex(random_bytes(32));
        $pdo->prepare("INSERT INTO product_follows(user_id,product_id,status,unsubscribe_token,followed_at) VALUES(?,?,'active',?,NOW()) ON DUPLICATE KEY UPDATE status='active',unsubscribe_token=VALUES(unsubscribe_token),followed_at=NOW(),updated_at=NOW()")
            ->execute([$userId,$productId,$token]);
        return self::state($pdo,$userId,$productId);
    }

    public static function unfollow(PDO $pdo, int $userId, int $productId): array {
        try {
            $pdo->prepare("UPDATE product_follows SET status='unsubscribed',community_notifications=0,updated_at=NOW() WHERE user_id=? AND product_id=?")
                ->execute([$userId,$productId]);
        } catch (Throwable $e) {
            if(!self::missingCommunityNotifications($e)) throw $e;
            $pdo->prepare("UPDATE product_follows SET status='unsubscribed',updated_at=NOW() WHERE user_id=? AND product_id=?")
                ->execute([$userId,$productId]);
        }
        return self::state($pdo,$userId,$productId);
    }

    public static function setCommunityNotifications(PDO $pdo,int $userId,int $productId,bool $enabled):array {
        $state=self::state($pdo,$userId,$productId);
        if(!$state['followed'])throw new LogicException('follow_required');
        try {
            $pdo->prepare("UPDATE product_follows SET community_notifications=?,updated_at=NOW() WHERE user_id=? AND product_id=? AND status='active'")
                ->execute([$enabled?1:0,$userId,$productId]);
        } catch (Throwable $e) {
            if(!self::missingCommunityNotifications($e)) throw $e;
            throw new LogicException('community_notifications_unavailable');
        }
        return self::state($pdo,$userId,$productId);
    }

    public static function unsubscribeTarget(PDO $pdo, string $token): ?array {
        if(!preg_match('/^[a-f0-9]{64}$/',$token)) return null;
        $st=$pdo->prepare("SELECT pf.id,pf.product_id,pf.status,p.name product_name,p.slug product_slug FROM product_follows pf JOIN products p ON p.id=pf.product_id WHERE pf.unsubscribe_token=? LIMIT 1");
        $st->execute([$token]);
        return $st->fetch()?:null;
    }

    public static function unsubscribeByToken(PDO $pdo, string $token): ?array {
        $row=self::unsubscribeTarget($pdo,$token);
        if(!$row) return null;
        $pdo->prepare("UPDATE product_follows SET status='unsubscribed',community_notifications=0,updated_at=NOW() WHERE id=?")->execute([(int)$row['id']]);
        $row['status']='unsubscribed';
        return $row;
    }

    public static function semanticSnapshot(PDO $pdo, int $productId): array {
        $st=$pdo->prepare("SELECT p.name,p.slug,p.short_description,p.website_url,p.status,v.name vendor,c.name category FROM products p LEFT JOIN vendors v ON v.id=p.vendor_id LEFT JOIN categories c ON c.id=p.category_id WHERE p.id=? LIMIT 1");
        $st->execute([$productId]);
        $base=$st->fetch()?:[];
        $parts=['product'=>$base];

        // Use schema-tolerant row snapshots for evolving relation tables. Selecting the
        // current row shape avoids silently dropping an entire relation when a column is
        // renamed (for example scope -> scope_status) while preserving deterministic order.
        $queries=[
            'capabilities'=>"SELECT c.slug,pc.support_status,pc.implementation_type,pc.limitations,pc.confidence_score FROM product_capabilities pc JOIN capabilities c ON c.id=pc.capability_id WHERE pc.product_id=? AND pc.edition_id IS NULL ORDER BY c.slug",
            'pricing'=>"SELECT pricing_model,billing_period,currency,amount_min,amount_max,unit_label,notes,source_url,last_verified_at FROM product_pricing WHERE product_id=? ORDER BY id",
            'integrations'=>"SELECT i.slug AS integration_slug,pi.* FROM product_integrations pi JOIN integrations i ON i.id=pi.integration_id WHERE pi.product_id=? ORDER BY i.slug",
            'deployment'=>"SELECT dm.slug AS deployment_slug,pd.* FROM product_deployments pd JOIN deployment_models dm ON dm.id=pd.deployment_model_id WHERE pd.product_id=? ORDER BY dm.slug",
            'mobile'=>"SELECT * FROM product_mobile_access WHERE product_id=? ORDER BY platform",
            'editions'=>"SELECT name,slug,status,sort_order FROM product_editions WHERE product_id=? ORDER BY sort_order,slug",
        ];
        foreach($queries as $key=>$sql){
            try{$q=$pdo->prepare($sql);$q->execute([$productId]);$parts[$key]=$q->fetchAll()?:[];}catch(Throwable $e){$parts[$key]=[];}
        }
        return $parts;
    }

    public static function snapshotHash(array $snapshot): string {
        return hash('sha256',json_encode($snapshot,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE));
    }
}
