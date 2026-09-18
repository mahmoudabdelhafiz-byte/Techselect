<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$migration=(string)file_get_contents($root.'/db/mysql/102_product_community_notifications.sql');
$lib=(string)file_get_contents($root.'/app/lib/ProductFollows.php');
$page=(string)file_get_contents($root.'/my_followed_products.php');
$errors=[];

if(strpos($migration,'ADD COLUMN IF NOT EXISTS community_notifications')===false){
    $errors[]='Migration 102 must be rerunnable with ADD COLUMN IF NOT EXISTS.';
}

foreach([
    'missingCommunityNotifications',
    '0 AS community_notifications,0 AS community_notifications_available',
    'community_notifications_unavailable'
] as $needle){
    if(strpos($lib,$needle)===false)$errors[]="Missing schema-tolerance guard in ProductFollows: {$needle}";
}

if(strpos($page,'Community email preferences are temporarily unavailable.')===false){
    $errors[]='Followed-products page must degrade gracefully when community preference schema is unavailable.';
}

if($errors){
    fwrite(STDERR,"Followed-products schema tolerance check failed:\n- ".implode("\n- ",$errors)."\n");
    exit(1);
}

echo "Followed-products schema tolerance contract passed.\n";
