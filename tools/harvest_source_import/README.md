# Harvest source scripts

## Create a report on harvest sources

list_harvest_sources

```
python list_harvest_sources.py --source_type=datajson
remote_ckan.lib - 99 (151) harvest sources found
remote_ckan.lib -   [datajson] Harvest source: U.S. Forest Service Geospatial Data Discovery [active]
remote_ckan.lib - Get harvest source data https://catalog.data.gov/api/3/action/harvest_source_show {'id': 'u-s-forest-service-geospatial-data-discovery'}
remote_ckan.lib - Error [500] trying to get full harvest source info about "U.S. Forest Service Geospatial Data Discovery" (u-s-forest-service-geospatial-data-discovery)
remote_ckan.lib -   [datajson] Harvest source: City of Boise Data.json [active]
remote_ckan.lib - Get harvest source data https://catalog.data.gov/api/3/action/harvest_source_show {'id': 'city-of-boise-data-json'}

...

Finished: 150 harvest sources with 2 error(s)
*******
WITH ERRORS
*******
  - Error [500] trying to get full harvest source info about "U.S. Forest Service Geospatial Data Discovery" (u-s-forest-service-geospatial-data-discovery)
	- Error [500] trying to get full harvest source info about "honolulu json" (honolulu-json)
```

### Import harvest sources

Scripts to read and import harvest sources from a CKAN instance and add it to another CKAN instance.

These scripts require Python >= 3.6.

## Import Harvest Sources

Get help with import_harvest_sources.py parameters

```
$ python import_harvest_sources.py -h
```

Response:

```
usage: import_harvest_sources.py [-h] [--origin_url ORIGIN_URL]
                                 [--source_type SOURCE_TYPE]
                                 [--user_agent USER_AGENT]
                                 [--destination_url DESTINATION_URL]
                                 [--destination_api_key DESTINATION_API_KEY]
                                 [--limit LIMIT]

optional arguments:
  -h, --help            show this help message and exit
  --origin_url ORIGIN_URL
                        CKAN instance URL
  --source_type SOURCE_TYPE
                        Type of harvest source: ALL|datajson|csw|waf etc
  --user_agent USER_AGENT
                        User agent
  --destination_url DESTINATION_URL
                        CKAN destination instance URL
  --destination_api_key DESTINATION_API_KEY
                        CKAN destination instance API KEY
  --limit LIMIT         Limit the amount of Harvest sources to import
```

Run a CSW harvest source:

```
$ python import_harvest_sources.py \
    --origin_url=https://catalog.data.gov \
    --destination_url=http://ckan:5000 \
    --destination_api_key=xxxxx-xxxxx-xxxx-xxxxxx \
    --source_type=csw \
    --limit=10
```


Response:

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

### Test

We use _pytest cassettes_ to save responses from orgin and destination CKAN instances.

#### Record results

We can run tests against real CKAN instances to save each request response (GET and POST)


```
$ python -m pytest --vcr-record=all tests/
```
#### Run tests against saved requests

Run test with fake requests based on previous results

```
$ python -m pytest --vcr-record=none
```

