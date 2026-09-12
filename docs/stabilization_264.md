# P0 stabilization / production reconciliation (#264)

This note records the operational fixes introduced after production exposed partially applied migrations and unaligned account email.

## Migration 019 — buyer intent analytics

Older `019_buyer_intent_analytics.sql` could fail with InnoDB errno 121 when a foreign key named `fk_consultation_industry` already existed. The stabilized migration now checks the actual `consultations.industry_id -> industries.id` relationship through `information_schema` and adds the FK only when missing.

For a partially applied production database, inspect before retrying:

```sql
SELECT CONSTRAINT_NAME, TABLE_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE CONSTRAINT_SCHEMA = DATABASE()
  AND TABLE_NAME = 'consultations'
  AND COLUMN_NAME = 'industry_id'
  AND REFERENCED_TABLE_NAME IS NOT NULL;
```

If that relationship already points to `industries(id)`, do not add another FK. The stabilized migration can be re-run to reconcile missing columns/indexes and will skip the existing relationship.

## Migration 036 — RFP documents

The old migration referenced a nonexistent `project_matrix_runs` table. The real matrix table created by migration 035 is `selection_project_matrix_runs`.

Before rerunning on production:

```sql
SHOW TABLES LIKE 'rfp_documents';
```

If no table is returned, run the corrected `036_rfp_documents.sql` after migration 035.

If `rfp_documents` already exists, inspect the matrix FK first:

```sql
SELECT CONSTRAINT_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE CONSTRAINT_SCHEMA = DATABASE()
  AND TABLE_NAME = 'rfp_documents'
  AND COLUMN_NAME = 'matrix_run_id'
  AND REFERENCED_TABLE_NAME IS NOT NULL;
```

Only if no valid relationship exists, add it manually:

```sql
ALTER TABLE rfp_documents
  ADD CONSTRAINT fk_ts_rfp_matrix_run_036
  FOREIGN KEY (matrix_run_id)
  REFERENCES selection_project_matrix_runs(id)
  ON DELETE SET NULL;
```

Do not add a second FK when an equivalent valid relationship already exists under another name.

## Account email authentication/alignment

TechSelectAI account email now uses one configured domain-aligned identity for both the visible `From` address and the SMTP envelope sender (`Return-Path`/MAIL FROM path when supported by the hosting MTA).

Recommended production values:

- `mail_from`: an existing mailbox or sender such as `no-reply@techselectai.com`
- `mail_return_path`: normally the same `@techselectai.com` address
- `mail_sender_name`: `TechSelectAI`

The PHP application cannot create SPF/DKIM/DMARC authentication by itself. On cPanel/Exim hosting, verify **Email Deliverability** for `techselectai.com` and ensure DNS/MTA authentication is valid.

After deployment, send a new verification email and use the receiving mailbox's **Show original** / message-source view. Target result:

- SPF: PASS
- DKIM: PASS
- DMARC: PASS
- visible From domain: `techselectai.com`
- Return-Path/envelope domain: aligned with `techselectai.com`

A mailbox may continue to show “Unverified” if DNS/MTA signing is not configured even when application headers are correct.

## Security-control audit

Run:

```bash
php scripts/security_control_audit.php
php scripts/migration_integrity_check.php
```

The security audit checks mutation-capable API files for the shared same-origin, CSRF and rate-limit controls. Anonymous/token-based routes must be explicitly documented as exceptions in the audit script rather than silently bypassed.
