<?php
require_once __DIR__.'/../app/lib/Db.php';
$pdo=Db::pdo();

echo "TechSelectAI SEO completeness audit\n";
echo str_repeat('=',34)."\n\n";

$sections=[
  'Products'=>"SELECT p.slug,
    (SELECT COUNT(*) FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.edition_id IS NULL) facts,
    (SELECT COUNT(*) FROM evidence_sources e WHERE e.product_id=p.id) evidence
    FROM products p WHERE p.status='active' ORDER BY p.slug",
  'Categories'=>"SELECT c.slug,
    (SELECT COUNT(*) FROM products p WHERE p.category_id=c.id AND p.status='active') active_products,
    (SELECT COUNT(*) FROM capabilities cp JOIN modules m ON m.id=cp.module_id WHERE m.category_id=c.id AND cp.is_active=1) capabilities
    FROM categories c WHERE c.is_active=1 ORDER BY c.slug",
  'Capabilities'=>"SELECT c.slug,COUNT(DISTINCT p.id) active_products,MAX(pc.last_verified_at) last_verified
    FROM capabilities c
    JOIN product_capabilities pc ON pc.capability_id=c.id AND pc.edition_id IS NULL
    JOIN products p ON p.id=pc.product_id AND p.status='active'
    WHERE c.is_active=1 GROUP BY c.id,c.slug ORDER BY c.slug",
  'Integrations'=>"SELECT i.slug,COUNT(DISTINCT p.id) active_products,MAX(pi.confidence_score) max_confidence
    FROM integrations i
    LEFT JOIN product_integrations pi ON pi.integration_id=i.id
    LEFT JOIN products p ON p.id=pi.product_id AND p.status='active'
    GROUP BY i.id,i.slug ORDER BY i.slug"
];

foreach($sections as $name=>$sql){
  echo "[$name]\n";
  foreach($pdo->query($sql) as $r){
    if($name==='Products')$ok=((int)$r['facts']>=3 && (int)$r['evidence']>=1);
    elseif($name==='Categories')$ok=((int)$r['active_products']>=2 && (int)$r['capabilities']>=1);
    elseif($name==='Capabilities')$ok=((int)$r['active_products']>=2);
    else $ok=((int)$r['active_products']>=2 && (float)$r['max_confidence']>0);
    $details=[];foreach($r as $k=>$v)if(!is_int($k)&&$k!=='slug')$details[]="$k=$v";
    echo ($ok?'INDEX ':'THIN  ').$r['slug'].'  '.implode('  ',$details)."\n";
  }
  echo "\n";
}

echo "INDEX = eligible for sitemap under current quality thresholds.\n";
echo "THIN  = keep public if useful, but do not intentionally promote for indexing until data improves.\n";
