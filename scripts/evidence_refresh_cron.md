# Evidence refresh cron

Run the evidence refresh scheduler from CLI only. The default policy checks sources that have not had an attempted refresh in the last 168 hours (7 days), up to 25 sources per run.

Example shared-hosting cron command:

```bash
/usr/local/bin/php /home/USERNAME/public_html/scripts/evidence_refresh_cron.php >> /home/USERNAME/logs/evidence-refresh.log 2>&1
```

Recommended cron cadence: once per day. The scheduler itself enforces the 7-day due interval, so running the cron daily distributes work while avoiding repeated requests.

Optional environment overrides:

```bash
TECHSELECT_EVIDENCE_REFRESH_HOURS=168 TECHSELECT_EVIDENCE_REFRESH_LIMIT=25 /usr/local/bin/php /path/to/scripts/evidence_refresh_cron.php
```

Or CLI overrides:

```bash
php scripts/evidence_refresh_cron.php --hours=168 --limit=25
```

Limits: interval 1–8760 hours; batch size 1–100.

The runner uses a MariaDB advisory lock to prevent overlapping runs. Source-level failures are recorded by the existing evidence refresh checker and do not abort the remaining batch. Failed attempts are also included in the due-time calculation so broken URLs are not retried on every cron invocation.

Scheduled checks only detect source-content changes and may create `pending_review` candidates. They do not run AI fact extraction, approve proposals, apply canonical facts, or change recommendation scores. Human review remains mandatory.
