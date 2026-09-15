<?php

final class PublicSeoMetadata {
    public static function forPath(PDO $pdo,string $canonicalPath): array {
        $title='TechSelectAI';
        $description='Evidence-backed software research and comparison for business technology decisions.';

        if(preg_match('#^/software/([a-z0-9-]+)$#',$canonicalPath,$m)){
            $st=$pdo->prepare("SELECT p.name,p.short_description,c.name category,v.name vendor FROM products p LEFT JOIN categories c ON c.id=p.category_id LEFT JOIN vendors v ON v.id=p.vendor_id WHERE p.slug=? AND p.status='active' LIMIT 1");
            $st->execute([$m[1]]);$r=$st->fetch();
            if($r){
                $title=$r['name'].' Review: Features, Pricing & Alternatives | TechSelectAI';
                $description=self::limit(($r['short_description']?:('Compare verified '.$r['name'].' capabilities, pricing, deployment, integrations and alternatives.')).' Evidence-backed profile with source transparency and last-reviewed product data.');
            }
        }elseif(preg_match('#^/alternatives/([a-z0-9-]+)$#',$canonicalPath,$m)){
            $st=$pdo->prepare("SELECT p.name,c.name category FROM products p LEFT JOIN categories c ON c.id=p.category_id WHERE p.slug=? AND p.status='active' LIMIT 1");
            $st->execute([$m[1]]);$r=$st->fetch();
            if($r){
                $title=$r['name'].' Alternatives: Compare Evidence-Backed Options | TechSelectAI';
                $description=self::limit('Compare evidence-qualified alternatives to '.$r['name'].' in '.$r['category'].'. TechSelectAI only includes same-category options with fresh verified evidence and meaningful capability overlap.');
            }
        }elseif(preg_match('#^/categories/([a-z0-9-]+)$#',$canonicalPath,$m)){
            $st=$pdo->prepare("SELECT name,description FROM categories WHERE slug=? AND is_active=1 LIMIT 1");$st->execute([$m[1]]);$r=$st->fetch();
            if($r){
                $title='Compare '.$r['name'].' Software: Features, Vendors & Evidence | TechSelectAI';
                $description=self::limit(($r['description']?:('Compare '.$r['name'].' software using verified capabilities, integrations, deployment and product evidence.')).' Review products side by side before building your shortlist.');
            }
        }elseif(preg_match('#^/capabilities/([a-z0-9-]+)$#',$canonicalPath,$m)){
            $st=$pdo->prepare("SELECT c.name,c.description,cat.name category FROM capabilities c JOIN modules mo ON mo.id=c.module_id JOIN categories cat ON cat.id=mo.category_id WHERE c.slug=? AND c.is_active=1 AND cat.is_active=1 LIMIT 1");$st->execute([$m[1]]);$r=$st->fetch();
            if($r){
                $title=$r['name'].' Software: Compare Product Support | TechSelectAI';
                $description=self::limit(($r['description']?:('Compare '.$r['category'].' products for '.$r['name'].'.')).' See supported, conditional and not-yet-verified states with evidence confidence and source-backed product facts.');
            }
        }elseif(preg_match('#^/integrations/([a-z0-9-]+)$#',$canonicalPath,$m)){
            $st=$pdo->prepare("SELECT name,description FROM integrations WHERE slug=? LIMIT 1");$st->execute([$m[1]]);$r=$st->fetch();
            if($r){
                $title=$r['name'].' Integration Software: Compare Compatible Products | TechSelectAI';
                $description=self::limit(($r['description']?:('Compare software products with recorded '.$r['name'].' integration support.')).' TechSelectAI keeps verified support separate from unknown or not-yet-verified integration claims.');
            }
        }elseif(preg_match('#^/compare/([a-z0-9-]+)-vs-([a-z0-9-]+)$#',$canonicalPath,$m)){
            $st=$pdo->prepare("SELECT name FROM products WHERE slug=? AND status='active' LIMIT 1");$st->execute([$m[1]]);$a=$st->fetchColumn();$st->execute([$m[2]]);$b=$st->fetchColumn();
            if($a&&$b){
                $title=$a.' vs '.$b.': Features, Evidence & Differences | TechSelectAI';
                $description=self::limit('Compare '.$a.' vs '.$b.' using evidence-backed capabilities, integrations, deployment and verified product facts. Unknown information remains not yet verified rather than unsupported.');
            }
        }
        return ['title'=>$title,'description'=>$description];
    }

    private static function limit(string $text,int $max=158): string {
        $text=trim(preg_replace('/\s+/u',' ',$text)??$text);
        if(mb_strlen($text)<=$max)return $text;
        $cut=mb_substr($text,0,$max-1);
        $pos=mb_strrpos($cut,' ');
        if($pos!==false&&$pos>90)$cut=mb_substr($cut,0,$pos);
        return rtrim($cut," ,.;:-").'…';
    }
}
