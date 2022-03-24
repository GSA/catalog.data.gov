import pysolr


solr = pysolr.Solr("http://solr:SolrRocks@localhost:8983/solr/ckan",  timeout=60)


# for i in range(1300000):
package_example = [
    {'id': 1,  'name': 'document 1', 'text': u'Paul Verlaine', "index_id": 1, "site_id": 0}
]

for i in range(1300000):
    package_test = package_example
    package_test[0]["index_id"] = i
    package_test[0]["id"] = i
    solr.add(docs=package_test, commit=False)
    if i % 100 == 0:
        print("Index Completed: %d / 1300000" % i)

    if i % 1000 == 0:
        solr.add(docs=package_test, commit=True)
