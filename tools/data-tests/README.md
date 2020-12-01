# Data (psql and SOLR) tests

## SOLR tests

```
python3 solr-test.py --solr_url http://solr:8983/solr/ckan --site_id default
Connecting to http://solr:8983/solr/ckan 
Search datasets
 - 4 QTime in 0.03s
 - 20 Hits
 - 20 Results
 - 1 QTime in 0.02s
 - 23 Hits
 - 21 Results
Search harvest sources
 - 1 QTime in 0.01s
 - 3 Hits
 - 3 Results
```

## SQL queries tests for catalog-next

This script is to check times for SQL queries in catalog-next

```
python3 sql-test.py \
    --db_host db.com \
    --db_name DBNAME \
    --user USER \
    --password PASS
```

## Results

### A small local instance

```
python3 sql-test.py --db_host db --db_name ckan --user ckan --password ckan
Connecting to db DB:ckan
==============================
Harvest objects: 115 (0.0 seconds)
Harvest logs: 472 (0.0 seconds)
Harvest objects extras: 460 (0.0 seconds)
Packages: 23 (0.0 seconds)
Harvest indexes (in 0.0 seconds)
RESULTS (first 10)
tablename |indexname |indexdef |
-----------------------------------------
harvest_object |harvest_source_id_idx |CREATE INDEX harvest_source_id_idx ON public.harvest_object USING btree (harvest_source_id) |
-----------------------------------------
harvest_object |harvest_job_id_idx |CREATE INDEX harvest_job_id_idx ON public.harvest_object USING btree (harvest_job_id) |
-----------------------------------------
harvest_object |package_id_idx |CREATE INDEX package_id_idx ON public.harvest_object USING btree (package_id) |
-----------------------------------------
harvest_object |guid_idx |CREATE INDEX guid_idx ON public.harvest_object USING btree (guid) |
-----------------------------------------
harvest_object |harvest_object_pkey |CREATE UNIQUE INDEX harvest_object_pkey ON public.harvest_object USING btree (id) |
-----------------------------------------
Harvest object from package f78b4d7f-600a-4c14-ba8d-7e539edf110c (1 results in 0.0 seconds)
Harvest object from package 0ee241b7-17ba-4a06-96d1-da5a78e6a050 (1 results in 0.0 seconds)
Harvest object from package 481d15cb-b7cf-4891-88f5-5799ebf0b12b (1 results in 0.0 seconds)
Harvest object from package 4afe09a9-653e-46aa-87a6-2f078d37fd49 (1 results in 0.0 seconds)
Harvest object from package 481d15cb-b7cf-4891-88f5-5799ebf0b12b (1 results in 0.0 seconds)
Slow queries
RESULTS (first 10)
pid |age |state |usename |query |
-----------------------------------------
130 |-1 day, 22:56:20.567061 |idle in transaction |ckan |SELECT "user".password AS user_password, "user".id AS user_id, "user".name AS user_name, "user".fullname AS user_fullname, "user".email AS user_email, "user".apikey AS user_apikey, "user".created AS user_created, "user".reset_key AS user_reset_key, "user".about AS user_about, "user".activity_streams_email_notifications AS user_activity_streams_email_notifications, "user".sysadmin AS user_sysadmin, "user".state AS user_state 
FROM "user" 
WHERE "user".name = 'default' OR "user".id = 'default' ORDER BY "user".name 
 LIMIT 1 |
-----------------------------------------

```

### In the sandbox environment

```
Connecting to terraform-xxxxxx DB:catalog_db_next
==============================
Harvest objects: 807733 (7.15 seconds)
Harvest logs: 0 (0.01 seconds)
Harvest objects extras: 3110860 (10.75 seconds)
Packages: 134006 (2.62 seconds)
Harvest indexes (in 0.02 seconds)
RESULTS (first 10)
tablename |indexname |indexdef |
-----------------------------------------
harvest_object |harvest_source_id_idx |CREATE INDEX harvest_source_id_idx ON public.harvest_object USING btree (harvest_source_id) |
-----------------------------------------
harvest_object |harvest_object_pkey |CREATE UNIQUE INDEX harvest_object_pkey ON public.harvest_object USING btree (id) |
-----------------------------------------
harvest_object |harvest_job_id_idx |CREATE INDEX harvest_job_id_idx ON public.harvest_object USING btree (harvest_job_id) |
-----------------------------------------
harvest_object |package_id_idx |CREATE INDEX package_id_idx ON public.harvest_object USING btree (package_id) |
-----------------------------------------
harvest_object |guid_idx |CREATE INDEX guid_idx ON public.harvest_object USING btree (guid) |
-----------------------------------------
Harvest object from package de801928-4b30-4742-a0b7-80b42deaf2d6 (6 results in 0.01 seconds)
Harvest object from package agroindustria_15fbd380-fa31-436c-9283-457c23e30ecc (2 results in 0.01 seconds)
Harvest object from package 64c9f734-c210-4f08-9170-3e9008646706 (1 results in 0.0 seconds)
Harvest object from package 7d2ea683-7fc5-4886-b3eb-e10d74251607 (3 results in 0.01 seconds)
Harvest object from package 57cf75a3-131b-4815-a8d3-ef1c210c4dc2 (2 results in 0.01 seconds)
Slow queries
RESULTS (first 10)
pid |age |state |usename |query |
-----------------------------------------
10301 |-1 day, 23:59:46.523561 |active |catalog_master |SELECT resource.id, resource.package_id, resource.url, resource.format, resource.description, resource.hash, resource.position, resource.name, resource.resource_type, resource.mimetype, resource.mimetype_inner, resource.size, resource.created, resource.last_modified, resource.cache_url, resource.cache_last_updated, resource.url_type, resource.extras, resource.state, resource.revision_id 
FROM resource 
WHERE resource.package_id = '4a4a1253-876b-4fd5-8682-3b4e695ed111' |
-----------------------------------------
10228 |-1 day, 23:58:50.038040 |idle in transaction |catalog_master |SELECT harvest_object.id AS harvest_object_id 
FROM harvest_object 
WHERE harvest_object.state = 'WAITING' |
```