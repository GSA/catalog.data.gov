---
title: 📌 Tracking Update Auditing Log
labels: bug
---

Workflow with Issue: {{ workflow }}
Job Failed: {{ env.GITHUB_JOB }}
CKAN Command (in question): {{ env.COMMAND }}
CKAN Command Schedule: {{ env.SCHEDULE }}
Cloud.gov Environment: {{ env.ENVIRONMENT }}
Total Execution Time: {{ env.EXEC_TIME }}

Last Commit: {{ env.LAST_COMMIT }}
Number of times run: {{ env.GITHUB_ATTEMPTS }}
Last run by: {{ env.LAST_RUN_BY }}
Github Action Run: https://github.com/GSA/catalog.data.gov/actions/runs/{{ env.RUN_ID }}
