<?php
require_once __DIR__.'/../app/lib/Scoring.php';

$cases = [
  'all-perfect' => [[
    'functional'=>100,'mandatory'=>100,'integration'=>100,'security'=>100,
    'deployment'=>100,'commercial'=>100,'regional'=>100,'implementation'=>100,
  ],100.00],
  'functional-only' => [['functional'=>80],80.00],
  'mandatory-gap' => [[
    'functional'=>90,'mandatory'=>60,'integration'=>90,'security'=>90,
    'deployment'=>90,'commercial'=>90,'regional'=>90,'implementation'=>90,
  ],75.00],
  'legacy-budget-key' => [[
    'functional'=>90,'mandatory'=>100,'integration'=>80,'security'=>80,
    'deployment'=>100,'budget'=>70,'regional'=>90,
  ],89.59],
];

$failed = 0;
foreach ($cases as $name => [$input,$expected]) {
  $actual = Scoring::overall($input);
  $ok = abs($actual-$expected) < 0.01;
  echo ($ok?'PASS ':'FAIL ').$name.' expected='.number_format($expected,2).' actual='.number_format($actual,2)."\n";
  if (!$ok) $failed++;
}

$weights = Scoring::weights();
echo "\nApproved methodology weights:\n";
foreach ($weights as $key=>$weight) echo "- {$key}: {$weight}%\n";

echo "\nMissing dimensions are excluded and the remaining evaluated weights are normalized.\n";
echo "Legacy `budget` input is treated as the commercial-fit dimension during migration.\n";

exit($failed ? 2 : 0);
