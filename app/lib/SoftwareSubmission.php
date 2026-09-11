<?php
final class SoftwareSubmission {
  public static function normalize(string $name): string {
    $name=mb_strtolower(trim($name),'UTF-8');
    $name=preg_replace('/[^a-z0-9]+/u',' ',iconv('UTF-8','ASCII//TRANSLIT//IGNORE',$name)?:$name)??$name;
    return trim(preg_replace('/\s+/',' ',$name)??$name);
  }

  public static function findDuplicate(PDO $pdo,string $productName,?string $website=null): ?array {
    $normalized=self::normalize($productName);
    $q=$pdo->prepare("SELECT id,name,slug,website_url FROM products WHERE LOWER(name)=LOWER(?) OR REPLACE(REPLACE(LOWER(name),'-',' '),'_',' ')=? LIMIT 1");
    $q->execute([$productName,$normalized]);
    if($row=$q->fetch(PDO::FETCH_ASSOC))return ['product'=>$row,'reason'=>'matching product name'];

    try{
      $q=$pdo->prepare("SELECT p.id,p.name,p.slug,p.website_url FROM product_aliases a JOIN products p ON p.id=a.product_id WHERE a.normalized_alias=? LIMIT 1");
      $q->execute([$normalized]);
      if($row=$q->fetch(PDO::FETCH_ASSOC))return ['product'=>$row,'reason'=>'matching known alias'];
    }catch(Throwable $e){}

    if($website){
      $host=parse_url($website,PHP_URL_HOST);
      if($host){
        $host=preg_replace('/^www\./i','',strtolower($host));
        $q=$pdo->query("SELECT id,name,slug,website_url FROM products WHERE website_url IS NOT NULL");
        foreach($q->fetchAll(PDO::FETCH_ASSOC) as $row){
          $existingHost=parse_url((string)$row['website_url'],PHP_URL_HOST);
          if($existingHost && preg_replace('/^www\./i','',strtolower($existingHost))===$host)return ['product'=>$row,'reason'=>'matching official website'];
        }
      }
    }
    return null;
  }

  public static function create(PDO $pdo,array $input): array {
    $type=(string)($input['submission_type']??'user_suggestion');
    if(!in_array($type,['vendor_submission','user_suggestion'],true))throw new InvalidArgumentException('invalid_submission_type');
    $name=trim((string)($input['product_name']??''));
    if($name===''||mb_strlen($name)>190)throw new InvalidArgumentException('invalid_product_name');
    $website=trim((string)($input['official_website']??''));
    if($website!==''&&!filter_var($website,FILTER_VALIDATE_URL))throw new InvalidArgumentException('invalid_website');
    $email=trim((string)($input['submitter_email']??''));
    if($email!==''&&!filter_var($email,FILTER_VALIDATE_EMAIL))throw new InvalidArgumentException('invalid_email');

    $dup=self::findDuplicate($pdo,$name,$website?:null);
    $status=$dup?'duplicate_detected':'new';
    $ipHash=hash('sha256',$_SERVER['REMOTE_ADDR']??'',true);
    $st=$pdo->prepare("INSERT INTO software_submissions(submission_type,product_name,normalized_product_name,vendor_name,official_website,category_id,short_description,pricing_url,documentation_url,security_url,integrations_url,deployment_options,submitter_email,supporting_notes,reference_asset_url,existing_product_id,duplicate_reason,status,ip_hash) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
    $st->execute([
      $type,$name,self::normalize($name),trim((string)($input['vendor_name']??''))?:null,$website?:null,
      !empty($input['category_id'])?(int)$input['category_id']:null,trim((string)($input['short_description']??''))?:null,
      trim((string)($input['pricing_url']??''))?:null,trim((string)($input['documentation_url']??''))?:null,
      trim((string)($input['security_url']??''))?:null,trim((string)($input['integrations_url']??''))?:null,
      trim((string)($input['deployment_options']??''))?:null,$email?:null,trim((string)($input['supporting_notes']??''))?:null,
      trim((string)($input['reference_asset_url']??''))?:null,$dup?(int)$dup['product']['id']:null,$dup['reason']??null,$status,$ipHash
    ]);
    return ['id'=>(int)$pdo->lastInsertId(),'status'=>$status,'duplicate'=>$dup];
  }

  public static function createDraftProduct(PDO $pdo,array $submission): int {
    if(($submission['status']??'')!=='approved_for_draft')throw new RuntimeException('submission_not_approved_for_draft');
    if(!empty($submission['created_product_id']))return (int)$submission['created_product_id'];
    if(!empty($submission['existing_product_id']))throw new RuntimeException('existing_product_submission');
    $slug=preg_replace('/[^a-z0-9]+/','-',self::normalize((string)$submission['product_name']))?:'software';
    $slug=trim($slug,'-');$base=$slug;$n=2;
    $chk=$pdo->prepare('SELECT 1 FROM products WHERE slug=? LIMIT 1');
    while(true){$chk->execute([$slug]);if(!$chk->fetchColumn())break;$slug=$base.'-'.$n++;}
    $st=$pdo->prepare("INSERT INTO products(category_id,name,slug,short_description,website_url,status) VALUES(?,?,?,?,?,'draft')");
    $st->execute([$submission['category_id']?:null,$submission['product_name'],$slug,$submission['short_description']?:null,$submission['official_website']?:null]);
    $id=(int)$pdo->lastInsertId();
    $pdo->prepare('UPDATE software_submissions SET created_product_id=? WHERE id=?')->execute([$id,$submission['id']]);
    return $id;
  }
}
