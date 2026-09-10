<?php
$root=dirname(__DIR__);
$main=@file_get_contents($root.'/frontend/src/main.jsx');
$nav=@file_get_contents($root.'/frontend/src/accountNav.js');
$errors=[];
foreach([
  [$main,"import'./accountNav.js'",'main entry loads account navigation'],
  [$nav,'/api/auth/csrf','account state is loaded from auth API'],
  [$nav,'/my-consultations','saved consultations link exists'],
  [$nav,'/my-reviews','review history link exists'],
  [$nav,'/login','login link exists'],
  [$nav,'/register','registration link exists'],
  [$nav,'/api/auth/logout','logout endpoint exists'],
  [$nav,"'X-CSRF-Token'",'logout uses CSRF token'],
] as [$hay,$needle,$label]) if($hay===false||strpos($hay,$needle)===false)$errors[]=$label;
if($errors){fwrite(STDERR,"Account navigation check failed:\n- ".implode("\n- ",$errors)."\n");exit(1);}echo "Account navigation check passed.\n";
