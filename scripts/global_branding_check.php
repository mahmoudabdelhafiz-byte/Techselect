<?php
$root=dirname(__DIR__);
$brand=file_get_contents($root.'/brand_page.php');
$ht=file_get_contents($root.'/.htaccess');
$checks=[
  'favicon injected'=>['src'=>$brand,'needle'=>'/favicon.svg'],
  'logo injected'=>['src'=>$brand,'needle'=>'/techselectai-logo.svg'],
  'logo alt text'=>['src'=>$brand,'needle'=>'alt="TechSelectAI"'],
  'software wrapped'=>['src'=>$ht,'needle'=>'RewriteRule ^software/[a-z0-9-]+/?$ brand_page.php'],
  'category wrapped'=>['src'=>$ht,'needle'=>'RewriteRule ^categories/[a-z0-9-]+/?$ brand_page.php'],
  'capability wrapped'=>['src'=>$ht,'needle'=>'RewriteRule ^capabilities/[a-z0-9-]+/?$ brand_page.php'],
  'integration wrapped'=>['src'=>$ht,'needle'=>'RewriteRule ^integrations/[a-z0-9-]+/?$ brand_page.php'],
  'comparison wrapped'=>['src'=>$ht,'needle'=>'brand_page.php [QSA,L]'],
  'account wrapped'=>['src'=>$ht,'needle'=>'RewriteRule ^(login|register|verify-email|reset-password)/?$ brand_page.php'],
  'admin wrapped'=>['src'=>$ht,'needle'=>'RewriteRule ^admin/?$ brand_page.php'],
  'favicon ico fallback'=>['src'=>$ht,'needle'=>'RewriteRule ^favicon\\.ico$ favicon.svg [L]'],
];
$failed=[];
foreach($checks as $label=>$check){if(strpos($check['src'],$check['needle'])===false)$failed[]=$label;}
if($failed){fwrite(STDERR,"Global branding check failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}
echo "Global branding check passed.\n";
