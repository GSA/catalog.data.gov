# Harvest source import

## Read harvest souorces

Read harvest sources list for a specific type.

CSW example
```
$ python import.py --source_type=csw
remote_ckan.lib - New remote CKAN https://catalog.data.gov
remote_ckan.lib - List harvest sources 0-10
remote_ckan.lib - request https://catalog.data.gov/api/3/action/package_search {'start': 0, 'rows': 10, 'q': '(type:harvest source_type:csw)'}
remote_ckan.lib - 7 (7) harvest sources found
remote_ckan.lib -   [csw] Harvest source: Alaska LCC CSW Server
remote_ckan.lib -   [csw] Harvest source: NC OneMap CSW
remote_ckan.lib -   [csw] Harvest source: USACE Geospatial CSW
remote_ckan.lib -   [csw] Harvest source: 2017_arealm
remote_ckan.lib -   [csw] Harvest source: GeoNode State CSW
remote_ckan.lib -   [csw] Harvest source: OpenTopography CSW
remote_ckan.lib -   [csw] Harvest source: Restore-the-gulf
Finished: 7 harvest sources
```

single-doc example
```
$ python import.py --source_type=single-doc
remote_ckan.lib - New remote CKAN https://catalog.data.gov
remote_ckan.lib - List harvest sources 0-10
remote_ckan.lib - request https://catalog.data.gov/api/3/action/package_search {'start': 0, 'rows': 10, 'q': '(type:harvest source_type:single-doc)'}
remote_ckan.lib - 10 (16) harvest sources found
remote_ckan.lib -   [single-doc] Harvest source: Census TIGER 2012 Counties
remote_ckan.lib -   [single-doc] Harvest source: Aid Dashboard
remote_ckan.lib -   [single-doc] Harvest source: Building the Climate Security Vulnerability Model
remote_ckan.lib -   [single-doc] Harvest source: NGDA NAIP HVS
remote_ckan.lib -   [single-doc] Harvest source: identifier test for csdgm
remote_ckan.lib -   [single-doc] Harvest source: Total Rainfall USAF 557th WW
remote_ckan.lib -   [single-doc] Harvest source: GDELT Dataset
remote_ckan.lib -   [single-doc] Harvest source: AidData Malawi Geocoded and Climate Aid Dataset
remote_ckan.lib -   [single-doc] Harvest source: 2017Cart_aiannhkml
remote_ckan.lib -   [single-doc] Harvest source: Park facilities
remote_ckan.lib - List harvest sources 10-10
remote_ckan.lib - request https://catalog.data.gov/api/3/action/package_search {'start': 10, 'rows': 10, 'q': '(type:harvest source_type:single-doc)'}
remote_ckan.lib - 6 (16) harvest sources found
remote_ckan.lib -   [single-doc] Harvest source: tstusaf
remote_ckan.lib -   [single-doc] Harvest source: ISO 19115 2003
remote_ckan.lib -   [single-doc] Harvest source: NFHL Harvest Source
remote_ckan.lib -   [single-doc] Harvest source: Aid Dashboard User Guide
remote_ckan.lib -   [single-doc] Harvest source: Test Harvest Source
remote_ckan.lib -   [single-doc] Harvest source: Coa Parks
Finished: 16 harvest sources
```