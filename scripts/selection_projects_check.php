<?php
$root=dirname(__DIR__);$checks=[];
function c($name,$ok){global $checks;$checks[]=['check'=>$name,'ok'=>(bool)$ok];}
$m=@file_get_contents($root.'/db/mysql/034_selection_projects.sql');
$s=@file_get_contents($root.'/app/lib/SelectionProjects.php');
$a=@file_get_contents($root.'/api/selection_projects.php');
$u=@file_get_contents($root.'/selection_projects.php');
$h=@file_get_contents($root.'/.htaccess');
$d=@file_get_contents($root.'/docs/selection_projects.md');
c('migration_has_project_table',str_contains($m,'CREATE TABLE IF NOT EXISTS selection_projects'));
c('migration_has_structured_requirements',str_contains($m,'selection_project_requirements')&&str_contains($m,'source VARCHAR(32)'));
c('migration_has_integrations',str_contains($m,'selection_project_integrations'));
c('service_preserves_provenance',str_contains($s,"'user_entered','ai_suggested','inferred'")&&str_contains($s,'user_confirmed'));
c('service_imports_consultation_context',str_contains($s,'mergeConsultation')&&str_contains($s,'importConsultationRequirements'));
c('requirements_brief_available',str_contains($s,"'requirements_brief'")&&str_contains($s,'brief('));
c('api_requires_registered_entitlement',str_contains($a,"requireFeature($pdo,$user,'selection_projects')"));
c('api_gates_ai_sources_to_pro',str_contains($a,"requireFeature($pdo,$user,'advanced_requirements_builder')"));
c('api_write_security',str_contains($a,'Security::sameOrigin')&&str_contains($a,'Security::requireCsrf')&&str_contains($a,'Security::rateLimit'));
c('workspace_is_private',str_contains($u,'noindex,nofollow')&&str_contains($u,"requireFeature($pdo,$u,'selection_projects')"));
c('routes_present',str_contains($h,'selection-projects/?$ selection_projects.php')&&str_contains($h,'api/selection-projects'));
c('downstream_reuse_documented',str_contains($d,'Downstream modules should consume this object/project ID'));
$ok=!in_array(false,array_column($checks,'ok'),true);echo json_encode(['ok'=>$ok,'checks'=>$checks],JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES).PHP_EOL;exit($ok?0:1);
