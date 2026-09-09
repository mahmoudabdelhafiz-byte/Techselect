<?php
require_once __DIR__.'/CategoryGuard.php';
final class AiExtraction {
  public static function extract(PDO $pdo,array $config,string $message,array $context=[]): array {
    $caps=$pdo->query("SELECT c.slug,c.name FROM capabilities c WHERE c.is_active=1 ORDER BY c.name")->fetchAll();
    $categories=$pdo->query("SELECT slug,name FROM categories WHERE is_active=1 ORDER BY name")->fetchAll();
    $allowedCaps=array_column($caps,'slug');
    $allowedCategories=array_column($categories,'slug');
    $explicitCategory=CategoryGuard::detectExplicit($context,$message,$allowedCategories);
    $capabilityCategoryMap=CategoryGuard::capabilityCategoryMap($pdo);

    if(empty($config['openai_api_key'])){
      return [
        'assistant_message'=>'I saved your message, but AI extraction is not configured on this server yet. You can still confirm requirements manually.',
        'category_slug'=>$explicitCategory,
        'requirements'=>[],
        'company'=>['country'=>null,'industry'=>null,'employee_count'=>null,'expected_users'=>null],
        'budget'=>['min'=>null,'max'=>null,'currency'=>null,'period'=>null],
        'deployment_preferences'=>[],
        'integrations'=>[],
        'languages'=>[],
        'follow_up_questions'=>[]
      ];
    }

    $schema=[
      'type'=>'object','additionalProperties'=>false,
      'properties'=>[
        'assistant_message'=>['type'=>'string'],
        'category_slug'=>['type'=>['string','null'],'enum'=>array_merge($allowedCategories,[null])],
        'company'=>['type'=>'object','additionalProperties'=>false,'properties'=>[
          'country'=>['type'=>['string','null']], 'industry'=>['type'=>['string','null']],
          'employee_count'=>['type'=>['integer','null']], 'expected_users'=>['type'=>['integer','null']]
        ],'required'=>['country','industry','employee_count','expected_users']],
        'budget'=>['type'=>'object','additionalProperties'=>false,'properties'=>[
          'min'=>['type'=>['number','null']], 'max'=>['type'=>['number','null']],
          'currency'=>['type'=>['string','null']], 'period'=>['type'=>['string','null']]
        ],'required'=>['min','max','currency','period']],
        'requirements'=>['type'=>'array','items'=>['type'=>'object','additionalProperties'=>false,'properties'=>[
          'capability_slug'=>['type'=>['string','null'],'enum'=>array_merge($allowedCaps,[null])],
          'text'=>['type'=>'string'],
          'priority'=>['type'=>'string','enum'=>['must_have','important','nice_to_have']],
          'mandatory'=>['type'=>'boolean'],
          'confidence'=>['type'=>'number','minimum'=>0,'maximum'=>1]
        ],'required'=>['capability_slug','text','priority','mandatory','confidence']]],
        'deployment_preferences'=>['type'=>'array','items'=>['type'=>'string']],
        'integrations'=>['type'=>'array','items'=>['type'=>'string']],
        'languages'=>['type'=>'array','items'=>['type'=>'string']],
        'follow_up_questions'=>['type'=>'array','items'=>['type'=>'string']]
      ],
      'required'=>['assistant_message','category_slug','company','budget','requirements','deployment_preferences','integrations','languages','follow_up_questions']
    ];

    $instructions='You are TechSelectAI, an independent software-selection consultant. Extract only requirements explicitly stated or strongly implied by the user. Use only the supplied category and capability slugs. An explicitly named software category in the user context has priority and must never be silently replaced by another category. Keep mapped capabilities within the selected primary category; cross-category needs should be described as context or integrations unless the user explicitly requests a multi-category evaluation. Never invent vendor facts, pricing, compliance, capabilities or rankings. Unknown is not unsupported. Mark inferred or ambiguous requirements with lower confidence and ask only follow-up questions that can materially change the recommendation.';
    if($explicitCategory)$instructions.=' The user explicitly selected category slug '.$explicitCategory.'. Keep that as the primary category.';
    $input="Known categories: ".json_encode($categories,JSON_UNESCAPED_UNICODE)."\nKnown capabilities: ".json_encode($caps,JSON_UNESCAPED_UNICODE)."\nRecent context: ".json_encode($context,JSON_UNESCAPED_UNICODE)."\nLatest user message: ".$message;
    $payload=[
      'model'=>$config['openai_model'] ?: 'gpt-5',
      'instructions'=>$instructions,
      'input'=>$input,
      'text'=>['format'=>['type'=>'json_schema','name'=>'techselect_requirement_extraction','strict'=>true,'schema'=>$schema]]
    ];

    $ch=curl_init('https://api.openai.com/v1/responses');
    curl_setopt_array($ch,[CURLOPT_POST=>true,CURLOPT_RETURNTRANSFER=>true,CURLOPT_TIMEOUT=>45,
      CURLOPT_HTTPHEADER=>['Authorization: Bearer '.$config['openai_api_key'],'Content-Type: application/json'],
      CURLOPT_POSTFIELDS=>json_encode($payload,JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES)]);
    $raw=curl_exec($ch);$status=(int)curl_getinfo($ch,CURLINFO_RESPONSE_CODE);$err=curl_error($ch);curl_close($ch);
    if($raw===false || $status<200 || $status>=300) throw new RuntimeException('AI extraction failed'.($err?': '.$err:''));
    $data=json_decode($raw,true);$text=$data['output_text']??null;
    if(!$text && !empty($data['output'])) foreach($data['output'] as $item) foreach(($item['content']??[]) as $content) if(($content['type']??'')==='output_text'){$text=$content['text']??null;break 2;}
    if(!$text) throw new RuntimeException('AI response did not contain structured output');
    $result=json_decode($text,true);if(!is_array($result)) throw new RuntimeException('AI response was not valid JSON');

    $modelCategory=$result['category_slug']??null;
    if($explicitCategory)$result['category_slug']=$explicitCategory;
    $resolvedCategory=$result['category_slug']??null;
    $before=count($result['requirements']??[]);
    $result['requirements']=CategoryGuard::filterRequirementsToCategory($result['requirements']??[],$resolvedCategory,$capabilityCategoryMap);
    $removed=$before-count($result['requirements']);
    if($explicitCategory && $modelCategory && $modelCategory!==$explicitCategory){
      $name=$explicitCategory==='crm'?'CRM':str_replace('-',' ',$explicitCategory);
      $result['assistant_message']='I’ll keep this consultation focused on '.$name.'. I removed unrelated category assumptions and will evaluate products only within that category. '.($result['assistant_message']??'');
    } elseif($removed>0){
      $result['assistant_message']='I removed requirements that belong to a different software category so the evaluation stays consistent. '.($result['assistant_message']??'');
    }
    if($resolvedCategory && empty(array_filter($result['requirements'],fn($r)=>!empty($r['capability_slug'])))){
      $q='Which capabilities in this software category are must-have for you?';
      if(!in_array($q,$result['follow_up_questions']??[],true))$result['follow_up_questions'][]=$q;
    }
    return $result;
  }
}
