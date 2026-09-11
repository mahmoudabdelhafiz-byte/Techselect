<?php
$required=['db/mysql/047_decision_packs.sql','app/lib/DecisionPack.php','api/decision_packs.php','decision_pack.php','docs/decision_pack_scope.md'];foreach($required as $f){if(!is_file(__DIR__.'/../'.$f)){fwrite(STDERR,"missing $f\n");exit(1);}}echo "ok\n";
