# Catalog expansion batch 3

Issue: #228, phase of #96.

## Categories
- AI Platforms (`ai-platforms`)
- Healthcare & EHR Systems (`healthcare-ehr`)
- Retail POS (`retail-pos`)
- CAD & Engineering (`cad-engineering`)

## Products
### AI Platforms
- Microsoft Foundry
- Google Cloud Vertex AI
- Amazon Bedrock
- IBM watsonx.ai

### Healthcare & EHR
- Epic
- Oracle Health EHR
- InterSystems TrakCare
- MEDITECH Expanse

### Retail POS
- Oracle Retail Xstore Point of Service
- Shopify POS
- Lightspeed Retail
- Square for Retail

### CAD & Engineering
- Autodesk AutoCAD
- SOLIDWORKS
- Siemens NX CAD
- PTC Creo

## Evidence policy
Initial publication uses official vendor-owned product pages only. Each product receives a small set of broad, defensible capability facts. All other category capabilities are inserted as `not_yet_verified`; they are not treated as unsupported. No pricing, compliance certification, regional availability, ranking, customer outcome, or implementation-partner claim is added by this migration.

## Sitemap behavior
No hard-coded sitemap rows are required. `sitemap.php` dynamically exposes:
- `/software/{slug}` when the active product has at least 3 capability rows and at least 1 evidence source;
- `/categories/{slug}` when the category has at least 2 qualifying active products;
- capability URLs when at least 2 active products carry the capability;
- same-category comparison URLs when both products meet the evidence/capability publication gates.

Therefore migration 039 makes the new catalog discoverable through the existing evidence-gated sitemap automatically after deployment.

## Deployment
Apply `db/mysql/039_catalog_expansion_batch3.sql` after migration 038 and deploy the updated `app/lib/CategoryGuard.php`. No frontend/Vite build is required.
