<?php
$root=dirname(__DIR__);
$checks=[
 ['db/mysql/059_advertising_settings.sql','advertising_settings'],
 ['app/lib/AdvertisingSettings.php','extractClientId'],
 ['app/lib/AdvertisingSettings.php','pagead2.googlesyndication.com'],
 ['admin_advertising.php','ADVERTISING_SETTINGS_UPDATE'],
 ['app/lib/AdminControlCenter.php',"'key'=>'advertising'"],
 ['crawlable_public_page.php','AdvertisingSettings::headScript'],
];
$failed=[];
foreach($checks as [$file,$needle]){$p=$root.'/'.$file;$txt=is_file($p)?file_get_contents($p):false;if($txt===false||strpos($txt,$needle)===false)$failed[]=$file.' :: '.$needle;}
// Advertising must remain absent from analytical/scoring modules.
foreach(['app/lib/Scoring.php','app/lib/ContextualFit.php','app/lib/ProductEvaluation.php','app/lib/DecisionPack.php'] as $file){$p=$root.'/'.$file;if(is_file($p)&&stripos((string)file_get_contents($p),'AdvertisingSettings')!==false)$failed[]='advertising coupled to analytical module: '.$file;}
// Raw pasted code must not be persisted or emitted; only a ca-pub client id may be used.
$svc=@file_get_contents($root.'/app/lib/AdvertisingSettings.php')?:'';
if(strpos($svc,"adsense_code')")===false||strpos($svc,'extractClientId')===false)$failed[]='AdSense input is not normalized to client id';
if($failed){fwrite(STDERR,"Advertising neutrality check FAILED\n - ".implode("\n - ",$failed)."\n");exit(1);}echo "Advertising neutrality check OK\n";
