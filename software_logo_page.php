<?php
require_once __DIR__.'/app/lib/Db.php';
$config=require __DIR__.'/app/config.php';
$pdo=Db::pdo();
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH)?:'/';

$logoMeta=null;
if(preg_match('#^/software/([a-z0-9-]+)/?$#',$path,$m)){
  $st=$pdo->prepare("SELECT name,logo_path,logo_source_url,logo_attribution,logo_last_verified_at FROM products WHERE slug=? AND status='active' LIMIT 1");
  $st->execute([$m[1]]);
  $row=$st->fetch();
  if($row && !empty($row['logo_path'])){
    $relative=ltrim((string)$row['logo_path'],'/');
    $safe=str_starts_with($relative,'media/software/') && strpos($relative,'..')===false;
    $absolute=__DIR__.'/'.$relative;
    if($safe && is_file($absolute)){
      $logoMeta=[
        'name'=>(string)$row['name'],
        'web_path'=>'/'.$relative,
        'source_url'=>(string)($row['logo_source_url']??''),
        'attribution'=>(string)($row['logo_attribution']??''),
        'verified_at'=>$row['logo_last_verified_at']??null,
      ];
    }
  }
}

ob_start();
require __DIR__.'/software_page.php';
$html=ob_get_clean();

if(!$logoMeta){echo $html;exit;}

$esc=static fn($v)=>htmlspecialchars((string)$v,ENT_QUOTES,'UTF-8');
$logo='<div class="product-mark official-logo"><img src="'.$esc($logoMeta['web_path']).'" alt="'.$esc($logoMeta['name']).' logo" width="72" height="72" loading="eager" decoding="async"></div>';
$html=preg_replace('#<div class="product-mark">.*?</div>#s',$logo,$html,1)??$html;

$css='.official-logo{background:#fff;padding:11px}.official-logo img{display:block;max-width:100%;max-height:100%;width:auto;height:auto;object-fit:contain}.logo-credit{margin:-12px 0 20px 108px;font-size:11px;color:var(--muted)}.logo-credit a{color:inherit}@media(max-width:560px){.logo-credit{margin:-10px 0 18px}}';
$html=str_replace('</style>',$css.'</style>',$html);

$credit='';
if($logoMeta['attribution']!=='' || $logoMeta['source_url']!==''){
  $credit='<div class="logo-credit">Logo: ';
  if($logoMeta['source_url']!==''){
    $credit.='<a href="'.$esc($logoMeta['source_url']).'" target="_blank" rel="nofollow noopener">'.$esc($logoMeta['attribution']!==''?$logoMeta['attribution']:'official vendor source').'</a>';
  }else{
    $credit.=$esc($logoMeta['attribution']);
  }
  $credit.=' · trademark belongs to its respective owner</div>';
}
if($credit!==''){
  $html=preg_replace('#</section>\s*<section class="summary">#','</section>'.$credit.'<section class="summary">',$html,1)??$html;
}

$og='<meta property="og:image" content="'.$esc(rtrim((string)$config['site_url'],'/').$logoMeta['web_path']).'">';
$html=str_replace('</head>',$og.'</head>',$html);

echo $html;
