<?php
final class CustomerOutcomes {
  private const VERIFICATION=['draft','in_review','verified','rejected'];
  private const PUBLICATION=['draft','published','archived'];
  private const VISIBILITY=['anonymous','named'];

  public static function listAdmin(PDO $pdo): array {
    return $pdo->query("SELECT co.*,p.name product_name,p.slug product_slug,c.name category_name,c.slug category_slug
      FROM customer_outcomes co
      LEFT JOIN products p ON p.id=co.product_id
      LEFT JOIN categories c ON c.id=co.category_id
      ORDER BY co.updated_at DESC,co.id DESC")->fetchAll();
  }

  public static function get(PDO $pdo,int $id): array {
    $st=$pdo->prepare("SELECT co.*,p.name product_name,p.slug product_slug,c.name category_name,c.slug category_slug
      FROM customer_outcomes co
      LEFT JOIN products p ON p.id=co.product_id
      LEFT JOIN categories c ON c.id=co.category_id
      WHERE co.id=?");
    $st->execute([$id]);$r=$st->fetch();if(!$r)throw new InvalidArgumentException('customer_outcome_not_found');return $r;
  }

  public static function publicList(PDO $pdo): array {
    $st=$pdo->query("SELECT co.id,co.slug,co.title,co.summary,co.visibility_mode,co.customer_name,co.customer_name_approved,
      co.industry,co.country,co.company_size,co.problem,co.measurable_outcome,co.outcome_date,co.published_at,
      p.name product_name,p.slug product_slug,c.name category_name,c.slug category_slug
      FROM customer_outcomes co
      LEFT JOIN products p ON p.id=co.product_id
      LEFT JOIN categories c ON c.id=co.category_id
      WHERE co.verification_status='verified' AND co.publication_status='published'
        AND co.approved_by IS NOT NULL AND co.approved_at IS NOT NULL AND co.published_at IS NOT NULL
      ORDER BY COALESCE(co.outcome_date,DATE(co.published_at)) DESC,co.id DESC");
    return $st->fetchAll();
  }

  public static function publicBySlug(PDO $pdo,string $slug): ?array {
    $st=$pdo->prepare("SELECT co.*,p.name product_name,p.slug product_slug,c.name category_name,c.slug category_slug
      FROM customer_outcomes co
      LEFT JOIN products p ON p.id=co.product_id
      LEFT JOIN categories c ON c.id=co.category_id
      WHERE co.slug=? AND co.verification_status='verified' AND co.publication_status='published'
        AND co.approved_by IS NOT NULL AND co.approved_at IS NOT NULL AND co.published_at IS NOT NULL LIMIT 1");
    $st->execute([$slug]);$r=$st->fetch();return $r?:null;
  }

  public static function save(PDO $pdo,array $b,int $userId,?int $id=null): array {
    $slug=self::slug((string)($b['slug']??''));
    $title=trim((string)($b['title']??''));$problem=trim((string)($b['problem']??''));
    if($slug===''||$title===''||$problem==='')throw new InvalidArgumentException('slug_title_problem_required');
    $visibility=(string)($b['visibility_mode']??'anonymous');if(!in_array($visibility,self::VISIBILITY,true))throw new InvalidArgumentException('invalid_visibility');
    $verification=(string)($b['verification_status']??'draft');if(!in_array($verification,self::VERIFICATION,true))throw new InvalidArgumentException('invalid_verification_status');
    $publication=(string)($b['publication_status']??'draft');if(!in_array($publication,self::PUBLICATION,true))throw new InvalidArgumentException('invalid_publication_status');
    if($publication==='published'&&$verification!=='verified')throw new InvalidArgumentException('verified_required_before_publish');
    $productId=self::nullableId($b['product_id']??null);$categoryId=self::nullableId($b['category_id']??null);
    self::assertLink($pdo,'products',$productId);self::assertLink($pdo,'categories',$categoryId);
    $namedApproved=!empty($b['customer_name_approved'])?1:0;$logoApproved=!empty($b['customer_logo_approved'])?1:0;
    if($visibility!=='named'){$namedApproved=0;$logoApproved=0;}
    if($logoApproved&&!$namedApproved)throw new InvalidArgumentException('customer_name_approval_required_for_logo');
    $customerName=self::nullableText($b['customer_name']??null);$logo=self::nullableText($b['customer_logo_url']??null);
    if($namedApproved&&$customerName===null)throw new InvalidArgumentException('approved_customer_name_required');
    $approvedBy=$verification==='verified'?$userId:null;$approvedAt=$verification==='verified'?date('Y-m-d H:i:s'):null;
    $publishedAt=$publication==='published'?date('Y-m-d H:i:s'):null;
    $vals=[
      $slug,$title,self::nullableText($b['summary']??null),$productId,$categoryId,$visibility,$customerName,$logo,$namedApproved,$logoApproved,
      self::nullableText($b['industry']??null),self::nullableText($b['country']??null),self::nullableText($b['company_size']??null),$problem,
      self::nullableText($b['requirements_text']??null),self::nullableText($b['options_evaluated']??null),self::nullableText($b['recommendation']??null),
      self::nullableText($b['rationale']??null),self::nullableText($b['implementation_decision']??null),self::nullableText($b['measurable_outcome']??null),
      self::nullableDate($b['outcome_date']??null),self::nullableText($b['evidence_notes']??null),$verification,$publication,self::nullableText($b['approval_notes']??null),
      $approvedBy,$approvedAt,$publishedAt,$userId
    ];
    if($id===null){
      $sql="INSERT INTO customer_outcomes (slug,title,summary,product_id,category_id,visibility_mode,customer_name,customer_logo_url,customer_name_approved,customer_logo_approved,industry,country,company_size,problem,requirements_text,options_evaluated,recommendation,rationale,implementation_decision,measurable_outcome,outcome_date,evidence_notes,verification_status,publication_status,approval_notes,approved_by,approved_at,published_at,created_by,updated_by) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
      $vals[]=$userId;$st=$pdo->prepare($sql);$st->execute($vals);$id=(int)$pdo->lastInsertId();
    }else{
      self::get($pdo,$id);
      $sql="UPDATE customer_outcomes SET slug=?,title=?,summary=?,product_id=?,category_id=?,visibility_mode=?,customer_name=?,customer_logo_url=?,customer_name_approved=?,customer_logo_approved=?,industry=?,country=?,company_size=?,problem=?,requirements_text=?,options_evaluated=?,recommendation=?,rationale=?,implementation_decision=?,measurable_outcome=?,outcome_date=?,evidence_notes=?,verification_status=?,publication_status=?,approval_notes=?,approved_by=?,approved_at=?,published_at=?,updated_by=? WHERE id=?";
      $vals[]=$id;$pdo->prepare($sql)->execute($vals);
    }
    return self::get($pdo,$id);
  }

  public static function publicCustomerLabel(array $r): string {
    if(($r['visibility_mode']??'anonymous')==='named'&&!empty($r['customer_name_approved'])&&!empty($r['customer_name']))return (string)$r['customer_name'];
    $parts=array_values(array_filter([(string)($r['industry']??''),(string)($r['country']??''),(string)($r['company_size']??'')]));
    return $parts?implode(' · ',$parts):'Verified customer outcome';
  }

  private static function assertLink(PDO $pdo,string $table,?int $id): void {if($id===null)return;$st=$pdo->prepare("SELECT 1 FROM {$table} WHERE id=?");$st->execute([$id]);if(!$st->fetchColumn())throw new InvalidArgumentException('invalid_'.$table.'_id');}
  private static function nullableId($v): ?int {return ($v===null||$v==='')?null:(int)$v;}
  private static function nullableText($v): ?string {$s=trim((string)$v);return $s===''?null:$s;}
  private static function nullableDate($v): ?string {$s=trim((string)$v);if($s==='')return null;$d=DateTime::createFromFormat('Y-m-d',$s);if(!$d||$d->format('Y-m-d')!==$s)throw new InvalidArgumentException('invalid_outcome_date');return $s;}
  private static function slug(string $s): string {$s=strtolower(trim($s));$s=preg_replace('/[^a-z0-9]+/','-',$s)??'';return trim($s,'-');}
}
