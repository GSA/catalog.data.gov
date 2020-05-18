# Harvest source import


```
python import.py \
    --origin_url=https://catalog.data.gov \
    ----destination_url=http://ckan:5000 \
    --destination_api_key=xxxxx-xxxxx-xxxx-xxxxxx \
    --source_type=csw \
    --destination_owner_org=my_owner_name_or_id
```

CSW example
```
remote_ckan.lib - 7 (7) harvest sources found
remote_ckan.lib -   [csw] Harvest source: Alaska LCC CSW Server [active]
remote_ckan.lib - Creating source URL Alaska LCC CSW Server
remote_ckan.lib - Harvest source created OK Alaska LCC CSW Server
remote_ckan.lib -   [csw] Harvest source: NC OneMap CSW [active]
remote_ckan.lib - Creating source URL NC OneMap CSW
remote_ckan.lib - Harvest source created OK NC OneMap CSW
remote_ckan.lib -   [csw] Harvest source: USACE Geospatial CSW [active]
remote_ckan.lib - Creating source URL USACE Geospatial CSW
remote_ckan.lib - Harvest source created OK USACE Geospatial CSW
remote_ckan.lib -   [csw] Harvest source: 2017_arealm [active]
remote_ckan.lib - Creating source URL 2017_arealm
remote_ckan.lib - Harvest source created OK 2017_arealm
remote_ckan.lib -   [csw] Harvest source: GeoNode State CSW [active]
remote_ckan.lib - Creating source URL GeoNode State CSW
remote_ckan.lib - Harvest source created OK GeoNode State CSW
remote_ckan.lib -   [csw] Harvest source: OpenTopography CSW [active]
remote_ckan.lib - Creating source URL OpenTopography CSW
remote_ckan.lib - Harvest source created OK OpenTopography CSW
remote_ckan.lib -   [csw] Harvest source: Restore-the-gulf [active]
remote_ckan.lib - Creating source URL Restore-the-gulf
remote_ckan.lib - Harvest source created OK Restore-the-gulf
Finished: 7 harvest sources. 7 Added, 0 already exists, 0 failed

```
