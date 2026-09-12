<?php
require_once __DIR__.'/AdminControlCenter.php';
final class AdminShell {
    public static function decorate(string $html,array $user,string $path): string {
        if(stripos($html,'<html')===false||stripos($html,'<body')===false)return $html;
        $role=(string)($user['role']??'');$nav=AdminControlCenter::navigation($role);
        $links='';
        foreach($nav as $item){$active=self::active($path,$item['key'])?' active':'';$links.='<a class="ts-admin-nav-link'.$active.'" href="'.self::h($item['href']).'">'.self::h($item['label']).'</a>';}
        $shell='<aside class="ts-admin-shell" id="tsAdminShell"><div class="ts-admin-brand"><a href="/admin"><img src="/techselectai-logo.svg" alt="TechSelectAI"><strong>Admin</strong></a><button type="button" id="tsAdminClose" aria-label="Close navigation">×</button></div><nav>'.$links.'</nav><div class="ts-admin-role">Role: '.self::h($role).'</div></aside><button class="ts-admin-menu" id="tsAdminMenu" type="button" aria-label="Open admin navigation">☰ Admin</button>';
        $css='<style id="ts-admin-shell-style">:root{--ts-admin-w:250px}.ts-admin-shell{box-sizing:border-box;position:fixed;inset:0 auto 0 0;width:var(--ts-admin-w);z-index:10000;background:#0f2740;color:#fff;padding:18px 12px;overflow:auto;box-shadow:4px 0 20px rgba(15,39,64,.12)}.ts-admin-brand a{display:flex;align-items:center;gap:9px;color:#fff;text-decoration:none}.ts-admin-brand img{width:145px;height:auto;filter:brightness(0) invert(1)}.ts-admin-brand strong{font-size:12px;opacity:.8}.ts-admin-brand button{display:none}.ts-admin-shell nav{display:flex;flex-direction:column;gap:4px;margin-top:24px}.ts-admin-nav-link{color:#d8e5ef!important;text-decoration:none!important;padding:10px 12px;border-radius:9px;font-size:14px;font-weight:650}.ts-admin-nav-link:hover,.ts-admin-nav-link.active{background:#1d496e;color:#fff!important}.ts-admin-role{margin:24px 10px 0;font-size:12px;color:#9fb8ca}.ts-admin-menu{display:none;position:fixed;top:10px;left:10px;z-index:10001;border:0;border-radius:9px;padding:9px 12px;background:#0f2740;color:#fff;font-weight:700}body.ts-admin-shell-body{box-sizing:border-box;margin-left:var(--ts-admin-w)!important;padding-left:0!important;width:calc(100% - var(--ts-admin-w))!important;max-width:none!important;overflow-x:auto}.ts-admin-shell-body>.ts-global-brand{margin-left:0!important}.ts-admin-shell-body main,.ts-admin-shell-body .wrap{max-width:min(1400px,calc(100vw - var(--ts-admin-w) - 48px))}@media(max-width:900px){body.ts-admin-shell-body{margin-left:0!important;padding-left:0!important;padding-top:52px!important;width:100%!important;max-width:none!important}.ts-admin-shell{transform:translateX(-105%);transition:transform .2s ease}.ts-admin-shell.open{transform:none}.ts-admin-menu{display:block}.ts-admin-brand button{display:block;margin-left:auto;background:transparent;border:0;color:#fff;font-size:24px}.ts-admin-brand{display:flex;align-items:center}.ts-admin-shell-body main,.ts-admin-shell-body .wrap{max-width:calc(100vw - 24px)}}</style>';
        $js='<script id="ts-admin-shell-script">document.addEventListener("DOMContentLoaded",()=>{const s=document.getElementById("tsAdminShell"),o=document.getElementById("tsAdminMenu"),c=document.getElementById("tsAdminClose");o&&o.addEventListener("click",()=>s&&s.classList.add("open"));c&&c.addEventListener("click",()=>s&&s.classList.remove("open"));});</script>';

        // Apply the layout class server-side. Admin pages run under a strict CSP, so layout must not depend on inline JS executing first.
        $html=preg_replace_callback('#<body([^>]*)>#i',static function($m) use($shell){
            $attrs=$m[1];
            if(preg_match('#\bclass=(["\'])(.*?)\1#i',$attrs,$cm)){
                $classes=trim($cm[2].' ts-admin-shell-body');
                $attrs=preg_replace('#\bclass=(["\'])(.*?)\1#i','class=$1'.$classes.'$1',$attrs,1)??$attrs;
            }else{$attrs.=' class="ts-admin-shell-body"';}
            return '<body'.$attrs.'>'.$shell;
        },$html,1)??$html;

        // Keep strict CSP while allowing only the inline scripts that belong to this server-rendered admin response.
        $nonce=rtrim(strtr(base64_encode(random_bytes(18)),'+/','-_'),'=');
        if(!headers_sent()){
            header("Content-Security-Policy: default-src 'self'; connect-src 'self'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'nonce-{$nonce}'; frame-ancestors 'none'");
        }
        $html=preg_replace_callback('#<script\b([^>]*)>#i',static function($m) use($nonce){
            if(preg_match('/\bnonce\s*=/i',$m[1]))return $m[0];
            return '<script nonce="'.htmlspecialchars($nonce,ENT_QUOTES|ENT_SUBSTITUTE,'UTF-8').'"'.$m[1].'>';
        },$html)??$html;

        $html=str_ireplace('</head>',$css.'</head>',$html);
        $html=str_ireplace('</body>',$js.'</body>',$html);
        // $js was inserted after the nonce pass, so add the same nonce to the shell controller script explicitly.
        $html=str_replace('<script id="ts-admin-shell-script">','<script nonce="'.htmlspecialchars($nonce,ENT_QUOTES|ENT_SUBSTITUTE,'UTF-8').'" id="ts-admin-shell-script">',$html);
        return $html;
    }
    private static function active(string $path,string $key): bool {
        return match($key){
            'overview'=>$path==='/admin'||$path==='/admin/'||$path==='/admin.php',
            'software'=>str_contains($path,'software-management'),
            'catalog_expansion'=>str_contains($path,'catalog-expansion'),
            'evidence'=>str_contains($path,'evidence'),
            'evaluations'=>str_contains($path,'evaluation'),
            'community'=>str_contains($path,'community')||str_contains($path,'pri-source'),
            'reviews'=>str_contains($path,'review-'),
            'taxonomy'=>str_contains($path,'taxonomy'),
            'seo'=>str_contains($path,'search-console')||str_contains($path,'indexation')||str_contains($path,'seo-quality')||str_contains($path,'long-tail'),
            'ai_visibility'=>str_contains($path,'ai-visibility')||str_contains($path,'ai-referrals'),
            'buyers'=>str_contains($path,'buyer-analytics'),
            'authority'=>str_contains($path,'authority'),
            'advertising'=>str_contains($path,'admin-advertising')||str_contains($path,'admin_advertising'),
            'users'=>str_contains($path,'admin-users'),
            'audit'=>str_contains($path,'admin-audit'),
            'health'=>str_contains($path,'health'),
            default=>false};
    }
    private static function h($v):string{return htmlspecialchars((string)$v,ENT_QUOTES|ENT_SUBSTITUTE,'UTF-8');}
}
