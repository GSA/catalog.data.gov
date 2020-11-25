""" check solr times
    Usage: python3 solr-test.py --solr_url http://solr:8983/solr/ckan
"""
import argparse
import pysolr
import time


parser = argparse.ArgumentParser()
parser.add_argument("--solr_url", type=str, help="Full solr URL (with user and pass if required")
parser.add_argument("--site_id", type=str, help="CKAN site id", default='default')
args = parser.parse_args()

print(f'Connecting to {args.solr_url} ')
conn = pysolr.Solr(args.solr_url)

def run_query(query):
    start = time.time()
    res = conn.search(**query)
    end = time.time()
    final_time = round(end - start, 2) 

    ret = {
        'query': query,
        'final_time': final_time,
        'results': res
    }

    print(' - {} QTime in {}s'.format(ret['results'].qtime, ret['final_time']))
    print(' - {} Hits'.format(ret['results'].hits))
    print(' - {} Results'.format(len(ret['results'])))
    # for result in ret['results']:
    #     print(' - result: {}'.format(result))
    print(' - Facets \n\t{}'.format(ret['results'].facets))
    # print(' - {}'.format(res.raw_response['response']['numFound']))
    
    return ret

print('Search datasets')

fq = '+site_id:"{}" -dataset_type:harvest -collection_package_id:["" TO *] +state:active'.format(args.site_id)
query = {'facet.limit':50, 'q': '*:*', 
         'facet.field': ['groups', 'vocab_category_all', 'metadata_type', 'tags', 'res_format', 'organization_type', 'organization', 'publisher', 'bureauCode'], 
         'fl':'id validated_data_dict',
         'start': 0,
         'sort': 'views_recent desc',
         'fq': fq,
         'facet.mincount': 1,
         'facet': 'true',
         'wt': 'json',
         'rows': 21
         }

ret = run_query(query)

fq = '+site_id:"{}" +state:active'.format(args.site_id)
query = {'q': '*:*',
         'facet.limit': -1,
         'facet.field': ['groups', 'owner_org'],
         'fl': 'groups', 
         'fq': fq,
         'facet.mincount': 1,
         'facet': 'true',
         'wt': 'json',
         'rows': 21
         }
ret = run_query(query)

print('Search harvest sources')
fq = '+dataset_type:harvest -collection_package_id:["" TO *] +site_id:"{}" +state:active'.format(args.site_id)
query ={
    'facet.limit': 50,
    'q': '*:*',
    'facet.field': ['organization_type', 'frequency', 'source_type', 'organization'],
    'fl': 'id validated_data_dict',
    'start': 0,
    'sort': 'views_recent desc',
    'fq': fq,
    'facet.mincount': 1,
    'facet': 'true',
    'wt': 'json',
    'rows': 21
    }

ret = run_query(query)