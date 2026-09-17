<?php
$root=dirname(__DIR__);
$main=@file_get_contents($root.'/frontend/src/main.jsx');
$nav=@file_get_contents($root.'/frontend/src/accountNav.js');
$follows=@file_get_contents($root.'/my_followed_products.php');
$productFollows=@file_get_contents($root.'/app/lib/ProductFollows.php');
$brand=@file_get_contents($root.'/brand_page.php');
$ht=@file_get_contents($root.'/.htaccess');
$errors=[];
foreach([
  [$main,"import'./accountNav.js'",'main entry loads account navigation'],
  [$nav,'/api/auth/csrf','account state is loaded from auth API'],
  [$nav,'/my-consultations','saved consultations link exists'],
  [$nav,'/my-followed-products','followed products link exists'],
  [$nav,'/my-reviews','review history link exists'],
  [$nav,'/login','login link exists'],
  [$nav,'/register','registration link exists'],
  [$nav,'/api/auth/logout','logout endpoint exists'],
  [$nav,"'X-CSRF-Token'",'logout uses CSRF token'],
  [$follows,'My Followed Products','followed products page exists'],
  [$follows,"method:'PATCH'",'community notification preference is editable'],
  [$follows,"method:'DELETE'",'account page can unfollow'],
  [$follows,'do not affect TechSelectAI Fit Score','follow signals remain ranking-neutral'],
  [$productFollows,'listForUser','followed products query is centralized'],
  [$brand,'my_followed_products.php','brand wrapper routes followed products page'],
  [$ht,'my-followed-products','web route exists'],
] as [$hay,$needle,$label]) if($hay===false||strpos($hay,$needle)===false)$errors[]=$label;
if($errors){fwrite(STDERR,"Account navigation check failed:\n- ".implode("\n- ",$errors)."\n");exit(1);}echo "Account navigation check passed.\n";
