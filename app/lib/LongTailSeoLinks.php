<?php
final class LongTailSeoLinks {
    public static function forPath(PDO $pdo,string $path,int $limit=6): array {
        $where=[];$params=[];
        if(preg_match('#^/categories/([a-z0-9-]+)$#',$path,$m)){
            $q=$pdo->prepare('SELECT id FROM categories WHERE slug=? LIMIT 1');$q->execute([$m[1]]);$id=(int)$q->fetchColumn();if($id){$where[]='l.category_id=?';$params[]=$id;}
        }elseif(preg_match('#^/software/([a-z0-9-]+)$#',$path,$m)){
            $q=$pdo->prepare('SELECT id FROM products WHERE slug=? LIMIT 1');$q->execute([$m[1]]);$id=(int)$q->fetchColumn();if($id){$where[]='(l.primary_product_id=? OR l.secondary_product_id=? OR JSON_CONTAINS(l.product_ids_json,?))';$params[]=$id;$params[]=$id;$params[]=json_encode($id);}
        }elseif(preg_match('#^/compare/([a-z0-9-]+)-vs-([a-z0-9-]+)$#',$path,$m)){
            $q=$pdo->prepare('SELECT id FROM products WHERE slug IN(?,?)');$q->execute([$m[1],$m[2]]);$ids=array_map('intval',$q->fetchAll(PDO::FETCH_COLUMN));if(count($ids)===2){$where[]='JSON_CONTAINS(l.product_ids_json,?) AND JSON_CONTAINS(l.product_ids_json,?)';$params[]=json_encode($ids[0]);$params[]=json_encode($ids[1]);}
        }
        if(!$where)return [];
        $sql="SELECT g.title,g.canonical_path,l.context_label FROM seo_generated_pages g JOIN seo_long_tail_pages l ON l.page_id=g.id WHERE g.status='published' AND g.quality_decision='indexable' AND ".implode(' AND ',$where)." ORDER BY g.quality_score DESC,g.updated_at DESC LIMIT ".(int)$limit;
        $q=$pdo->prepare($sql);$q->execute($params);return $q->fetchAll(PDO::FETCH_ASSOC);
    }
}
