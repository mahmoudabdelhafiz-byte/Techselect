<?php
final class SoftwareLogoManager {
    private const MAX_HTML_BYTES=786432;
    private const MAX_LOGO_BYTES=1572864;
    private const MAX_REDIRECTS=3;

    public static function discover(array $product): array {
        $official=(string)($product['website_url']??'');
        self::assertOfficialWebsite($official);
        $page=self::fetch($official,self::MAX_HTML_BYTES,['text/html','application/xhtml+xml']);
        $html=$page['body'];$base=$page['url'];$found=[];

        if(class_exists('DOMDocument')){
            $doc=new DOMDocument();$prev=libxml_use_internal_errors(true);$doc->loadHTML($html,LIBXML_NONET|LIBXML_NOWARNING|LIBXML_NOERROR);libxml_clear_errors();libxml_use_internal_errors($prev);
            foreach($doc->getElementsByTagName('img') as $img){
                $src=trim((string)$img->getAttribute('src'));if($src==='')continue;
                $hint=strtolower($img->getAttribute('alt').' '.$img->getAttribute('class').' '.$img->getAttribute('id'));
                $score=(str_contains($hint,'logo')||str_contains($hint,'brand'))?100:20;
                self::addCandidate($found,$official,$base,$src,'Page image',$score);
            }
            foreach($doc->getElementsByTagName('link') as $link){
                $rel=strtolower((string)$link->getAttribute('rel'));$href=trim((string)$link->getAttribute('href'));
                if($href!==''&&(str_contains($rel,'icon')||str_contains($rel,'apple-touch-icon')))self::addCandidate($found,$official,$base,$href,'Official site icon',55);
            }
            foreach($doc->getElementsByTagName('meta') as $meta){
                $key=strtolower((string)($meta->getAttribute('property')?:$meta->getAttribute('name')));$value=trim((string)$meta->getAttribute('content'));
                if($value!==''&&in_array($key,['og:image','twitter:image','twitter:image:src'],true))self::addCandidate($found,$official,$base,$value,'Official social/brand image',45);
            }
        }else{
            if(preg_match_all('#<(?:img|link)[^>]+(?:src|href)=["\']([^"\']+)["\'][^>]*>#i',$html,$m))foreach($m[1] as $u)self::addCandidate($found,$official,$base,$u,'Official site image',20);
        }

        usort($found,fn($a,$b)=>$b['score']<=>$a['score']);
        $unique=[];$seen=[];foreach($found as $c){if(isset($seen[$c['url']]))continue;$seen[$c['url']]=1;$unique[]=$c;if(count($unique)>=12)break;}
        return ['official_website'=>$official,'resolved_page'=>$base,'candidates'=>$unique];
    }

    public static function cache(array $product,string $sourceUrl): array {
        $official=(string)($product['website_url']??'');self::assertOfficialWebsite($official);
        $sourceUrl=self::absoluteUrl($official,$sourceUrl);self::assertAllowedSource($official,$sourceUrl);
        $res=self::fetch($sourceUrl,self::MAX_LOGO_BYTES,['image/png','image/jpeg','image/webp','image/svg+xml','image/x-icon','image/vnd.microsoft.icon']);
        $body=$res['body'];$mime=self::detectMime($body,(string)($res['content_type']??''));
        $ext=match($mime){'image/png'=>'png','image/jpeg'=>'jpg','image/webp'=>'webp','image/svg+xml'=>'svg','image/x-icon','image/vnd.microsoft.icon'=>'ico',default=>throw new RuntimeException('unsupported_logo_type')};
        $dimensions=null;
        if($mime==='image/svg+xml')self::validateSvg($body);else{
            $size=@getimagesizefromstring($body);if($size===false)throw new RuntimeException('invalid_image');
            $dimensions=['width'=>(int)$size[0],'height'=>(int)$size[1]];
            if($dimensions['width']<16||$dimensions['height']<16||$dimensions['width']>4096||$dimensions['height']>4096)throw new RuntimeException('invalid_logo_dimensions');
        }
        $slug=preg_replace('/[^a-z0-9-]+/','-',strtolower((string)($product['slug']??'software')));$slug=trim((string)$slug,'-')?:'software';
        $dir=dirname(__DIR__,2).'/media/software';if(!is_dir($dir)&&!mkdir($dir,0755,true)&&!is_dir($dir))throw new RuntimeException('logo_storage_unavailable');
        $name=$slug.'-'.substr(hash('sha256',$body),0,12).'.'.$ext;$path=$dir.'/'.$name;
        if(file_put_contents($path,$body,LOCK_EX)===false)throw new RuntimeException('logo_write_failed');
        @chmod($path,0644);
        return ['logo_path'=>'media/software/'.$name,'source_url'=>$res['url'],'mime'=>$mime,'bytes'=>strlen($body),'dimensions'=>$dimensions];
    }

