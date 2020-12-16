from __future__ import print_function
import argparse
import json
import psycopg2


parser = argparse.ArgumentParser()
parser.add_argument("--db_host", type=str, help="DB host")
parser.add_argument("--db_name", type=str, help="DB name")
parser.add_argument("--user", type=str, help="DB user name")
parser.add_argument("--password", type=str, help="Password for user")
parser.add_argument("--port", type=int, default=5432, help="Postgresql port")

args = parser.parse_args()

print('Connecting to database')
connection = psycopg2.connect(user=args.user,
                              password=args.password,
                              host=args.db_host,
                              port=args.port,
                              database=args.db_name)
cursor = connection.cursor()
page_size = 10000
pos = 0
c = 0
results = {}
    
while True:
    query = "Select value from package_extra where key = 'extras_rollup' OFFSET {} LIMIT {};".format(pos, page_size)
    print("Querying: {}".format(query))
    pos += page_size
    cursor.execute(query)
    records = cursor.fetchall()
    colnames = [desc[0] for desc in cursor.description]

    for row in records:
        c += 1
        rolled_str = row[0]
        extras_rollup = json.loads(rolled_str)
        cpi = extras_rollup.get('collection_package_id', None)
        if cpi is None:
            continue
        print(" - ROW: {} CPI {}".format(c, cpi))
        
        if cpi not in results.keys():
            results[cpi] = 0
        results[cpi] +=1 
    
    if len(records) < page_size:
        break

cursor.close()
connection.close()

# sort the results
sort_orders = sorted(results.iteritems(), key=lambda x: x[1], reverse=True)

print("--------------------")
print("Big parents")
for res in sort_orders:
    print(res)