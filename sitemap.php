<?php
require_once __DIR__.'/app/lib/Db.php';
$config=require __DIR__.'/app/config.php';
$pdo=Db::pdo();
function x($v){return htmlspecialchars((string)$v,ENT_XML1|ENT_QUOTES,'UTF-8');}
header('Content-Type: application/xml; charset=utf-8');
$urls=[['/','weekly','1.0',null],['/software','daily','0.9',null],['/methodology','monthly','0.6',null]];
foreach($pdo->query("SELECT slug,updated_at FROM products WHERE status='active'") as $r)$urls[]=['/software/'.$r['slug'],'weekly','0.8',$r['updated_at']];
foreach($pdo->query("SELECT slug FROM categories WHERE is_active=1") as $r)$urls[]=['/categories/'.$r['slug'],'weekly','0.8',null];
foreach($pdo->query("SELECT DISTINCT c.slug FROM capabilities c JOIN modules m ON m.id=c.module_id JOIN categories cat ON cat.id=m.category_id WHERE c.is_active=1 AND cat.is_active=1") as $r)$urls[]=['/capabilities/'.$r['slug'],'weekly','0.7',null];
foreach($pdo->query("SELECT i.slug FROM integrations i WHERE EXISTS(SELECT 1 FROM product_integrations pi JOIN products p ON p.id=pi.product_id WHERE pi.integration_id=i.id AND p.status='active')") as $r)$urls[]=['/integrations/'.$r['slug'],'weekly','0.7',null];
echo '<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">';
foreach($urls as $u){echo '<url><loc>'.x($config['site_url'].$u[0]).'</loc><changefreq>'.$u[1].'</changefreq><priority>'.$u[2].'</priority>';if(!empty($u[3]))echo '<lastmod>'.date('c',strtotime($u[3])).'</lastmod>';echo '</url>';}
echo '</urlset>';
