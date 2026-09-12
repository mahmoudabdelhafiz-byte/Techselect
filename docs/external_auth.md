# Google and Microsoft sign-in

TechSelectAI supports optional Google and Microsoft authentication in addition to the existing email/password flow.

## Database

Run `db/mysql/068_external_auth_identities.sql` during deployment.

The migration creates a provider-identity mapping table. It does not remove or weaken the existing password login model.

## Google

Create a Google OAuth 2.0 Web application credential and configure this authorized redirect URI exactly:

`https://techselectai.com/api/auth/oauth/callback?provider=google`

Set these server-side environment/config values:

- `GOOGLE_OAUTH_CLIENT_ID`
- `GOOGLE_OAUTH_CLIENT_SECRET`

Requested scopes are `openid email profile`.

## Microsoft

Create an app registration in Microsoft Entra ID. For broad TechSelectAI sign-in, allow the account types you want to support and configure this Web redirect URI exactly:

`https://techselectai.com/api/auth/oauth/callback?provider=microsoft`

Set:

- `MICROSOFT_OAUTH_CLIENT_ID`
- `MICROSOFT_OAUTH_CLIENT_SECRET`
- `MICROSOFT_OAUTH_TENANT=common` for work/school and personal Microsoft accounts, or use a tenant identifier/domain to restrict authentication.

Requested scopes are `openid profile email User.Read`. The server uses Microsoft Graph `/me` to obtain the authenticated account identifier and email instead of trusting an unverified client-side token payload.

## Account behavior

- External sign-in uses OAuth authorization code flow with PKCE and one-time, session-bound `state` values.
- Google accounts require a verified provider email when Google returns the verification claim.
- A matching existing TechSelectAI account is linked by normalized verified provider email on first external sign-in.
- A pending email-registration account becomes active after a successful external-provider sign-in for the same email.
- Disabled/non-active accounts are not reactivated through external sign-in.
- New external users receive the normal `free_registered` plan.
- Password login remains available. Social-only accounts receive a random non-user-known password hash, so password authentication is unavailable unless the user later completes the password-reset flow.
- Provider identities are unique by `(provider, provider_subject)` and are not used to alter roles, entitlements, Fit Score, recommendations, or catalog ranking.

## Deployment verification

1. Run migration 068.
2. Configure provider credentials outside Git.
3. Verify PHP cURL is enabled on the hosting environment.
4. Open `/login` and confirm only configured providers appear.
5. Test Google sign-in with a new user and with an existing account using the same email.
6. Test Microsoft sign-in likewise.
7. Confirm cancelled/failed provider authentication returns safely to `/login`.
8. Confirm the active anonymous consultation is claimed after external sign-in just as it is after password login.
9. Confirm admin/reviewer users with a matching linked email return to `/admin`; normal users return to the requested safe relative `next` path.
