<?php
final class ProductMentionResolver
{
    public static function aliases(PDO $pdo,int $productId):array
    {
        $st=$pdo->prepare('SELECT name FROM products WHERE id=?');$st->execute([$productId]);$name=trim((string)$st->fetchColumn());if($name==='')return [];$values=[$name];
        try{$a=$pdo->prepare('SELECT alias_name FROM product_aliases WHERE product_id=?');$a->execute([$productId]);foreach($a->fetchAll(PDO::FETCH_COLUMN) as $v)$values[]=(string)$v;}catch(Throwable $e){}
        $out=[];foreach($values as $v){$n=self::normalize($v);if(mb_strlen($n)>=3)$out[$n]=true;}return array_keys($out);
    }

    public static function matches(PDO $pdo,int $productId,string $text):bool
    {
        $hay=' '.self::normalize($text).' ';if(trim($hay)==='')return false;
        foreach(self::aliases($pdo,$productId) as $alias){
            if(mb_strlen($alias)<4)continue;
            if(str_contains($hay,' '.$alias.' '))return true;
            if(str_contains($alias,' ')&&str_contains($hay,$alias))return true;
        }
        return false;
    }

    private static function normalize(string $v):string
    {
        $v=mb_strtolower(html_entity_decode(strip_tags($v),ENT_QUOTES|ENT_HTML5,'UTF-8'));
        $v=preg_replace('/[^\pL\pN]+/u',' ',$v)??$v;return trim(preg_replace('/\s+/u',' ',$v)??$v);
    }
}
