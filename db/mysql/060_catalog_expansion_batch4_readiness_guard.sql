-- Batch 4 publication-readiness guard.
-- 059 seeds the research catalog using the same historical import pattern as earlier batches.
-- Current TechSelectAI governance requires evidence/pricing/deployment/integration/community/evaluation
-- readiness before public activation, so these newly seeded products remain drafts until reviewed.
SET NAMES utf8mb4;
START TRANSACTION;

UPDATE products
SET status='draft'
WHERE slug IN (
  'microsoft-sentinel','splunk-enterprise-security','ibm-qradar-siem','elastic-security',
  'microsoft-entra-id','okta-workforce-identity','pingone-for-workforce','jumpcloud-identity-platform',
  'cyberark-privilege-cloud','beyondtrust-password-safe','delinea-secret-server','manageengine-pam360',
  'sap-extended-warehouse-management','oracle-fusion-cloud-warehouse-management','manhattan-active-warehouse-management','blue-yonder-warehouse-management',
  'microsoft-power-apps','mendix-platform','outsystems-platform','appian-platform'
);

COMMIT;
