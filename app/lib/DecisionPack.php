<?php
require_once __DIR__.'/Entitlements.php';
require_once __DIR__.'/PartnerDiscovery.php';

final class DecisionPack {
    public const VERSION='decision-pack-v1';

    public static function build(PDO $pdo,int $projectId,int $userId,array $narrative=[]): array {
        $st=$pdo->prepare("SELECT * FROM selection_projects WHERE id=? AND user_id=? LIMIT 1");$st->execute([$projectId,$userId]);$project=$st->fetch(PDO::FETCH_ASSOC);if(!$project)throw new RuntimeException('project_not_found');
        $sections=[];$missing=[];
        $sections['executive_summary']=['source'=>'TechSelectAI analysis','content'=>$narrative['executive_summary']??'Generated from the saved selection project, shortlist and supporting decision artifacts.'];
        $sections['business_need']=['source'=>'Buyer input','content'=>$project['business_problem']??($project['description']??null)];
        $sections['requirements']=['source'=>'Buyer confirmed requirements','items'=>self::rows($pdo,"SELECT requirement_text,priority,is_mandatory,user_confirmed FROM selection_project_requirements WHERE selection_project_id=? ORDER BY is_mandatory DESC,priority",[$projectId])];
        if(!$sections['requirements']['items'])$missing[]='Confirmed requirements';
        $matrix=self::rows($pdo,"SELECT s.product_id,p.name product_name,p.slug product_slug,s.project_fit_score,s.baseline_evaluation_score,s.mandatory_gap_count,s.shortlist_state,s.score_breakdown_json,s.rationale_json FROM selection_project_shortlist s JOIN products p ON p.id=s.product_id WHERE s.selection_project_id=? ORDER BY s.project_fit_score DESC",[$projectId]);
        $sections['decision_matrix']=['source'=>'TechSelectAI project fit analysis','items'=>$matrix];if(!$matrix)$missing[]='Weighted decision matrix / shortlist';
        $preferred=null;foreach($matrix as $m){if(($m['shortlist_state']??'')==='preferred'){$preferred=$m;break;}}if(!$preferred&&$matrix)$preferred=$matrix[0];
        $sections['recommendation']=['source'=>'TechSelectAI analysis + buyer shortlist state','preferred'=>$preferred,'narrative'=>$narrative['recommendation']??null];
        if($preferred){$partners=PartnerDiscovery::find($pdo,(int)$preferred['product_id'],(string)($project['country_code']??''),[]);$sections['verified_partners']=['source'=>'Verified company-product relationships','items'=>$partners];}
        else {$sections['verified_partners']=['source'=>'Verified company-product relationships','items'=>[]];$missing[]='Preferred software';}
        $sections['roi_tco']=['source'=>'Buyer assumptions + ROI/TCO model','items'=>self::safeRows($pdo,"SELECT * FROM roi_tco_models WHERE selection_project_id=? ORDER BY updated_at DESC LIMIT 1",[$projectId])];if(!$sections['roi_tco']['items'])$missing[]='ROI/TCO model';
        $sections['business_case']=['source'=>'Business Case Builder','items'=>self::safeRows($pdo,"SELECT id,title,status,updated_at FROM business_cases WHERE selection_project_id=? ORDER BY updated_at DESC LIMIT 1",[$projectId])];if(!$sections['business_case']['items'])$missing[]='Business case';
        $sections['rfp']=['source'=>'RFP Generator','items'=>self::safeRows($pdo,"SELECT id,title,status,updated_at FROM rfp_documents WHERE selection_project_id=? ORDER BY updated_at DESC LIMIT 1",[$projectId])];if(!$sections['rfp']['items'])$missing[]='RFP';
        $sections['risks_assumptions']=['source'=>'Buyer input / explicit assumptions','content'=>$narrative['risks_assumptions']??null];
        $sections['provenance']=['source'=>'System','legend'=>['verified_fact'=>'Verified fact/evidence','community_signal'=>'Reviewed community signal','analysis'=>'TechSelectAI analysis','buyer_assumption'=>'Buyer-provided assumption']];
        return ['version'=>self::VERSION,'project'=>$project,'sections'=>$sections,'missing_data'=>$missing,'generated_at'=>gmdate('c')];
    }

    private static function rows(PDO $pdo,string $sql,array $params): array {$st=$pdo->prepare($sql);$st->execute($params);return $st->fetchAll(PDO::FETCH_ASSOC);}
    private static function safeRows(PDO $pdo,string $sql,array $params): array {try{return self::rows($pdo,$sql,$params);}catch(Throwable $e){return [];}}
}
