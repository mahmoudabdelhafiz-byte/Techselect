<?php

declare(strict_types=1);

$root=dirname(__DIR__);
$checks=[
  'frontend/src/homepageValue.js'=>[
    'Specialized software intelligence & technology advisory',
    'industry-specific and operational software decisions',
    'not a mass-market list of popular tools',
    'capability models built around how those systems are actually selected'
  ],
  'frontend/index.html'=>[
    'Specialized Software Intelligence & Technology Advisory',
    'specialized software intelligence and technology advisory platform',
    'industry-specific and operational software',
    'instead of mass-market directory rankings'
  ],
  'about_techselectai.php'=>[
    'specialized software intelligence and technology advisory platform',
    'industry-specific, operational and technically complex software categories',
    'specialized software directory and decision-intelligence platform',
    'not listing the largest number of products',
    'generic popularity or review-volume lists'
  ],
  'methodology.php'=>[
    'Specialized recommendation methodology',
    'domain-specific capability models for specialized software categories',
    'rather than popularity or listing volume',
    'Why specialization matters',
    'forcing specialized products into a generic checklist'
  ],
  'trust.php'=>[
    'specialized software decisions where generic directory rankings are not enough',
    'Specialized, not a mass-market directory',
    'Catalog breadth is not treated as the goal',
    'popularity or review volume'
  ],
  'llms.txt'=>[
    'specialized software intelligence and technology advisory platform',
    'not designed as a mass-market directory',
    'domain-specific requirements',
    'category-specific capability models',
    'industrial operations',
    'maritime and terminal systems'
  ]
];

$failed=[];
foreach($checks as $file=>$needles){
    $text=@file_get_contents($root.'/'.$file)?:'';
    foreach($needles as $needle){
        if(stripos($text,$needle)===false)$failed[]="$file missing specialized-positioning phrase: $needle";
    }
}

$homepage=@file_get_contents($root.'/frontend/src/homepageValue.js')?:'';
$about=@file_get_contents($root.'/about_techselectai.php')?:'';
$trust=@file_get_contents($root.'/trust.php')?:'';
$combined=$homepage."\n".$about."\n".$trust;
foreach([
    'largest software directory',
    'most comprehensive software directory',
    'all software products',
    'number one software directory',
    'ranking based on popularity',
    'most popular software wins'
] as $forbidden){
    if(stripos($combined,$forbidden)!==false)$failed[]="Generic-directory positioning reintroduced: $forbidden";
}

if($failed){
    fwrite(STDERR,"Specialized directory positioning check failed:\n- ".implode("\n- ",$failed)."\n");
    exit(1);
}

echo "Specialized directory positioning check passed: public copy consistently describes TechSelectAI as evidence-backed specialized software intelligence rather than a mass-market directory.\n";
