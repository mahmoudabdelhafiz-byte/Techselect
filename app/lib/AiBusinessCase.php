<?php
final class AiBusinessCase {
  public static function generate(array $config,array $case): array {
    $facts=is_array($case['verified_facts']??null)?$case['verified_facts']:[];
    $assumptions=is_array($case['assumptions']??null)?$case['assumptions']:[];
    if(empty($config['openai_api_key'])) throw new RuntimeException('AI generation is not configured on this server');

    $section=['type'=>'object','additionalProperties'=>false,'properties'=>[
      'title'=>['type'=>'string'],'content'=>['type'=>'string']
    ],'required'=>['title','content']];
    $schema=['type'=>'object','additionalProperties'=>false,'properties'=>[
      'executive_summary'=>$section,
      'current_situation'=>$section,
      'objectives'=>$section,
      'why_this_product'=>$section,
      'requirement_fit'=>$section,
      'expected_benefits'=>$section,
      'financial_roi_assumptions'=>$section,
      'implementation_approach'=>$section,
      'risks_mitigations'=>$section,
      'alternatives_considered'=>$section,
      'recommendation'=>$section,
      'next_steps'=>$section,
      'verified_facts_used'=>['type'=>'array','items'=>['type'=>'string']],
      'assumptions_used'=>['type'=>'array','items'=>['type'=>'string']],
      'caveats'=>['type'=>'array','items'=>['type'=>'string']]
    ],'required'=>['executive_summary','current_situation','objectives','why_this_product','requirement_fit','expected_benefits','financial_roi_assumptions','implementation_approach','risks_mitigations','alternatives_considered','recommendation','next_steps','verified_facts_used','assumptions_used','caveats']];

    $instructions='You are TechSelectAI Business Case Builder. Produce a concise, management-ready business case for the specified product. Treat VERIFIED_FACTS as the only authoritative product facts supplied by TechSelectAI. Treat USER_ASSUMPTIONS as user-provided assumptions, not verified vendor facts. Never invent vendor pricing, capabilities, compliance, implementation timelines, savings, ROI, integrations, certifications, customer outcomes or market claims. If a requested fact is absent from VERIFIED_FACTS, state that it requires confirmation rather than guessing. Financial benefits and ROI may be discussed only when the user supplied assumptions support them; label them clearly as estimates based on user assumptions. Keep TechSelectAI recommendation scoring separate from this document. Do not imply sponsorship or ownership affects fit. Write neutral professional prose suitable for management, procurement, finance and IT stakeholders.';
    $input="VERIFIED_FACTS:\n".json_encode($facts,JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES)."\n\nUSER_ASSUMPTIONS:\n".json_encode($assumptions,JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES)."\n\nBUSINESS_CASE_TITLE:\n".($case['title']??'Business Case');
    $payload=['model'=>$config['openai_model']?:'gpt-5','instructions'=>$instructions,'input'=>$input,'text'=>['format'=>['type'=>'json_schema','name'=>'techselect_business_case','strict'=>true,'schema'=>$schema]]];
    $ch=curl_init('https://api.openai.com/v1/responses');
    curl_setopt_array($ch,[CURLOPT_POST=>true,CURLOPT_RETURNTRANSFER=>true,CURLOPT_TIMEOUT=>45,CURLOPT_HTTPHEADER=>['Authorization: Bearer '.$config['openai_api_key'],'Content-Type: application/json'],CURLOPT_POSTFIELDS=>json_encode($payload,JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES)]);
    $raw=curl_exec($ch);$status=(int)curl_getinfo($ch,CURLINFO_RESPONSE_CODE);$err=curl_error($ch);curl_close($ch);
    if($raw===false||$status<200||$status>=300) throw new RuntimeException('AI business case generation failed'.($err?': '.$err:''));
    $data=json_decode($raw,true);$text=$data['output_text']??null;
    if(!$text&&!empty($data['output'])) foreach($data['output'] as $item) foreach(($item['content']??[]) as $content) if(($content['type']??'')==='output_text'){$text=$content['text']??null;break 2;}
    if(!$text) throw new RuntimeException('AI response did not contain structured output');
    $result=json_decode($text,true);if(!is_array($result)) throw new RuntimeException('AI response was not valid JSON');
    return $result;
  }
}
