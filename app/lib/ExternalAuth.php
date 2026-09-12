<?php
final class ExternalAuth {
  private static function cfg(array $config,string $provider,string $key,string $env,string $default=''):string {
    $v=getenv($env);if($v!==false&&trim((string)$v)!=='')return trim((string)$v);
    return trim((string)($config['oauth'][$provider][$key]??$default));
  }

  public static function provider(array $config,string $provider):array {
    $site=rtrim((string)($config['site_url']??'https://techselectai.com'),'/');
    if($provider==='google')return [
      'name'=>'Google',
      'client_id'=>self::cfg($config,'google','client_id','GOOGLE_OAUTH_CLIENT_ID'),
      'client_secret'=>self::cfg($config,'google','client_secret','GOOGLE_OAUTH_CLIENT_SECRET'),
      'authorize_url'=>'https://accounts.google.com/o/oauth2/v2/auth',
      'token_url'=>'https://oauth2.googleapis.com/token',
      'profile_url'=>'https://openidconnect.googleapis.com/v1/userinfo',
      'scope'=>'openid email profile',
      'redirect_uri'=>$site.'/api/auth/oauth/callback?provider=google',
    ];
    if($provider==='microsoft'){
      $tenant=self::cfg($config,'microsoft','tenant','MICROSOFT_OAUTH_TENANT','common');
      if(!preg_match('/^[A-Za-z0-9._-]+$/',$tenant))$tenant='common';
      return [
        'name'=>'Microsoft',
        'client_id'=>self::cfg($config,'microsoft','client_id','MICROSOFT_OAUTH_CLIENT_ID'),
        'client_secret'=>self::cfg($config,'microsoft','client_secret','MICROSOFT_OAUTH_CLIENT_SECRET'),
        'authorize_url'=>'https://login.microsoftonline.com/'.rawurlencode($tenant).'/oauth2/v2.0/authorize',
        'token_url'=>'https://login.microsoftonline.com/'.rawurlencode($tenant).'/oauth2/v2.0/token',
        'profile_url'=>'https://graph.microsoft.com/v1.0/me?$select=id,displayName,mail,userPrincipalName',
        'scope'=>'openid profile email User.Read',
        'redirect_uri'=>$site.'/api/auth/oauth/callback?provider=microsoft',
      ];
    }
    throw new InvalidArgumentException('unsupported_provider');
  }

  public static function configured(array $config,string $provider):bool {
    try{$p=self::provider($config,$provider);return $p['client_id']!==''&&$p['client_secret']!=='';}catch(Throwable $e){return false;}
  }

  public static function safeNext(?string $next):string {
    $next=trim((string)$next);
    if($next===''||$next[0]!=='/'||str_starts_with($next,'//'))return '/my-consultations';
    return $next;
  }

  public static function begin(array $config,string $provider,string $next):string {
    $p=self::provider($config,$provider);if($p['client_id']===''||$p['client_secret']==='')throw new RuntimeException('provider_not_configured');
    $state=bin2hex(random_bytes(32));$verifier=self::base64url(random_bytes(48));$challenge=self::base64url(hash('sha256',$verifier,true));
    $_SESSION['external_auth'][$state]=['provider'=>$provider,'verifier'=>$verifier,'next'=>self::safeNext($next),'created_at'=>time()];
    self::pruneStates();
    return $p['authorize_url'].'?'.http_build_query([
      'client_id'=>$p['client_id'],'redirect_uri'=>$p['redirect_uri'],'response_type'=>'code','scope'=>$p['scope'],
      'state'=>$state,'code_challenge'=>$challenge,'code_challenge_method'=>'S256','prompt'=>'select_account'
    ],'','&',PHP_QUERY_RFC3986);
  }

  public static function callback(array $config,string $provider,string $state,string $code):array {
    self::pruneStates();$saved=$_SESSION['external_auth'][$state]??null;unset($_SESSION['external_auth'][$state]);
    if(!$saved||!hash_equals((string)($saved['provider']??''),$provider)||(time()-(int)($saved['created_at']??0))>600)throw new RuntimeException('invalid_oauth_state');
    if($code==='')throw new RuntimeException('missing_authorization_code');
    $p=self::provider($config,$provider);
    $token=self::postForm($p['token_url'],[
      'client_id'=>$p['client_id'],'client_secret'=>$p['client_secret'],'code'=>$code,'redirect_uri'=>$p['redirect_uri'],
      'grant_type'=>'authorization_code','code_verifier'=>(string)$saved['verifier']
    ]);
    $access=(string)($token['access_token']??'');if($access==='')throw new RuntimeException('oauth_token_exchange_failed');
    $profile=self::getJson($p['profile_url'],$access);
    if($provider==='google'){
      $subject=trim((string)($profile['sub']??''));$email=strtolower(trim((string)($profile['email']??'')));$name=trim((string)($profile['name']??''));
      if(isset($profile['email_verified'])&&!filter_var($profile['email_verified'],FILTER_VALIDATE_BOOLEAN))throw new RuntimeException('provider_email_not_verified');
    }else{
      $subject=trim((string)($profile['id']??''));$email=strtolower(trim((string)($profile['mail']??$profile['userPrincipalName']??'')));$name=trim((string)($profile['displayName']??''));
    }
    if($subject===''||!filter_var($email,FILTER_VALIDATE_EMAIL))throw new RuntimeException('provider_email_unavailable');
    return ['provider'=>$provider,'subject'=>$subject,'email'=>$email,'name'=>$name?:'TechSelectAI User','next'=>(string)$saved['next']];
  }

