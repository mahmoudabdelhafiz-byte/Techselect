<?php
final class ProductCommunity {
    private const MAX_BODY=3000;
    private const MAX_DETAILS=1000;

    public static function list(PDO $pdo,int $productId,?int $viewerId=null,string $sort='recent'):array {
        $order=$sort==='helpful'?'helpful_count DESC, p.created_at DESC':'p.created_at DESC';
        $sql="SELECT p.id,p.parent_id,p.post_type,p.body,p.created_at,p.updated_at,p.user_id,
                     (SELECT COUNT(*) FROM product_community_helpful h WHERE h.post_id=p.id) helpful_count
              FROM product_community_posts p
              WHERE p.product_id=? AND p.status='published'
              ORDER BY ".$order.", p.id DESC
              LIMIT 200";
        $st=$pdo->prepare($sql);$st->execute([$productId]);$rows=$st->fetchAll(PDO::FETCH_ASSOC);
        $helpful=[];
        if($viewerId && $rows){
            $ids=array_map(fn($r)=>(int)$r['id'],$rows);
            $ph=implode(',',array_fill(0,count($ids),'?'));
            $q=$pdo->prepare("SELECT post_id FROM product_community_helpful WHERE user_id=? AND post_id IN ($ph)");
            $q->execute(array_merge([$viewerId],$ids));
            foreach($q->fetchAll(PDO::FETCH_COLUMN) as $id)$helpful[(int)$id]=true;
        }
        $top=[];$replies=[];
        foreach($rows as $row){
            $item=[
                'id'=>(int)$row['id'],
                'parent_id'=>$row['parent_id']===null?null:(int)$row['parent_id'],
                'type'=>(string)$row['post_type'],
                'body'=>(string)$row['body'],
                'created_at'=>(string)$row['created_at'],
                'updated_at'=>(string)$row['updated_at'],
                'helpful_count'=>(int)$row['helpful_count'],
                'viewer_helpful'=>isset($helpful[(int)$row['id']]),
                'viewer_owns'=>$viewerId!==null && (int)$row['user_id']===$viewerId,
                'author_label'=>$viewerId!==null && (int)$row['user_id']===$viewerId?'You':'Community member',
                'replies'=>[],
            ];
            if($item['parent_id']===null)$top[$item['id']]=$item;else $replies[]=$item;
        }
        foreach($replies as $reply){if(isset($top[$reply['parent_id']]))$top[$reply['parent_id']]['replies'][]=$reply;}
        foreach($top as &$item)usort($item['replies'],fn($a,$b)=>strcmp($a['created_at'],$b['created_at']));unset($item);
        return array_values($top);
    }

    public static function createPost(PDO $pdo,int $productId,int $userId,string $type,string $body,?int $parentId=null):int {
        $body=trim(preg_replace('/\r\n?/',"\n",$body));
        if(mb_strlen($body)<3||mb_strlen($body)>self::MAX_BODY)throw new InvalidArgumentException('invalid_body');
        if($parentId!==null){
            $q=$pdo->prepare("SELECT id,parent_id FROM product_community_posts WHERE id=? AND product_id=? AND status='published' LIMIT 1");
            $q->execute([$parentId,$productId]);$parent=$q->fetch(PDO::FETCH_ASSOC);
            if(!$parent||$parent['parent_id']!==null)throw new InvalidArgumentException('invalid_parent');
            $type='reply';
        }elseif(!in_array($type,['question','discussion'],true))throw new InvalidArgumentException('invalid_type');
        $st=$pdo->prepare("INSERT INTO product_community_posts(product_id,user_id,parent_id,post_type,body,status) VALUES(?,?,?,?,?,'published')");
        $st->execute([$productId,$userId,$parentId,$type,$body]);
        return (int)$pdo->lastInsertId();
    }

    public static function toggleHelpful(PDO $pdo,int $productId,int $postId,int $userId):array {
        self::assertPost($pdo,$productId,$postId);
        $q=$pdo->prepare("SELECT 1 FROM product_community_helpful WHERE post_id=? AND user_id=? LIMIT 1");$q->execute([$postId,$userId]);
        if($q->fetchColumn()){$pdo->prepare("DELETE FROM product_community_helpful WHERE post_id=? AND user_id=?")->execute([$postId,$userId]);$active=false;}
        else{$pdo->prepare("INSERT INTO product_community_helpful(post_id,user_id) VALUES(?,?)")->execute([$postId,$userId]);$active=true;}
        $q=$pdo->prepare("SELECT COUNT(*) FROM product_community_helpful WHERE post_id=?");$q->execute([$postId]);
        return ['helpful'=>$active,'helpful_count'=>(int)$q->fetchColumn()];
    }

    public static function report(PDO $pdo,int $productId,int $postId,int $userId,string $reason,string $details=''):void {
        self::assertPost($pdo,$productId,$postId);
        $allowed=['spam','abuse','off_topic','misleading','other'];
        if(!in_array($reason,$allowed,true))throw new InvalidArgumentException('invalid_reason');
        $details=trim($details);if(mb_strlen($details)>self::MAX_DETAILS)$details=mb_substr($details,0,self::MAX_DETAILS);
        $st=$pdo->prepare("INSERT INTO product_community_reports(post_id,reporter_user_id,reason,details,status) VALUES(?,?,?,?,'open') ON DUPLICATE KEY UPDATE reason=VALUES(reason),details=VALUES(details),status='open',updated_at=NOW()");
        $st->execute([$postId,$userId,$reason,$details!==''?$details:null]);
    }

    private static function assertPost(PDO $pdo,int $productId,int $postId):void {
        $q=$pdo->prepare("SELECT id FROM product_community_posts WHERE id=? AND product_id=? AND status='published' LIMIT 1");$q->execute([$postId,$productId]);
        if(!$q->fetchColumn())throw new InvalidArgumentException('post_not_found');
    }
}
