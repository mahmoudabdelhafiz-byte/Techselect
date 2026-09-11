<?php
require_once __DIR__.'/PartnerDiscovery.php';

final class DecisionPack {
    public const VERSION='decision-pack-v1.0';

    public static function build(PDO $pdo,int $projectId,int $userId,array $narrative=[]): array {
        $st=$pdo->prepare("SELECT * FROM selection_projects WHERE id=? AND user_id=? LIMIT 1");
        $st->execute([$projectId,$userId]);
        $project=$st->fetch(PDO::FETCH_ASSOC);
        if(!$project)throw new RuntimeException('project_not_found');

        $countries=self::decodeList($project['country_codes_json']??null);
        $country=(string)($countries[0]??'');
        $sections=[];$missing=[];

        $sections['executive_summary']=[
            'source'=>'TechSelectAI analysis',
            'provenance'=>'analysis',
            'content'=>trim((string)($narrative['executive_summary']??'')) ?: 'Generated from the saved selection project, decision matrix and linked decision-support artifacts.'
        ];
        $sections['business_need']=[
            'source'=>'Buyer input',
            'provenance'=>'buyer_assumption',
            'content'=>$project['strategic_objectives']??null,
            'context'=>[
                'industry'=>$project['industry_text']??null,
                'company_size'=>$project['company_size_band']??null,
                'countries'=>$countries,
                'expected_users'=>$project['expected_users']??null,
                'implementation_timeline'=>$project['implementation_timeline']??null,
                'deployment_preference'=>$project['deployment_preference']??null,
            ],
        ];
        if(empty($project['strategic_objectives']))$missing[]='Business need / strategic objectives';

        $requirements=self::rows($pdo,"SELECT requirement_text,priority,is_mandatory,user_confirmed,source FROM selection_project_requirements WHERE project_id=? ORDER BY is_mandatory DESC,FIELD(priority,'mandatory','important','preferred'),id",[$projectId]);
        $sections['requirements']=['source'=>'Buyer confirmed requirements','provenance'=>'buyer_assumption','items'=>$requirements];
        if(!$requirements)$missing[]='Confirmed requirements';

        $matrix=self::safeRows($pdo,"SELECT s.product_id,p.name product_name,p.slug product_slug,v.name vendor_name,s.project_fit_score,s.baseline_evaluation_score,s.mandatory_gap_count,s.shortlist_state,s.score_breakdown_json,s.rationale_json,s.updated_at FROM selection_project_shortlist s JOIN products p ON p.id=s.product_id LEFT JOIN vendors v ON v.id=p.vendor_id WHERE s.project_id=? ORDER BY s.mandatory_gap_count,s.project_fit_score DESC,p.name",[$projectId]);
        foreach($matrix as &$row){$row['score_breakdown']=self::decodeObject($row['score_breakdown_json']??null);$row['rationale']=self::decodeObject($row['rationale_json']??null);unset($row['score_breakdown_json'],$row['rationale_json']);}unset($row);
        $sections['market_scan']=['source'=>'Saved decision matrix / considered products','provenance'=>'analysis','items'=>array_map(static fn($r)=>['product_id'=>$r['product_id'],'product_name'=>$r['product_name'],'vendor_name'=>$r['vendor_name'],'shortlist_state'=>$r['shortlist_state']],$matrix)];
        $sections['methodology']=['source'=>'TechSelectAI methodology','provenance'=>'analysis','version'=>self::latestMatrixVersion($pdo,$projectId),'note'=>'Project-specific fit remains separate from the general Product Evaluation score.'];
        $sections['decision_matrix']=['source'=>'TechSelectAI project fit analysis','provenance'=>'analysis','items'=>$matrix];
        if(!$matrix)$missing[]='Weighted decision matrix / shortlist';

        $preferred=null;
        foreach($matrix as $m){if(($m['shortlist_state']??'')==='preferred'){$preferred=$m;break;}}
        if(!$preferred&&$matrix)$preferred=$matrix[0];
        $sections['recommendation']=['source'=>'TechSelectAI analysis + buyer shortlist state','provenance'=>'analysis','preferred'=>$preferred,'narrative'=>trim((string)($narrative['recommendation']??''))?:null];
        if(!$preferred)$missing[]='Preferred software';

        $partners=[];
        if($preferred)$partners=PartnerDiscovery::find($pdo,(int)$preferred['product_id'],$country,[]);
        $sections['verified_partners']=['source'=>'Verified company-product relationships','provenance'=>'verified_fact','territory'=>$country?:null,'items'=>$partners];

        $roi=self::safeRows($pdo,"SELECT id,title,status,currency,horizon_years,assumptions_json,verified_pricing_json,results_json,scenario_json,source_snapshot_json,business_case_id,updated_at FROM roi_tco_models WHERE project_id=? AND user_id=? ORDER BY updated_at DESC LIMIT 1",[$projectId,$userId]);
        foreach($roi as &$r){foreach(['assumptions_json','verified_pricing_json','results_json','scenario_json','source_snapshot_json'] as $k){$r[$k]=self::decodeObject($r[$k]??null);}}unset($r);
        $sections['roi_tco']=['source'=>'Buyer assumptions + ROI/TCO model','provenance'=>'buyer_assumption','items'=>$roi];
        if(!$roi)$missing[]='ROI/TCO model';

        $businessCase=[];
        $bcId=(int)($roi[0]['business_case_id']??0);
        if($bcId>0)$businessCase=self::safeRows($pdo,"SELECT id,title,status,assumptions_json,verified_facts_json,generated_output_json,updated_at FROM business_cases WHERE id=? AND user_id=? LIMIT 1",[$bcId,$userId]);
        foreach($businessCase as &$b){foreach(['assumptions_json','verified_facts_json','generated_output_json'] as $k){$b[$k]=self::decodeObject($b[$k]??null);}}unset($b);
        $sections['business_case']=['source'=>'Business Case Builder','provenance'=>'mixed','items'=>$businessCase];
        if(!$businessCase)$missing[]='Business case linked to this project/ROI model';

        $rfp=self::safeRows($pdo,"SELECT id,title,status,selected_product_ids_json,source_snapshot_json,sections_json,updated_at FROM rfp_documents WHERE project_id=? AND user_id=? ORDER BY updated_at DESC LIMIT 1",[$projectId,$userId]);
        foreach($rfp as &$r){foreach(['selected_product_ids_json','source_snapshot_json','sections_json'] as $k){$r[$k]=self::decodeObject($r[$k]??null);}}unset($r);
        $sections['rfp']=['source'=>'RFP Generator','provenance'=>'mixed','items'=>$rfp];
        if(!$rfp)$missing[]='RFP';

        $sections['risks_assumptions']=['source'=>'Buyer input / explicit assumptions','provenance'=>'buyer_assumption','content'=>trim((string)($narrative['risks_assumptions']??''))?:null];
        $sections['final_decision']=['source'=>'Buyer decision + TechSelectAI analysis','provenance'=>'mixed','content'=>trim((string)($narrative['final_decision']??''))?:null,'preferred_product'=>$preferred?['id'=>(int)$preferred['product_id'],'name'=>$preferred['product_name']]:null];
        $sections['provenance']=['source'=>'System','legend'=>['verified_fact'=>'Verified fact/evidence','community_signal'=>'Reviewed community signal','analysis'=>'TechSelectAI analysis','buyer_assumption'=>'Buyer-provided assumption','mixed'=>'Contains multiple labeled source types']];

        return [
            'version'=>self::VERSION,
            'project'=>['id'=>(int)$project['id'],'name'=>$project['name'],'status'=>$project['status'],'version'=>(int)$project['version']],
            'sections'=>$sections,
            'missing_data'=>array_values(array_unique($missing)),
            'generated_at'=>gmdate('c'),
            'scope_boundary'=>'Decision support and procurement handoff only; no requisition, approval, PO, contract execution, invoicing or procurement operations.'
        ];
    }

    private static function latestMatrixVersion(PDO $pdo,int $projectId): ?string {try{$st=$pdo->prepare("SELECT scoring_version FROM selection_project_matrix_runs WHERE project_id=? ORDER BY id DESC LIMIT 1");$st->execute([$projectId]);$v=$st->fetchColumn();return $v!==false?(string)$v:null;}catch(Throwable $e){return null;}}
    private static function rows(PDO $pdo,string $sql,array $params): array {$st=$pdo->prepare($sql);$st->execute($params);return $st->fetchAll(PDO::FETCH_ASSOC);}
    private static function safeRows(PDO $pdo,string $sql,array $params): array {try{return self::rows($pdo,$sql,$params);}catch(Throwable $e){return [];}}
    private static function decodeList($value): array {$d=$value?json_decode((string)$value,true):[];return is_array($d)?array_values($d):[];}
    private static function decodeObject($value): array {$d=$value?json_decode((string)$value,true):[];return is_array($d)?$d:[];}
}
