<?php
$root=dirname(__DIR__);
$main=@file_get_contents($root.'/frontend/src/main.jsx');
$search=@file_get_contents($root.'/frontend/src/softwareCatalogSearch.js');
$errors=[];
foreach([
  [$main,"./softwareCatalogSearch.js",'frontend entry loads catalog search'],
  [$search,"location.pathname.replace(/\\/$/,'')!=='/software'",'search is scoped to software catalog'],
  [$search,"fetch('/api/software'",'search reuses existing software API'],
  [$search,"Start typing a software, vendor, or category",'autocomplete prompt exists'],
  [$search,"role=\"combobox\"",'autocomplete combobox semantics exist'],
  [$search,"ArrowDown",'keyboard navigation exists'],
  [$search,"/software/",'autocomplete navigates to product profiles'],
  [$search,"card.hidden=!visible",'catalog cards are filtered while typing'],
] as [$hay,$needle,$label]) if($hay===false||strpos($hay,$needle)===false)$errors[]=$label;
if($errors){fwrite(STDERR,"Software catalog search check failed:\n- ".implode("\n- ",$errors)."\n");exit(1);}echo "Software catalog search check passed.\n";
