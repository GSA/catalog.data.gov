import argparse
from jinja2 import Template
import os
import psycopg2
import time


parser = argparse.ArgumentParser()
parser.add_argument("--db_host", type=str, help="DB host")
parser.add_argument("--db_name", type=str, help="DB name")
parser.add_argument("--user", type=str, help="DB user name")
parser.add_argument("--password", type=str, help="Password for user")
parser.add_argument("--port", type=int, default=5432, help="Postgresql port")

args = parser.parse_args()

print(f'Connecting to {args.db_host} DB:{args.db_name}')
connection = psycopg2.connect(user=args.user,
                              password=args.password,
                              host=args.db_host,
                              port=args.port,
                              database=args.db_name)
cursor = connection.cursor()


def get_random_pkg_id():
    """ get some random package_id """
    cursor.execute('select id from package ORDER BY random() limit 1')
    record = cursor.fetchone()
    return record[0]

def run_query(name, context=None):
    """ get and SQL query with contexts vars if needed """
    path = os.path.join('sql', '{}.sql'.format(name))
    f = open(path)
    query = f.read()
    f.close()
    if context is not None:
        tm = Template(query)
        query = tm.render(**context)

    start = time.time()
    cursor.execute(query)
    records = cursor.fetchall()
    end = time.time()
    final_time = round(end - start, 2) 
    colnames = [desc[0] for desc in cursor.description]

    ret = {
        'query': query,
        'final_time': final_time,
        'colnames': colnames,
        'records': records
    }
    return ret

def draw_table(records, colnames):
    rows = len(records)
    if rows == 0:
        print('0 results')
    else:
        print("RESULTS (first 10)")
        c = 0
        for col in colnames:
            print(col, end=' |')
        print('\n-----------------------------------------')
            
        for row in records:
            c += 1
            
            for val in row:
                print(val, end=' |')
            print('\n-----------------------------------------')

            if c == 10:
                break


print('==============================')
q = run_query('count_harvest_objects')
print('Harvest objects: {} ({} seconds)'.format(q['records'][0][0], q['final_time']))
q = run_query('count_harvest_logs')
print('Harvest logs: {} ({} seconds)'.format(q['records'][0][0], q['final_time']))
q = run_query('count_harvest_object_extra')
print('Harvest objects extras: {} ({} seconds)'.format(q['records'][0][0], q['final_time']))
q = run_query('count_packages')
print('Packages: {} ({} seconds)'.format(q['records'][0][0], q['final_time']))

hi = run_query('get_harvest_indexes')
print('Harvest indexes (in {} seconds)'.format(hi['final_time']))
draw_table(hi['records'], hi['colnames'])

for r in range(0, 5):
    pkg_id = get_random_pkg_id()
    context = {'package_id': pkg_id}
    hfp = run_query('get_harvest_objects_from_package', context)
    print('Harvest object from package {} ({} results in {} seconds)'.format(pkg_id, len(hfp['records']), hfp['final_time']))
    # draw_table(hfp['records'], hfp['colnames'])

sq = run_query('slow_queries')
print('Slow queries')
draw_table(sq['records'], sq['colnames'])

cursor.close()
connection.close()
