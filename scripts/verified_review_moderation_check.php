<?php
$files=[
  __DIR__.'/../app/lib/VerifiedReviewModeration.php'=>[
    "public const STATUSES=['pending','approved','rejected','needs_more_verification']",
    'recalculate(PDO $pdo,int $productId)',
    'business_domain_verified',
    'proof_of_use_verified',
    'admin_verified'
  ],
  __DIR__.'/../api/review_admin.php'=>[
    '/api/review-admin/reviews',
    'REVIEW_MODERATION',
    'REVIEW_VERIFICATION_UPDATE',
    'REVIEW_RISK_FLAG_ADD'
  ],
  __DIR__.'/../review_moderation.php'=>[
    'Verified Review Moderation',
    'needs_more_verification',
    'Mark verified',
    'Add flag'
  ],
  __DIR__.'/../.htaccess'=>[
    'review-moderation/?$ review_moderation.php',
    'api/review-admin(?:/.*)?$ api/review_admin.php'
  ]
];
$failed=[];foreach($files as $file=>$needles){if(!is_file($file)){$failed[]='missing '.basename($file);continue;}$src=file_get_contents($file);foreach($needles as $n)if(strpos($src,$n)===false)$failed[]=basename($file).' missing '.$n;}
if($failed){fwrite(STDERR,"Verified review moderation check failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "Verified review moderation check passed.\n";