  public static function signIn(PDO $pdo,array $identity):array {
    $provider=(string)$identity['provider'];$subject=(string)$identity['subject'];$email=(string)$identity['email'];$name=(string)$identity['name'];
    $pdo->beginTransaction();
    try{
      $st=$pdo->prepare("SELECT u.id,u.email,u.full_name,u.role,u.status FROM external_auth_identities x JOIN users u ON u.id=x.user_id WHERE x.provider=? AND x.provider_subject=? LIMIT 1");
      $st->execute([$provider,$subject]);$u=$st->fetch();
      if(!$u){
        $st=$pdo->prepare("SELECT id,email,full_name,role,status FROM users WHERE email=? LIMIT 1 FOR UPDATE");$st->execute([$email]);$u=$st->fetch();
        if($u){
          if(!in_array($u['status'],['active','pending'],true))throw new RuntimeException('account_unavailable');
          if($u['status']==='pending'){$pdo->prepare("UPDATE users SET status='active',email_verified_at=COALESCE(email_verified_at,NOW()) WHERE id=?")->execute([$u['id']]);$u['status']='active';}
        }else{
          $random=password_hash(bin2hex(random_bytes(32)),PASSWORD_DEFAULT);
          $pdo->prepare("INSERT INTO users(email,password_hash,full_name,role,status,email_verified_at) VALUES(?,?,?,'user','active',NOW())")->execute([$email,$random,$name]);
          $uid=(int)$pdo->lastInsertId();
          $pdo->prepare("INSERT INTO user_plan_assignments(user_id,plan_code,plan_status,source) VALUES(?,'free_registered','active','external_auth')")->execute([$uid]);
          $u=['id'=>$uid,'email'=>$email,'full_name'=>$name,'role'=>'user','status'=>'active'];
        }
        $pdo->prepare("INSERT INTO external_auth_identities(user_id,provider,provider_subject,provider_email,last_login_at) VALUES(?,?,?,?,NOW())")->execute([(int)$u['id'],$provider,$subject,$email]);
      }else{
        if($u['status']!=='active')throw new RuntimeException('account_unavailable');
        $pdo->prepare("UPDATE external_auth_identities SET provider_email=?,last_login_at=NOW() WHERE provider=? AND provider_subject=?")->execute([$email,$provider,$subject]);
      }
      $pdo->prepare("UPDATE users SET last_login_at=NOW() WHERE id=?")->execute([$u['id']]);$pdo->commit();
      return ['id'=>(int)$u['id'],'email'=>$u['email'],'name'=>$u['full_name'],'role'=>$u['role']];
    }catch(Throwable $e){if($pdo->inTransaction())$pdo->rollBack();throw $e;}
  }

  private static function pruneStates():void {
    if(empty($_SESSION['external_auth'])||!is_array($_SESSION['external_auth']))return;$cut=time()-600;
    foreach($_SESSION['external_auth'] as $k=>$v)if((int)($v['created_at']??0)<$cut)unset($_SESSION['external_auth'][$k]);
    if(count($_SESSION['external_auth'])>8)$_SESSION['external_auth']=array_slice($_SESSION['external_auth'],-8,null,true);
  }
  private static function base64url(string $v):string{return rtrim(strtr(base64_encode($v),'+/','-_'),'=');}
  private static function postForm(string $url,array $fields):array {
    return self::httpJson($url,['Content-Type: application/x-www-form-urlencoded'],http_build_query($fields,'','&',PHP_QUERY_RFC3986));
  }
  private static function getJson(string $url,string $accessToken):array {return self::httpJson($url,['Authorization: Bearer '.$accessToken],null);}
  private static function httpJson(string $url,array $headers,?string $body):array {
    if(!function_exists('curl_init'))throw new RuntimeException('oauth_http_client_unavailable');
    $ch=curl_init($url);curl_setopt_array($ch,[CURLOPT_RETURNTRANSFER=>true,CURLOPT_FOLLOWLOCATION=>false,CURLOPT_CONNECTTIMEOUT=>5,CURLOPT_TIMEOUT=>12,CURLOPT_HTTPHEADER=>$headers,CURLOPT_USERAGENT=>'TechSelectAI/1.0']);
    if($body!==null){curl_setopt($ch,CURLOPT_POST,true);curl_setopt($ch,CURLOPT_POSTFIELDS,$body);} $raw=curl_exec($ch);$status=(int)curl_getinfo($ch,CURLINFO_RESPONSE_CODE);$err=curl_error($ch);curl_close($ch);
    if($raw===false||$status<200||$status>=300)throw new RuntimeException('oauth_provider_request_failed'.($err?':'.$err:''));
    $data=json_decode((string)$raw,true);if(!is_array($data))throw new RuntimeException('oauth_provider_invalid_response');return $data;
  }
}
