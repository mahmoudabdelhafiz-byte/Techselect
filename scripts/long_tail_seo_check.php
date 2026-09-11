<?php
$root=dirname(__DIR__);
$checks=[
  'migration'=>file_exists($root.'/db/mysql/051_long_tail_seo_pages.sql'),
  'generator'=>file_exists($root.'/app/lib/LongTailSeoGenerator.php'),
  'links'=>file_exists($root.'/app/lib/LongTailSeoLinks.php'),
  'public_renderer'=>file_exists($root.'/long_tail_seo_page.php'),
  'admin'=>file_exists($root.'/long_tail_seo_admin.php'),
  'api'=>file_exists($root.'/api/long_tail_seo.php'),
];
$gen=file_get_contents($root.'/app/lib/LongTailSeoGenerator.php');
$ht=file_get_contents($root.'/.htaccess');
$sitemap=file_get_contents($root.'/sitemap.php');
$checks['templates']=str_contains($gen,'category_for_industry')&&str_contains($gen,'category_for_company_size')&&str_contains($gen,'comparison_for_context')&&str_contains($gen,'alternatives_for_context');
$checks['quality_gate']=str_contains($gen,'ProgrammaticSeoQualityGate::run');
$checks['published_eval_only']=str_contains($gen,"pe.status='published'")&&str_contains($gen,"em.status='published'");
$checks['fit_boundary']=str_contains($gen,'buyer-specific Fit Score');
$checks['routes']=str_contains($ht,'software-selection/[a-z0-9-]+')&&str_contains($ht,'api/long-tail-seo')&&str_contains($ht,'long-tail-seo');
$checks['sitemap_gate']=str_contains($sitemap,"quality_decision='indexable'")&&str_contains($sitemap,"status='published'");
$failed=array_keys(array_filter($checks,fn($v)=>!$v));
echo json_encode(['checks'=>$checks,'failed'=>$failed],JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES).PHP_EOL;
exit($failed?1:0);
