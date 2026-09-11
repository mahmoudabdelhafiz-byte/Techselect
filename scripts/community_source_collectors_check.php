<?php
$root=dirname(__DIR__);$need=[
 'db/mysql/054_community_source_collectors.sql'=>['public_review_connectors','public_review_collection_runs','public_review_collected_items','analysis_text','purge_after'],
 'app/lib/CommunitySourceCollectors.php'=>['stackexchange_api','rss_atom','policy_status','connector_policy_not_permitted','ProductMentionResolver::matches','CURLOPT_FOLLOWLOCATION=>false','LIBXML_NONET','PublicReviewAdminService::analyzeProduct','DATE_ADD(NOW(),INTERVAL 7 DAY)'],
 'app/lib/ProductMentionResolver.php'=>['product_aliases','matches'],
 'api/community_source_collectors.php'=>['Security::requireRole','Security::requireCsrf','COMMUNITY_CONNECTOR_POLICY','COMMUNITY_CONNECTOR_RUN'],
 'community_source_collectors.php'=>['Community Source Collectors','pending connector','/api/community-collectors'],
 'scripts/community_collectors_cron.php'=>['PHP_SAPI','TECHSELECT_COMMUNITY_AUTO_ANALYZE','CommunitySourceCollectors::due'],
 'docs/community_source_collectors.md'=>['G2 and Capterra','Reddit collector is intentionally not included','Collection never publishes Community Intelligence automatically'],
 '.htaccess'=>['community-collectors','api/community-collectors'],
 'admin_shell_page.php'=>['community_source_collectors.php']
];$errors=[];foreach($need as $file=>$terms){$path=$root.'/'.$file;if(!is_file($path)){$errors[]="missing:$file";continue;}$txt=file_get_contents($path);foreach($terms as $term)if(strpos($txt,$term)===false)$errors[]="$file missing $term";}
$collector=file_get_contents($root.'/app/lib/CommunitySourceCollectors.php');if(strpos($collector,"'g2'")!==false||strpos($collector,"'capterra'")!==false||strpos($collector,"'reddit_api'")!==false)$errors[]='restricted collector unexpectedly enabled';
if($errors){fwrite(STDERR,implode(PHP_EOL,$errors).PHP_EOL);exit(1);}echo "community_source_collectors_check: OK\n";
