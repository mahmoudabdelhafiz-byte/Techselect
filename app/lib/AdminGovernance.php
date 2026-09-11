<?php
final class AdminGovernance {
    public const ADMIN_ROLES=['reviewer','data_editor','admin','super_admin'];
    public const ASSIGNABLE_BY_ADMIN=['user','reviewer','data_editor'];
    public const ASSIGNABLE_BY_SUPER=['user','reviewer','data_editor','admin','super_admin'];
    public const USER_STATUSES=['pending','active','suspended','disabled'];
    public const PERMISSIONS=[
        'edit_product_data'=>['reviewer'=>true,'data_editor'=>true,'admin'=>true,'super_admin'=>true],
        'verify_evidence'=>['reviewer'=>true,'data_editor'=>false,'admin'=>true,'super_admin'=>true],
        'publish_activate_product'=>['reviewer'=>true,'data_editor'=>false,'admin'=>true,'super_admin'=>true],
        'moderate_user_reviews'=>['reviewer'=>true,'data_editor'=>false,'admin'=>true,'super_admin'=>true],
        'approve_community_intelligence'=>['reviewer'=>true,'data_editor'=>false,'admin'=>true,'super_admin'=>true],
        'approve_ai_evaluation_changes'=>['reviewer'=>true,'data_editor'=>false,'admin'=>true,'super_admin'=>true],
        'manage_users_roles'=>['reviewer'=>false,'data_editor'=>false,'admin'=>true,'super_admin'=>true],
        'change_methodology_system_settings'=>['reviewer'=>false,'data_editor'=>false,'admin'=>false,'super_admin'=>true],
    ];

    public static function users(PDO $pdo,array $filters=[]): array {
        $where=['1=1'];$args=[];
        if(($q=trim((string)($filters['q']??'')))!==''){$where[]='(email LIKE ? OR full_name LIKE ?)';$like='%'.$q.'%';$args[]=$like;$args[]=$like;}
        if(!empty($filters['role'])){$where[]='role=?';$args[]=$filters['role'];}
        if(!empty($filters['status'])){$where[]='status=?';$args[]=$filters['status'];}
        $sql="SELECT id,email,full_name,role,status,email_verified_at,last_login_at,created_at,updated_at FROM users WHERE ".implode(' AND ',$where)." ORDER BY created_at DESC LIMIT 500";
        $st=$pdo->prepare($sql);$st->execute($args);return $st->fetchAll(PDO::FETCH_ASSOC);
    }

    public static function canChangeUser(PDO $pdo,array $actor,array $target,string $newRole,string $newStatus): array {
        $actorRole=(string)($actor['role']??'');$targetRole=(string)($target['role']??'');$actorId=(int)($actor['id']??0);$targetId=(int)$target['id'];
        if(!in_array($newStatus,self::USER_STATUSES,true))return [false,'invalid_status'];
        if($actorRole==='super_admin'){
            if(!in_array($newRole,self::ASSIGNABLE_BY_SUPER,true))return [false,'invalid_role'];
            if($actorId===$targetId && ($newRole!=='super_admin'||$newStatus!=='active'))return [false,'cannot_remove_own_super_admin_access'];
            if($targetRole==='super_admin' && ($newRole!=='super_admin'||$newStatus!=='active')){
                $count=(int)$pdo->query("SELECT COUNT(*) FROM users WHERE role='super_admin' AND status='active'")->fetchColumn();
                if($count<=1)return [false,'last_active_super_admin_required'];
            }
            return [true,null];
        }
        if($actorRole==='admin'){
            if(in_array($targetRole,['admin','super_admin'],true))return [false,'cannot_manage_equal_or_higher_role'];
            if(!in_array($newRole,self::ASSIGNABLE_BY_ADMIN,true))return [false,'role_requires_super_admin'];
            return [true,null];
        }
        return [false,'forbidden'];
    }

    public static function audit(PDO $pdo,array $filters=[]): array {
        $page=max(1,(int)($filters['page']??1));$per=min(100,max(10,(int)($filters['per_page']??50)));$offset=($page-1)*$per;
        $where=['1=1'];$args=[];
        if(!empty($filters['actor_user_id'])){$where[]='a.actor_user_id=?';$args[]=(int)$filters['actor_user_id'];}
        if(($q=trim((string)($filters['action']??'')))!==''){$where[]='a.action LIKE ?';$args[]='%'.$q.'%';}
        if(($q=trim((string)($filters['entity_type']??'')))!==''){$where[]='a.entity_type=?';$args[]=$q;}
        if(($q=trim((string)($filters['entity_id']??'')))!==''){$where[]='a.entity_id=?';$args[]=$q;}
        if(($q=trim((string)($filters['outcome']??'')))!==''){$where[]='a.outcome=?';$args[]=$q;}
        if(($q=trim((string)($filters['from']??'')))!==''){$where[]='a.created_at>=?';$args[]=$q.' 00:00:00';}
        if(($q=trim((string)($filters['to']??'')))!==''){$where[]='a.created_at<=?';$args[]=$q.' 23:59:59';}
        $w=implode(' AND ',$where);
        $ct=$pdo->prepare("SELECT COUNT(*) FROM audit_logs a WHERE $w");$ct->execute($args);$total=(int)$ct->fetchColumn();
        $sql="SELECT a.id,a.actor_user_id,u.email actor_email,u.full_name actor_name,a.action,a.entity_type,a.entity_id,a.outcome,a.before_json,a.after_json,a.created_at FROM audit_logs a LEFT JOIN users u ON u.id=a.actor_user_id WHERE $w ORDER BY a.created_at DESC,a.id DESC LIMIT $per OFFSET $offset";
        $st=$pdo->prepare($sql);$st->execute($args);$rows=$st->fetchAll(PDO::FETCH_ASSOC);
        foreach($rows as &$r){$r['before']=$r['before_json']?json_decode($r['before_json'],true):null;$r['after']=$r['after_json']?json_decode($r['after_json'],true):null;unset($r['before_json'],$r['after_json']);$r['link']=self::entityLink((string)$r['entity_type'],(string)($r['entity_id']??''));}unset($r);
        return ['rows'=>$rows,'page'=>$page,'per_page'=>$per,'total'=>$total,'pages'=>(int)ceil($total/$per)];
    }

    public static function auditCsv(PDO $pdo,array $filters=[]): string {
        $filters['page']=1;$filters['per_page']=100;$all=[];$page=1;
        do{$filters['page']=$page;$chunk=self::audit($pdo,$filters);array_push($all,...$chunk['rows']);$page++;}while($page<=$chunk['pages']&&$page<=100);
        $f=fopen('php://temp','r+');fputcsv($f,['id','created_at','actor_email','action','entity_type','entity_id','outcome','before_json','after_json']);
        foreach($all as $r)fputcsv($f,[$r['id'],$r['created_at'],$r['actor_email'],$r['action'],$r['entity_type'],$r['entity_id'],$r['outcome'],json_encode($r['before'],JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES),json_encode($r['after'],JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES)]);
        rewind($f);return stream_get_contents($f);
    }

    public static function entityLink(string $type,string $id): ?string {
        if($id==='')return null;
        return match($type){
            'product'=>'/software-management?product_id='.rawurlencode($id),
            'evidence'=>'/evidence-inbox?evidence_id='.rawurlencode($id),
            'review'=>'/review-moderation?review_id='.rawurlencode($id),
            'evaluation'=>'/evaluation-control?evaluation_id='.rawurlencode($id),
            'user'=>'/admin-users?user_id='.rawurlencode($id),
            default=>null,
        };
    }
}
