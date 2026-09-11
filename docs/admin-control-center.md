# TechSelectAI Admin Control Center

The admin control center provides one responsive navigation shell around existing operational tools. It does not weaken or replace server-side role checks in specialist pages/APIs.

## Navigation

Overview, Software, Evidence, AI Evaluations, Community Intelligence, User Reviews, Taxonomy, SEO & Indexing, AI Visibility, Buyer Analytics, Authority & Backlinks, Users & Roles, Audit Log, and System Health.

Users & Roles and the searchable Audit Log remain intentionally reserved for issue #190; the navigation points to explanatory sections rather than broken routes until those dedicated controls exist.

## Overview queues

The overview surfaces product state and actionable queues for stale product review, evidence attention, PRI policy, review moderation, missing/stale evaluations, indexing alerts, SEO quality failures, community-intelligence review, vendor claims, and partner claims. Queries are defensive: if an optional module/table has not been migrated yet the metric renders unavailable rather than breaking the whole dashboard.

## Shared shell

`admin_shell_page.php` wraps existing specialist server-rendered pages and `AdminShell` injects the responsive sidebar. Existing specialist renderer and API behavior remains intact. Role-specific navigation visibility is convenience only; authorization continues to be enforced by the underlying server-side page/API.

## Mobile

Below 900px the sidebar becomes an off-canvas menu with a fixed Admin button. Specialist page content remains otherwise unchanged.
