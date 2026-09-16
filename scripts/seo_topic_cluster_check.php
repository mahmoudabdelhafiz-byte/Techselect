<?php

$root=dirname(__DIR__);
$errors=[];
$required=[
    'app/lib/SeoTopicCluster.php'=>['BestCategorySeo::page','RegionalCategorySeo::linksForCategory'],
    'alternatives_page.php'=>['SeoTopicCluster::categoryLinks','Continue'],
    'best_category_page.php'=>['SeoTopicCluster::categoryLinks','Browse the full category'],
    'regional_category_page.php'=>['SeoTopicCluster::categoryLinks','Browse the category'],
];
foreach($required as $file=>$needles){
    $path=$root.'/'.$file;
    if(!is_file($path)){$errors[]="missing $file";continue;}
    $body=(string)file_get_contents($path);
    foreach($needles as $needle)if(strpos($body,$needle)===false)$errors[]="$file missing $needle";
}
$helper=(string)@file_get_contents($root.'/app/lib/SeoTopicCluster.php');
foreach(['fit_score','recommendation_score','rank_bonus','sponsorship'] as $forbidden){
    if(stripos($helper,$forbidden)!==false)$errors[]="SEO topic cluster helper must not contain scoring/ranking token: $forbidden";
}
if($errors){fwrite(STDERR,"SEO topic cluster check failed:\n- ".implode("\n- ",$errors)."\n");exit(1);}
echo "SEO topic cluster check passed.\n";
