<?php
$root=dirname(__DIR__);
$file=$root.'/db/mysql/031_authority_target_seeds.sql';
$sql=@file_get_contents($file)?:'';
$failed=[];
foreach(['Product Hunt','Crunchbase','F6S','StartupBlink','MAGNiTT','LinkedIn Company Page','G2','Capterra','AlternativeTo','SaaSHub','Wamda','Entrepreneur Middle East'] as $name){if(strpos($sql,$name)===false)$failed[]="Missing vetted target: $name";}
foreach(["'researching'","'not_published'",'published_url','first_verified_at','@authority_seed_actor IS NOT NULL'] as $needle){if(strpos($sql,$needle)===false)$failed[]="Missing seed safety invariant: $needle";}
foreach(["'active'","'published',s.next_action",'NOW()','first_verified_at,NOW'] as $forbidden){if(strpos($sql,$forbidden)!==false)$failed[]="Seed migration must not claim acquired authority: $forbidden";}
if(strpos($sql,"published_url,link_type,backlink_status,first_verified_at,last_checked_at")===false)$failed[]='Seed fields must explicitly include publication/backlink state';
if(strpos($sql,"0,0,NULL,NULL,'not_published',NULL,NULL")===false)$failed[]='All seed rows must remain unapproved and unpublished';
if($failed){fwrite(STDERR,"Authority target seed checks failed:\n- ".implode("\n- ",$failed)."\n");exit(1);}echo "Authority target seed checks passed.\n";
