<?php
require_once __DIR__.'/AuthoritySources.php';
final class AuthorityCampaigns {
  private const CAMPAIGN_STATUS=['draft','active','paused','completed'];
  private const TARGET_STATUS=['queued','ready','contacted','follow_up','accepted','declined','published','blocked'];
  private const EVENTS=['queued','contacted','follow_up','reply','accepted','declined','published','backlink_verified','backlink_lost','note'];
  private const CHANNELS=['email','form','linkedin','partner','vendor','customer','editorial','other'];

  public static function list(PDO $pdo):array{
    $sql="SELECT c.*,
      COUNT(t.id) targets,
      SUM(t.status IN('contacted','follow_up')) contacted,
      SUM(t.status='accepted') accepted,
      SUM(t.status='published') published,
      SUM(a.backlink_status='active') active_backlinks,
      SUM(a.backlink_status='lost') lost_backlinks
      FROM authority_campaigns c
      LEFT JOIN authority_campaign_targets t ON t.campaign_id=c.id
      LEFT JOIN authority_sources a ON a.id=t.authority_source_id
      GROUP BY c.id ORDER BY FIELD(c.status,'active','draft','paused','completed'),c.updated_at DESC";
    return $pdo->query($sql)->fetchAll();
  }

  public static function create(PDO $pdo,array $b,int $actor):array{
    $name=trim((string)($b['name']??''));$asset=self::assetPath($b['asset_path']??null);$objective=trim((string)($b['objective']??''));
    if($name===''||$asset===null||$objective==='')throw new InvalidArgumentException('name_asset_objective_required');
    $status=(string)($b['status']??'draft');if(!in_array($status,self::CAMPAIGN_STATUS,true))throw new InvalidArgumentException('invalid_campaign_status');
    $st=$pdo->prepare("INSERT INTO authority_campaigns(name,asset_path,objective,target_audience,status,starts_at,ends_at,created_by) VALUES(?,?,?,?,?,?,?,?)");
    $st->execute([$name,$asset,$objective,self::nullable($b['target_audience']??null,500),$status,self::dateOrNull($b['starts_at']??null),self::dateOrNull($b['ends_at']??null),$actor]);
    return self::get($pdo,(int)$pdo->lastInsertId());
  }

