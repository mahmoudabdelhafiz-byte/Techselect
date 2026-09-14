<?php
$root=dirname(__DIR__);$errors=[];
$collector=file_get_contents($root.'/app/lib/CommunitySourceCollectors.php')?:'';
$google=file_get_contents($root.'/app/lib/GooglePlayReviewCollector.php')?:'';
$migration=file_get_contents($root.'/db/mysql/085_google_play_review_connector.sql')?:'';
$env=file_get_contents($root.'/.env.shared.example')?:'';

foreach(['google_play_developer_api','GooglePlayReviewCollector::collect','app_store','ProductMentionResolver::matches'] as $term)if(!str_contains($collector,$term))$errors[]="collector missing {$term}";
foreach(['androidpublisher.googleapis.com','https://www.googleapis.com/auth/androidpublisher','TECHSELECT_GOOGLE_PLAY_SERVICE_ACCOUNT_FILE','Authorization: Bearer','reviewId','starRating'] as $term)if(!str_contains($google,$term))$errors[]="Google Play collector missing {$term}";
foreach(['cardiq','com.card_iq.myapp','google_play_developer_api','app_store','androidpublisher.googleapis.com','permitted'] as $term)if(!str_contains($migration,$term))$errors[]="085 migration missing {$term}";
if(!str_contains($env,'TECHSELECT_GOOGLE_PLAY_SERVICE_ACCOUNT_FILE='))$errors[]='service-account environment setting not documented';
if(str_contains(strtolower($google),'g2.com')||str_contains(strtolower($google),'capterra.com'))$errors[]='Google Play collector must not reference excluded review aggregators';
foreach(['Scoring::','fit_score','recommendation_rank','recommendation_score'] as $term){if(str_contains($collector,$term)||str_contains($google,$term)||str_contains($migration,$term))$errors[]="Google Play review path must remain independent from scoring/ranking: {$term}";}
if(!str_contains($collector,"$isGooglePlay&&!ProductMentionResolver::matches"))$errors[]='product-mention bypass is not narrowly limited to the authorized Google Play connector';
if(!str_contains($migration,'Official authenticated Google Play Developer API'))$errors[]='085 must document authenticated official API basis';
if($errors){fwrite(STDERR,"Google Play reviews contract failed:\n- ".implode("\n- ",$errors)."\n");exit(1);}echo "Google Play reviews contract passed.\n";
