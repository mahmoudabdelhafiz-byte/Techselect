<?php
$root=dirname(__DIR__);
require_once $root.'/app/lib/AiReferralAnalytics.php';
$checks=[];
$c=AiReferralAnalytics::classify('https://chatgpt.com/c/abc?utm_source=test');
$checks['ChatGPT recognized']=is_array($c)&&($c['source_provider']??null)==='chatgpt'&&($c['referrer_host']??null)==='chatgpt.com'&&($c['referrer_path']??null)==='/c/abc';
$c=AiReferralAnalytics::classify('https://claude.ai/chat/123?x=1');
$checks['Claude recognized']=is_array($c)&&($c['source_provider']??null)==='claude'&&($c['referrer_path']??null)==='/chat/123';
$checks['normal Google not misclassified']=AiReferralAnalytics::classify('https://www.google.com/search?q=crm')===null;
$checks['normal Bing not misclassified']=AiReferralAnalytics::classify('https://www.bing.com/search?q=crm')===null;
$checks['public software path']=AiReferralAnalytics::isPublicKnowledgePath('/software/cardiq');
$checks['public capability path']=AiReferralAnalytics::isPublicKnowledgePath('/capabilities/email-signatures');
$checks['admin excluded']=!AiReferralAnalytics::isPublicKnowledgePath('/admin');
$checks['api excluded']=!AiReferralAnalytics::isPublicKnowledgePath('/api/products');
$migration=(string)@file_get_contents($root.'/db/mysql/018_ai_referral_analytics.sql');
$checks['schema avoids personal identifiers']=strpos($migration,'ip_address')===false&&strpos($migration,'user_agent')===false&&strpos($migration,'cookie')===false;
$brand=(string)@file_get_contents($root.'/brand_page.php');
$checks['tracking failure is isolated']=strpos($brand,'AiReferralAnalytics::record')!==false&&strpos($brand,'catch(Throwable $e){}')!==false;
$report=(string)@file_get_contents($root.'/ai_referrals.php');
$checks['report requires privileged role']=strpos($report,"Security::requireRole(['admin','super_admin','data_editor'])")!==false;
$docs=(string)@file_get_contents($root.'/docs/ai_discoverability_test_matrix.md');
$checks['test matrix has no citation guarantee']=strpos($docs,'does not guarantee citation')!==false;
$failed=[];foreach($checks as $label=>$ok){echo ($ok?'PASS':'FAIL').' '.$label.PHP_EOL;if(!$ok)$failed[]=$label;}
if($failed){fwrite(STDERR,"AI referral analytics checks failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "AI referral analytics checks passed.\n";