    private static function addCandidate(array &$found,string $official,string $base,string $raw,string $label,int $score):void{
        try{$url=self::absoluteUrl($base,$raw);self::assertAllowedSource($official,$url);$found[]=['url'=>$url,'label'=>$label,'score'=>$score];}catch(Throwable $e){}
    }

    private static function assertOfficialWebsite(string $url):void{
        if(!filter_var($url,FILTER_VALIDATE_URL))throw new RuntimeException('official_website_required');$p=parse_url($url);if(!in_array(strtolower((string)($p['scheme']??'')),['https','http'],true)||empty($p['host']))throw new RuntimeException('invalid_official_website');self::assertPublicHost((string)$p['host']);
    }

    private static function assertAllowedSource(string $official,string $candidate):void{
        if(!filter_var($candidate,FILTER_VALIDATE_URL))throw new RuntimeException('invalid_logo_url');$op=parse_url($official);$cp=parse_url($candidate);$scheme=strtolower((string)($cp['scheme']??''));if(!in_array($scheme,['https','http'],true))throw new RuntimeException('unsupported_logo_scheme');
        $officialHost=self::normalizedHost((string)($op['host']??''));$candidateHost=self::normalizedHost((string)($cp['host']??''));
        $root=self::siteRoot($officialHost);if($candidateHost!==$root&&!str_ends_with($candidateHost,'.'.$root))throw new RuntimeException('logo_source_not_official_host');self::assertPublicHost($candidateHost);
    }

    private static function normalizedHost(string $host):string{$host=strtolower(rtrim($host,'.'));return str_starts_with($host,'www.')?substr($host,4):$host;}
    private static function siteRoot(string $host):string{$parts=explode('.',self::normalizedHost($host));return count($parts)>2?implode('.',array_slice($parts,-2)):implode('.',$parts);}

    private static function assertPublicHost(string $host):void{
        $host=self::normalizedHost($host);if($host===''||$host==='localhost'||str_ends_with($host,'.local'))throw new RuntimeException('private_host_rejected');
        if(filter_var($host,FILTER_VALIDATE_IP)){if(!self::isPublicIp($host))throw new RuntimeException('private_ip_rejected');return;}
        $records=@dns_get_record($host,DNS_A|DNS_AAAA)?:[];if(!$records)throw new RuntimeException('host_resolution_failed');
        foreach($records as $r){$ip=$r['ip']??$r['ipv6']??null;if($ip&&!self::isPublicIp((string)$ip))throw new RuntimeException('private_ip_rejected');}
    }
    private static function isPublicIp(string $ip):bool{return filter_var($ip,FILTER_VALIDATE_IP,FILTER_FLAG_NO_PRIV_RANGE|FILTER_FLAG_NO_RES_RANGE)!==false;}

