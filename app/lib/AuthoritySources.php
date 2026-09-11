<?php
final class AuthoritySources {
  private const SOURCE_TYPES=['directory','partner','industry_publication','company_profile','customer_mention','vendor_mention','thought_leadership','other'];
  private const OUTREACH=['prospect','researching','ready','contacted','follow_up','accepted','declined','published','paused'];
  private const TIERS=['high','medium','low'];
  private const LINK_TYPES=['editorial','profile','partner','customer','vendor','directory','other'];
  private const BACKLINK=['not_published','active','lost','removed'];

  public static function list(PDO $pdo):array{
    $sql="SELECT a.*,u.email owner_email FROM authority_sources a LEFT JOIN users u ON u.id=a.owner_user_id ORDER BY CASE a.backlink_status WHEN 'active' THEN 0 ELSE 1 END,a.next_action_at IS NULL,a.next_action_at,a.updated_at DESC";
    return $pdo->query($sql)->fetchAll();
  }

  public static function summary(PDO $pdo):array{
    $r=$pdo->query("SELECT COUNT(*) total,SUM(outreach_status='prospect') prospects,SUM(outreach_status IN('contacted','follow_up')) contacted,SUM(outreach_status='published') published,SUM(backlink_status='active') active_backlinks,SUM(backlink_status='lost') lost_backlinks FROM authority_sources")->fetch()?:[];
    $types=$pdo->query("SELECT source_type,COUNT(*) total,SUM(backlink_status='active') active FROM authority_sources GROUP BY source_type ORDER BY total DESC,source_type")->fetchAll();
    return ['total'=>(int)($r['total']??0),'prospects'=>(int)($r['prospects']??0),'contacted'=>(int)($r['contacted']??0),'published'=>(int)($r['published']??0),'active_backlinks'=>(int)($r['active_backlinks']??0),'lost_backlinks'=>(int)($r['lost_backlinks']??0),'by_type'=>$types];
  }

  public static function get(PDO $pdo,int $id):array{
    $st=$pdo->prepare("SELECT * FROM authority_sources WHERE id=?");$st->execute([$id]);$r=$st->fetch();if(!$r)throw new InvalidArgumentException('authority_source_not_found');return $r;
  }

  public static function save(PDO $pdo,array $b,int $actor,?int $id=null):array{
    $sourceName=trim((string)($b['source_name']??''));if($sourceName==='')throw new InvalidArgumentException('source_name_required');
    $domain=self::domain((string)($b['domain']??$b['source_url']??''));if($domain==='')throw new InvalidArgumentException('valid_domain_required');
    $sourceType=(string)($b['source_type']??'');if(!in_array($sourceType,self::SOURCE_TYPES,true))throw new InvalidArgumentException('invalid_source_type');
    $outreach=(string)($b['outreach_status']??'prospect');if(!in_array($outreach,self::OUTREACH,true))throw new InvalidArgumentException('invalid_outreach_status');
    $tier=(string)($b['authority_tier']??'medium');if(!in_array($tier,self::TIERS,true))throw new InvalidArgumentException('invalid_authority_tier');
    $backlink=(string)($b['backlink_status']??'not_published');if(!in_array($backlink,self::BACKLINK,true))throw new InvalidArgumentException('invalid_backlink_status');
    $linkType=trim((string)($b['link_type']??''));if($linkType!==''&&!in_array($linkType,self::LINK_TYPES,true))throw new InvalidArgumentException('invalid_link_type');
    $relevance=max(1,min(5,(int)($b['relevance_score']??3)));
    $sourceUrl=self::urlOrNull($b['source_url']??null);$publishedUrl=self::urlOrNull($b['published_url']??null);
    $requires=!empty($b['mention_requires_approval'])?1:0;$approved=!empty($b['mention_approved'])?1:0;
    if(in_array($sourceType,['customer_mention','vendor_mention','partner'],true))$requires=1;
    if($requires&&!$approved&&($backlink==='active'||$outreach==='published'))throw new InvalidArgumentException('mention_approval_required_before_publish');
    if($backlink==='active'&&$publishedUrl===null)throw new InvalidArgumentException('published_url_required_for_active_backlink');
    $fields=['source_name'=>$sourceName,'domain'=>$domain,'source_url'=>$sourceUrl,'source_type'=>$sourceType,'geography_code'=>self::nullable($b['geography_code']??null,10),'relevance_score'=>$relevance,'authority_tier'=>$tier,'owner_user_id'=>self::nullableInt($b['owner_user_id']??null),'outreach_status'=>$outreach,'next_action'=>self::nullable($b['next_action']??null,255),'next_action_at'=>self::nullableDate($b['next_action_at']??null),'techselect_asset_path'=>self::assetPath($b['techselect_asset_path']??null),'intended_context'=>self::nullable($b['intended_context']??null,500),'mention_requires_approval'=>$requires,'mention_approved'=>$approved,'approval_notes'=>self::nullable($b['approval_notes']??null,500),'published_url'=>$publishedUrl,'link_type'=>$linkType!==''?$linkType:null,'rel_attribute'=>self::nullable($b['rel_attribute']??null,80),'backlink_status'=>$backlink,'first_verified_at'=>self::nullableDate($b['first_verified_at']??null),'last_checked_at'=>self::nullableDate($b['last_checked_at']??null),'notes'=>self::nullable($b['notes']??null,4000)];
    if($id===null){$cols=array_keys($fields);$sql="INSERT INTO authority_sources(".implode(',',$cols).",created_by,updated_by) VALUES(".implode(',',array_fill(0,count($cols)+2,'?')).")";$pdo->prepare($sql)->execute([...array_values($fields),$actor,$actor]);$id=(int)$pdo->lastInsertId();}
    else{self::get($pdo,$id);$sets=[];foreach(array_keys($fields) as $k)$sets[]="$k=?";$sql="UPDATE authority_sources SET ".implode(',',$sets).",updated_by=? WHERE id=?";$pdo->prepare($sql)->execute([...array_values($fields),$actor,$id]);}
    return self::get($pdo,$id);
  }

  private static function domain(string $v):string{$v=trim(strtolower($v));if($v==='')return '';$candidate=str_contains($v,'://')?$v:'https://'.$v;$host=parse_url($candidate,PHP_URL_HOST);if(!$host)return '';$host=preg_replace('/^www\./','',$host);return filter_var($host,FILTER_VALIDATE_DOMAIN,FILTER_FLAG_HOSTNAME)?$host:'';}
  private static function urlOrNull($v):?string{$v=trim((string)$v);if($v==='')return null;if(!filter_var($v,FILTER_VALIDATE_URL)||!in_array(strtolower((string)parse_url($v,PHP_URL_SCHEME)),['http','https'],true))throw new InvalidArgumentException('invalid_url');return $v;}
  private static function nullable($v,int $max):?string{$v=trim((string)$v);if($v==='')return null;return mb_substr($v,0,$max);}
  private static function nullableInt($v):?int{$n=(int)$v;return $n>0?$n:null;}
  private static function nullableDate($v):?string{$v=trim((string)$v);if($v==='')return null;$t=strtotime($v);if($t===false)throw new InvalidArgumentException('invalid_date');return date('Y-m-d H:i:s',$t);}
  private static function assetPath($v):?string{$v=trim((string)$v);if($v==='')return null;if(!str_starts_with($v,'/'))throw new InvalidArgumentException('asset_path_must_be_internal');return mb_substr($v,0,512);}
}
