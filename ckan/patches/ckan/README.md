# About this patches

## unflatter-indexerror:

Related to issue [#75](https://github.com/GSA/catalog.data.gov/issues/75):

[This commit](https://github.com/GSA/ckan/commit/f92fd41197d75028e470ba860d6698f10368cdb4), 5 years ago skip the `extras` in harvest packages.
This is not part of CKAN 2.8 upstream version

```
if data.get(('type',)) == 'harvest':
    data.pop(('extras',), None)
```

[10 days ago](https://github.com/ckan/ckan/commit/1e573fce60e2ae7169fa9811c2e080ab7e02a883) this function was improved. This PR maybe fix this error. This is part of [a PR](https://github.com/ckan/ckan/pull/5444) which is marked to _backport_ in next days.
Possible solution: add a patch and update to CKAN 2.8.5 when becoming available.

### Test

We create a `waf-collection` source:
 - URL: https://meta.geo.census.gov/data/existing/decennial/GEO/GPMB/TIGERline/TIGER2018/concity/
 - type: WAF homegeneous collection
 - validator: ISO 19115
 - Collection Metadata Url: https://meta.geo.census.gov/data/existing/decennial/GEO/GPMB/TIGERline/TIGER2018/SeriesInfo/SeriesCollection_tl_2018_concity.shp.iso.xml

Save it's workings (seems fixed) but if I try to edit this source the `Collection Metadata Url` field is missing.