<?php
require_once __DIR__.'/app/lib/Db.php';
require_once __DIR__.'/app/lib/Security.php';
require_once __DIR__.'/app/lib/AdvertisingSettings.php';
require_once __DIR__.'/app/lib/AdminShell.php';
$pdo=Db::pdo();Security::start();$user=Security::requireRole(['admin','super_admin']);$config=require __DIR__.'/app/config.php';
$message='';$error='';
if(($_SERVER['REQUEST_METHOD']??'GET')==='POST'){
    try{
        Security::sameOrigin($config);Security::requireCsrf();Security::rateLimit($pdo,'admin-advertising-save',12,300);
        $before=AdvertisingSettings::get($pdo);
        $saved=AdvertisingSettings::save($pdo,$_POST,(int)$user['id']);
        Security::audit($pdo,(int)$user['id'],'ADVERTISING_SETTINGS_UPDATE','advertising','adsense',$before,$saved);
        $message='Advertising settings saved.';
    }catch(InvalidArgumentException $e){$error=$e->getMessage()==='adsense_client_id_not_found'?'Could not find a valid AdSense publisher/client ID (ca-pub-...) in the value you pasted.':($e->getMessage()==='adsense_client_id_required'?'Add an AdSense client ID before enabling ads.':'Invalid settings.');}
    catch(Throwable $e){$error='Could not save advertising settings.';}
}
$s=AdvertisingSettings::get($pdo);$csrf=Security::csrf();
function ah($v){return htmlspecialchars((string)$v,ENT_QUOTES|ENT_SUBSTITUTE,'UTF-8');}
ob_start();
?><!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex,nofollow"><title>Advertising | TechSelectAI Admin</title><style>body{font-family:Inter,Arial,sans-serif;background:#f6f8fb;color:#14213d;margin:0}main{max-width:980px;margin:auto;padding:28px}.card{background:#fff;border:1px solid #dfe6ee;border-radius:14px;padding:20px;margin:16px 0}.muted{color:#64748b}.ok{color:#166534}.bad{color:#b91c1c}label{display:block;font-weight:700;margin:12px 0 7px}textarea{width:100%;box-sizing:border-box;padding:11px;border:1px solid #cbd5e1;border-radius:9px;min-height:125px}button{border:0;border-radius:9px;padding:11px 16px;background:#123b67;color:#fff;font-weight:700;cursor:pointer}.checks label{font-weight:500;margin:8px 0}.warning{background:#fff7ed;border-color:#fed7aa}</style></head><body><main><h1>Advertising</h1><p class="muted">Manage Google AdSense without editing PHP files. Advertising remains separate from TechSelectAI scores, fit recommendations, shortlists and Decision Packs.</p><?php if($message):?><p class="ok"><?=ah($message)?></p><?php endif;?><?php if($error):?><p class="bad"><?=ah($error)?></p><?php endif;?><form method="post"><input type="hidden" name="csrf_token" value="<?=ah($csrf)?>"><div class="card"><label><input type="checkbox" name="enabled" value="1" <?=$s['enabled']?'checked':''?>> Enable advertising</label><label>AdSense code or Publisher/Client ID</label><textarea name="adsense_code" placeholder="Paste the AdSense script from Google, or only ca-pub-xxxxxxxxxxxxxxxx"><?=ah($s['adsense_client_id'])?></textarea><p class="muted">For safety, TechSelectAI extracts and stores only the <strong>ca-pub-…</strong> client ID. Arbitrary JavaScript pasted here is never stored or executed.</p><label><input type="checkbox" name="auto_ads_enabled" value="1" <?=$s['auto_ads_enabled']?'checked':''?>> Auto Ads enabled in your AdSense account</label></div><div class="card"><h2>Where ads may load</h2><p class="muted">This controls where the AdSense loader is included. No ads are injected into AI recommendations, evaluation scoring, admin pages, logged-in decision tools or Decision Packs.</p><div class="checks"><?php foreach(AdvertisingSettings::PAGE_TYPES as $type):?><label><input type="checkbox" name="page_types[]" value="<?=ah($type)?>" <?=in_array($type,$s['page_types'],true)?'checked':''?>> <?=ah(ucwords(str_replace('_',' ',$type)))?></label><?php endforeach;?></div></div><div class="card warning"><strong>Editorial neutrality</strong><p>Advertising configuration is display-only and is not read by Product Evaluation, Fit Score, Community Intelligence, shortlist ordering or recommendation services.</p></div><button type="submit">Save advertising settings</button><?php if($s['updated_at']):?><p class="muted">Last updated: <?=ah($s['updated_at'])?></p><?php endif;?></form></main></body></html><?php
$html=ob_get_clean();
echo AdminShell::decorate($html,$user,'/admin_advertising.php');
