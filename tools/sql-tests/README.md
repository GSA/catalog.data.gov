# SQL queries tests for catalog-next

This script is to check times for SQL queries in catalog-next

```
python sql-test.py \
    --db_host db.com \
    --db_name DBNAME \
    --user USER \
    --password PASS
```

Results

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