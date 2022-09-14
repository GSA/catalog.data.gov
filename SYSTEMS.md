# Systems maintained by Data.gov

## Cloud.gov Apps

| App Name                              | Cloud.gov space                                  | Application/Service
|---------------------------------------|--------------------------------------------------|----------------------
| catalog-admin                         | development, staging, prod                       | catalog.data.gov
| catalog-proxy                         | development, staging, prod                       | catalog.data.gov
| catalog-fetch                         | development, staging, prod                       | catalog.data.gov
| catalog-gather                        | development, staging, prod                       | catalog.data.gov
| catalog-web                           | development, staging, prod                       | catalog.data.gov
| proxy-gsa-datagov-prod-catalog        | prod-egress                                      | Egress Proxy (catalog.data.gov)
| proxy-gsa-datagov-staging-catalog     | staging-egress                                   | Egress Proxy (catalog.data.gov)
| proxy-gsa-datagov-development-catalog | development-egress                               | Egress Proxy (catalog.data.gov)

## Cloud.gov services

| Service Name              | Cloud.gov space                                  | Application/Service
|---------------------------|--------------------------------------------------|----------------------
| sysadmin-users            | development, staging, prod                       | catalog.data.gov, inventory.data.gov
| catalog-db                | development, staging, prod                       | catalog.data.gov
| catalog-redis             | development, staging, prod                       | catalog.data.gov
| catalog-secrets           | development, staging, prod                       | catalog.data.gov
| catalog-smtp              | development, staging, prod                       | catalog.data.gov
| catalog-solr              | development, staging, prod                       | catalog.data.gov

## Cloud.gov routes

Routes can be found in the related vars.[[`development`](https://github.com/GSA/catalog.data.gov/blob/main/vars.development.yml)/[`staging`](https://github.com/GSA/catalog.data.gov/blob/main/vars.staging.yml)/[`production`](https://github.com/GSA/catalog.data.gov/blob/main/vars.production.yml)].yml files.

- The general flow for incoming traffic is:
  - Internet -> `catalog-proxy` -> [`catalog-web`|`catalog-admin`]
- The general flow for outgoing traffic is:
  - [`catalog-web`|`catalog-admin`] -> `proxy-gsa-datagov-prod-catalog` -> Internet
