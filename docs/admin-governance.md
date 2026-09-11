# Admin Users, Roles, and Audit Governance

## Roles
- `reviewer`: evidence/evaluation/review approval workflows and product activation.
- `data_editor`: factual catalog/taxonomy editing without approval powers.
- `admin`: operational administration plus management of non-admin users/roles.
- `super_admin`: full administrative control, including admin/super-admin role management and system-level settings.

The UI is not the authorization boundary. APIs and specialist pages enforce roles server-side.

## Role-change policy
- Admin may assign `user`, `reviewer`, and `data_editor` only.
- Admin cannot change users who are already `admin` or `super_admin`.
- Only `super_admin` may assign or remove `admin` / `super_admin`.
- A super admin cannot remove their own super-admin access in the same operation.
- The last active super admin cannot be demoted or disabled.
- Every role/status change is written to `audit_logs`.

## Permission matrix
The canonical matrix lives in `AdminGovernance::PERMISSIONS` and covers product editing, evidence verification, activation, review moderation, community-intelligence approval, AI-evaluation approval, user/role management, and methodology/system settings.

## Audit Log
`/admin-audit` supports actor, action, entity type, entity ID, outcome, and date filters; before/after JSON; operational links; pagination; and CSV export.

Migration `052_admin_roles_audit.sql` adds the `outcome` field with a default of `success`, preserving all existing audit rows.
