<?php
$checks=[
 ['db/mysql/047_decision_packs.sql','decision_packs'],
 ['app/lib/DecisionPack.php','class DecisionPack'],
 ['api/decision_packs.php','decision_pack'],
 ['decision_pack.php','Software Decision Pack'],
];
foreach($checks as [$f,$needle]){if(!is_file(__DIR__.'/../'.$f)||strpos(file_get_contents(__DIR__.'/../'.$f),$needle)===false){fwrite(STDERR,"Missing contract: $f / $needle\n");exit(1);}}
echo "decision pack contract ok\n";
