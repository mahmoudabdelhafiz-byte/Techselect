<?php
require_once __DIR__.'/app/lib/Db.php';
$config=require __DIR__.'/app/config.php';
$pdo=Db::pdo();
function x($v){return htmlspecialchars((string)$v,ENT_XML1|ENT_QUOTES,'UTF-8');}
function add_url(&$urls,$path,$freq,$priority,$lastmod=null){$urls[]=[$path,$freq,$priority,$lastmod];}

header('Content-Type: application/xml; charset=utf-8');
$urls=[];
add_url($urls,'/','weekly','1.0');
add_url($urls,'/software','daily','0.9');
add_url($urls,'/trust','monthly','0.7');
add_url($urls,'/methodology','monthly','0.6');
add_url($urls,'/about-techselectai','monthly','0.7');
add_url($urls,'/case-studies','weekly','0.8');
add_url($urls,'/guides/crm-saudi-arabia','weekly','0.8');
add_url($urls,'/guides/salesforce-vs-dynamics-enterprise','weekly','0.8');
add_url($urls,'/guides/cloud-vs-self-hosted-crm','weekly','0.8');
add_url($urls,'/guides/hrms-arabic-mena','weekly','0.8');
add_url($urls,'/guides/itsm-multi-site-enterprise','weekly','0.8');

$productSql="SELECT p.id,p.slug,p.updated_at
FROM products p
WHERE p.status='active'
AND (SELECT COUNT(*) FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.edition_id IS NULL)>=3
AND EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id)
ORDER BY p.slug";
$indexableProducts=[];
foreach($pdo->query($productSql) as $r){
  $indexableProducts[(int)$r['id']]=$r['slug'];
  add_url($urls,'/software/'.$r['slug'],'weekly','0.8',$r['updated_at']);
}

$categorySql="SELECT c.slug
FROM categories c
WHERE c.is_active=1
AND (SELECT COUNT(*) FROM products p
     WHERE p.category_id=c.id AND p.status='active'
       AND (SELECT COUNT(*) FROM product_capabilities pc WHERE pc.product_id=p.id AND pc.edition_id IS NULL)>=3
       AND EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p.id))>=2
ORDER BY c.slug";
foreach($pdo->query($categorySql) as $r)add_url($urls,'/categories/'.$r['slug'],'weekly','0.8');

$capabilitySql="SELECT c.slug,MAX(pc.last_verified_at) last_verified
FROM capabilities c
JOIN modules m ON m.id=c.module_id
JOIN categories cat ON cat.id=m.category_id
JOIN product_capabilities pc ON pc.capability_id=c.id AND pc.edition_id IS NULL
JOIN products p ON p.id=pc.product_id AND p.status='active'
WHERE c.is_active=1 AND cat.is_active=1
GROUP BY c.id,c.slug
HAVING COUNT(DISTINCT p.id)>=2
ORDER BY c.slug";
foreach($pdo->query($capabilitySql) as $r)add_url($urls,'/capabilities/'.$r['slug'],'weekly','0.7',$r['last_verified']);

$integrationSql="SELECT i.slug
FROM integrations i
JOIN product_integrations pi ON pi.integration_id=i.id
JOIN products p ON p.id=pi.product_id AND p.status='active'
GROUP BY i.id,i.slug
HAVING COUNT(DISTINCT p.id)>=2 AND MAX(pi.confidence_score)>0
ORDER BY i.slug";
foreach($pdo->query($integrationSql) as $r)add_url($urls,'/integrations/'.$r['slug'],'weekly','0.7');

if(count($indexableProducts)>=2){
  $compareSql="SELECT p1.id id1,p1.slug slug1,p2.id id2,p2.slug slug2
  FROM products p1
  JOIN products p2 ON p2.category_id=p1.category_id AND p2.id>p1.id AND p2.status='active'
  WHERE p1.status='active'
    AND (SELECT COUNT(*) FROM product_capabilities pc WHERE pc.product_id=p1.id AND pc.edition_id IS NULL)>=3
    AND (SELECT COUNT(*) FROM product_capabilities pc WHERE pc.product_id=p2.id AND pc.edition_id IS NULL)>=3
    AND EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p1.id)
    AND EXISTS(SELECT 1 FROM evidence_sources e WHERE e.product_id=p2.id)
    AND (SELECT COUNT(DISTINCT a.capability_id)
         FROM product_capabilities a
         JOIN product_capabilities b ON b.capability_id=a.capability_id AND b.product_id=p2.id AND b.edition_id IS NULL
         WHERE a.product_id=p1.id AND a.edition_id IS NULL)>=3
  ORDER BY p1.slug,p2.slug";
  foreach($pdo->query($compareSql) as $r){
    $pair=[$r['slug1'],$r['slug2']];sort($pair,SORT_STRING);
    add_url($urls,'/compare/'.implode('-vs-',$pair),'weekly','0.7');
  }
}

try{
  $caseSql="SELECT slug,updated_at FROM customer_outcomes
    WHERE verification_status='verified' AND publication_status='published'
      AND approved_by IS NOT NULL AND approved_at IS NOT NULL AND published_at IS NOT NULL
    ORDER BY slug";
  foreach($pdo->query($caseSql) as $r)add_url($urls,'/case-studies/'.$r['slug'],'monthly','0.7',$r['updated_at']);
}catch(Throwable $e){}

echo '<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">';
foreach($urls as $u){
  echo '<url><loc>'.x($config['site_url'].$u[0]).'</loc><changefreq>'.$u[1].'</changefreq><priority>'.$u[2].'</priority>';
  if(!empty($u[3]))echo '<lastmod>'.date('c',strtotime($u[3])).'</lastmod>';
  echo '</url>';
}
echo '</urlset>';
