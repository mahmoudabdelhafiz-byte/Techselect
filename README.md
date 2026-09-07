# TechSelect data architecture

This repository contains the PostgreSQL foundation for TechSelect's Phase 1
consultation and first-party analytics platform.

## Apply the schema

The migration targets PostgreSQL 15 or newer and expects an empty database:

```bash
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 \
  -f db/migrations/001_consultation_analytics.sql
```

Run the lightweight repository checks with:

```bash
./scripts/check-schema.sh
```

The model intentionally permits anonymous consultations through a visitor
session. `link_visitor_session_to_user` atomically claims that session and its
consultations, analytics events, and searches after account creation. Raw
messages and company-level data remain operational records; dashboards should
use the aggregated views at the end of the migration.