    private static function fetch(string $url,int $maxBytes,array $allowedTypes,int $redirects=0):array{
        if($redirects>self::MAX_REDIRECTS)throw new RuntimeException('too_many_redirects');
        $p=parse_url($url);if(!$p||empty($p['host']))throw new RuntimeException('invalid_fetch_url');self::assertPublicHost((string)$p['host']);
        if(!function_exists('curl_init'))throw new RuntimeException('curl_required');
        $body='';$headers=[];$ch=curl_init($url);curl_setopt_array($ch,[CURLOPT_FOLLOWLOCATION=>false,CURLOPT_RETURNTRANSFER=>false,CURLOPT_CONNECTTIMEOUT=>5,CURLOPT_TIMEOUT=>12,CURLOPT_USERAGENT=>'TechSelectAI-LogoResearch/1.0 (+https://techselectai.com)',CURLOPT_SSL_VERIFYPEER=>true,CURLOPT_SSL_VERIFYHOST=>2,CURLOPT_HEADERFUNCTION=>function($ch,$line)use(&$headers){$len=strlen($line);$pos=strpos($line,':');if($pos!==false)$headers[strtolower(trim(substr($line,0,$pos)))]=trim(substr($line,$pos+1));return $len;},CURLOPT_WRITEFUNCTION=>function($ch,$chunk)use(&$body,$maxBytes){if(strlen($body)+strlen($chunk)>$maxBytes)return 0;$body.=$chunk;return strlen($chunk);}]);
        $ok=curl_exec($ch);$err=curl_error($ch);$status=(int)curl_getinfo($ch,CURLINFO_RESPONSE_CODE);$type=strtolower(trim(explode(';',(string)curl_getinfo($ch,CURLINFO_CONTENT_TYPE))[0]));curl_close($ch);
        if($ok===false){if(strlen($body)>=$maxBytes)throw new RuntimeException('response_too_large');throw new RuntimeException('fetch_failed'.($err?': '.$err:''));}
        if($status>=300&&$status<400&&!empty($headers['location'])){$next=self::absoluteUrl($url,$headers['location']);return self::fetch($next,$maxBytes,$allowedTypes,$redirects+1);}
        if($status<200||$status>=300)throw new RuntimeException('fetch_http_'.$status);
        if($type!==''&&!in_array($type,$allowedTypes,true))throw new RuntimeException('unexpected_content_type');
        return ['url'=>$url,'body'=>$body,'content_type'=>$type,'status'=>$status];
    }

    private static function detectMime(string $body,string $header):string{
        if(str_starts_with(ltrim($body),'<?xml')||preg_match('/^\s*<svg\b/i',$body))return 'image/svg+xml';
        $f=new finfo(FILEINFO_MIME_TYPE);$mime=(string)$f->buffer($body);if($mime==='application/octet-stream'&&$header!=='')$mime=$header;return strtolower($mime);
    }

    private static function validateSvg(string $svg):void{
        if(strlen($svg)>524288)throw new RuntimeException('svg_too_large');
        if(preg_match('/<!DOCTYPE|<!ENTITY|<script\b|<foreignObject\b|\son[a-z]+\s*=|javascript:|data:text\/html|url\s*\(/i',$svg))throw new RuntimeException('unsafe_svg');
        if(preg_match('/(?:href|xlink:href)\s*=\s*["\']\s*(?:https?:|data:|\/\/)/i',$svg))throw new RuntimeException('unsafe_svg_external_reference');
        $doc=new DOMDocument();$prev=libxml_use_internal_errors(true);$ok=$doc->loadXML($svg,LIBXML_NONET|LIBXML_NOERROR|LIBXML_NOWARNING);libxml_clear_errors();libxml_use_internal_errors($prev);if(!$ok||strtolower((string)$doc->documentElement?->localName)!=='svg')throw new RuntimeException('invalid_svg');
    }

    private static function absoluteUrl(string $base,string $raw):string{
        $raw=trim(html_entity_decode($raw,ENT_QUOTES|ENT_HTML5,'UTF-8'));if($raw==='')throw new RuntimeException('empty_url');if(str_starts_with($raw,'data:')||str_starts_with($raw,'javascript:'))throw new RuntimeException('inline_url_rejected');if(filter_var($raw,FILTER_VALIDATE_URL))return $raw;
        $b=parse_url($base);if(!$b||empty($b['scheme'])||empty($b['host']))throw new RuntimeException('invalid_base_url');if(str_starts_with($raw,'//'))return $b['scheme'].':'.$raw;
        $origin=$b['scheme'].'://'.$b['host'].(isset($b['port'])?':'.$b['port']:'');if(str_starts_with($raw,'/'))return $origin.$raw;
        $path=(string)($b['path']??'/');$dir=rtrim(str_replace('\\','/',dirname($path)),'/');$combined=$dir.'/'.$raw;$parts=[];foreach(explode('/',$combined) as $part){if($part===''||$part==='.')continue;if($part==='..'){array_pop($parts);continue;}$parts[]=$part;}return $origin.'/'.implode('/',$parts);
    }
}