  public static function get(PDO $pdo,int $id):array{
    $st=$pdo->prepare("SELECT * FROM authority_campaigns WHERE id=?");$st->execute([$id]);$c=$st->fetch();if(!$c)throw new InvalidArgumentException('campaign_not_found');
    $q=$pdo->prepare("SELECT t.*,a.source_name,a.domain,a.source_type,a.authority_tier,a.relevance_score,a.readiness_status,a.outreach_status,a.backlink_status,a.published_url,a.submission_url
      FROM authority_campaign_targets t JOIN authority_sources a ON a.id=t.authority_source_id WHERE t.campaign_id=? ORDER BY t.priority_score DESC,a.source_name");$q->execute([$id]);$c['targets']=$q->fetchAll();
    return $c;
  }

  public static function addTarget(PDO $pdo,int $campaignId,int $sourceId,?string $angle=null,?string $nextActionAt=null):array{
    self::get($pdo,$campaignId);$source=AuthoritySources::get($pdo,$sourceId);$score=self::priority($source);
    $st=$pdo->prepare("INSERT INTO authority_campaign_targets(campaign_id,authority_source_id,priority_score,angle,status,next_action_at) VALUES(?,?,?,?,?,?)
      ON DUPLICATE KEY UPDATE priority_score=VALUES(priority_score),angle=VALUES(angle),next_action_at=VALUES(next_action_at),updated_at=CURRENT_TIMESTAMP");
    $initial=$source['readiness_status']==='ready'?'ready':'queued';$st->execute([$campaignId,$sourceId,$score,self::nullable($angle,500),$initial,self::dateOrNull($nextActionAt)]);
    return self::get($pdo,$campaignId);
  }

  public static function recordEvent(PDO $pdo,int $targetId,array $b,int $actor):array{
    $type=(string)($b['event_type']??'note');if(!in_array($type,self::EVENTS,true))throw new InvalidArgumentException('invalid_event_type');
    $channel=trim((string)($b['channel']??''));if($channel!==''&&!in_array($channel,self::CHANNELS,true))throw new InvalidArgumentException('invalid_channel');
    $external=self::urlOrNull($b['external_reference']??null);
    $st=$pdo->prepare("SELECT t.*,a.id source_id,a.source_type,a.mention_requires_approval,a.mention_approved,a.published_url FROM authority_campaign_targets t JOIN authority_sources a ON a.id=t.authority_source_id WHERE t.id=?");$st->execute([$targetId]);$t=$st->fetch();if(!$t)throw new InvalidArgumentException('campaign_target_not_found');
    if($type==='backlink_verified'){
      if($external===null&&empty($t['published_url']))throw new InvalidArgumentException('published_url_required_for_backlink_verification');
      if(!empty($t['mention_requires_approval'])&&empty($t['mention_approved']))throw new InvalidArgumentException('mention_approval_required_before_backlink_verification');
    }
    $pdo->beginTransaction();
    try{
      $ins=$pdo->prepare("INSERT INTO authority_outreach_events(campaign_target_id,event_type,channel,occurred_at,subject,notes,external_reference,actor_user_id) VALUES(?,?,?,?,?,?,?,?)");
      $ins->execute([$targetId,$type,$channel!==''?$channel:null,self::dateOrNull($b['occurred_at']??null)?:date('Y-m-d H:i:s'),self::nullable($b['subject']??null,255),self::nullable($b['notes']??null,4000),$external,$actor]);
      $status=self::statusForEvent($type);
      if($status){$pdo->prepare("UPDATE authority_campaign_targets SET status=?,next_action_at=?,updated_at=CURRENT_TIMESTAMP WHERE id=?")->execute([$status,self::dateOrNull($b['next_action_at']??null),$targetId]);}
      if(in_array($type,['contacted','follow_up','accepted','declined','published'],true))$pdo->prepare("UPDATE authority_sources SET outreach_status=?,updated_by=?,updated_at=CURRENT_TIMESTAMP WHERE id=?")->execute([$type,$actor,$t['source_id']]);
      if($type==='backlink_verified'){$published=$external?:$t['published_url'];$pdo->prepare("UPDATE authority_sources SET outreach_status='published',backlink_status='active',published_url=?,first_verified_at=COALESCE(first_verified_at,NOW()),last_checked_at=NOW(),updated_by=? WHERE id=?")->execute([$published,$actor,$t['source_id']]);}
      if($type==='backlink_lost')$pdo->prepare("UPDATE authority_sources SET backlink_status='lost',last_checked_at=NOW(),updated_by=? WHERE id=?")->execute([$actor,$t['source_id']]);
      $pdo->commit();
    }catch(Throwable $e){$pdo->rollBack();throw $e;}
    return self::targetWithEvents($pdo,$targetId);
  }

  public static function targetWithEvents(PDO $pdo,int $id):array{
    $st=$pdo->prepare("SELECT t.*,a.source_name,a.domain,a.backlink_status,a.published_url FROM authority_campaign_targets t JOIN authority_sources a ON a.id=t.authority_source_id WHERE t.id=?");$st->execute([$id]);$r=$st->fetch();if(!$r)throw new InvalidArgumentException('campaign_target_not_found');
    $q=$pdo->prepare("SELECT * FROM authority_outreach_events WHERE campaign_target_id=? ORDER BY occurred_at DESC,id DESC");$q->execute([$id]);$r['events']=$q->fetchAll();return $r;
  }

  public static function priority(array $s):float{
    $tier=['high'=>30,'medium'=>20,'low'=>10][$s['authority_tier']??'low']??10;
    $rel=max(1,min(5,(int)($s['relevance_score']??1)))*10;
    $ready=['ready'=>20,'eligibility_check'=>12,'researching'=>6,'submitted'=>5,'blocked'=>0][$s['readiness_status']??'researching']??0;
    $type=in_array(($s['source_type']??''),['industry_publication','thought_leadership','partner','customer_mention','vendor_mention'],true)?10:5;
    $penalty=($s['backlink_status']??'')==='active'?20:0;
    return max(0,min(100,$tier+$rel+$ready+$type-$penalty));
  }

  private static function statusForEvent(string $e):?string{return match($e){'queued'=>'queued','contacted'=>'contacted','follow_up'=>'follow_up','accepted'=>'accepted','declined'=>'declined','published','backlink_verified'=>'published',default=>null};}
  private static function assetPath($v):?string{$v=trim((string)$v);if($v==='')return null;if(!str_starts_with($v,'/'))throw new InvalidArgumentException('asset_path_must_be_internal');return mb_substr($v,0,512);}
  private static function nullable($v,int $max):?string{$v=trim((string)$v);return $v===''?null:mb_substr($v,0,$max);}
  private static function dateOrNull($v):?string{$v=trim((string)$v);if($v==='')return null;$t=strtotime($v);if($t===false)throw new InvalidArgumentException('invalid_date');return date('Y-m-d H:i:s',$t);}
  private static function urlOrNull($v):?string{$v=trim((string)$v);if($v==='')return null;if(!filter_var($v,FILTER_VALIDATE_URL)||!in_array(strtolower((string)parse_url($v,PHP_URL_SCHEME)),['http','https'],true))throw new InvalidArgumentException('invalid_external_reference');return $v;}
}
