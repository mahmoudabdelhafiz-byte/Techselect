<?php
/**
 * PR consolidation guard.
 *
 * Reads `git diff --name-status` lines from STDIN. During the consolidation
 * freeze, newly-added major product surfaces require an explicit maintainer
 * exception label. This guard does not inspect or alter scoring/ranking logic.
 */
$labels=array_filter(array_map('trim',explode(',',getenv('PR_LABELS')?:'')));
$freeze=(getenv('CONSOLIDATION_FREEZE')?:'1')!=='0';
$exception=in_array('consolidation-exception',$labels,true);
$lines=file('php://stdin',FILE_IGNORE_NEW_LINES|FILE_SKIP_EMPTY_LINES)?:[];
$candidates=[];

foreach($lines as $line){
    $parts=preg_split('/\s+/',trim($line),2);
    if(count($parts)!==2)continue;
    [$status,$path]=$parts;
    if(!str_starts_with($status,'A'))continue;

    $major=false;
    if(preg_match('#^[^/]+\.php$#',$path))$major=true; // new top-level public/admin page
    if(preg_match('#^api/[^/]+\.php$#',$path))$major=true; // new top-level API surface
    if(preg_match('#^frontend/src/(pages|routes)/.+\.(jsx?|tsx?)$#',$path))$major=true;

    // Governance/tests/docs/scripts are not product surfaces.
    if(preg_match('#^(scripts|docs|db|\.github)/#',$path))$major=false;

    if($major)$candidates[]=$path;
}

if(!$freeze){
    echo "Consolidation freeze disabled; no surface gate applied.\n";
    exit(0);
}
if(!$candidates){
    echo "Consolidation gate passed: no new major product-surface candidates detected.\n";
    exit(0);
}
if($exception){
    echo "Consolidation gate passed with explicit maintainer exception for:\n- ".implode("\n- ",$candidates)."\n";
    exit(0);
}

fwrite(STDERR,"Consolidation gate blocked this PR. New major product-surface candidates were detected:\n- ".implode("\n- ",$candidates)."\n\nWhile the freeze is active, keep work to quality/security/evidence/usability or apply the maintainer-reviewed `consolidation-exception` label with documented user-demand justification.\n");
exit(1);
