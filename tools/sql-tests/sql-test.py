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
parser.add_argument("--package_id", type=str, help="A package id is required")

args = parser.parse_args()

print(f'Connecting to {args.db_host} DB:{args.db_name}')
connection = psycopg2.connect(user=args.user,
                              password=args.password,
                              host=args.db_host,
                              port=args.port,
                              database=args.db_name)
cursor = connection.cursor()


# var for templates
context = {
    'package_id': args.package_id
}

# get all sql queries
queries = []
for sql_file in os.listdir('sql'):
    path = os.path.join('sql', sql_file)
    ext = sql_file.split('.')[-1]
    if ext != 'sql':
        continue
    
    f = open(path)
    query = f.read()
    f.close()

    # add the context values
    tm = Template(query)
    final_query = tm.render(**context)

    queries.append((sql_file, final_query))
    

for query_full in queries:
    query_name, query = query_full
    print(f'Running "{query_name}": \n\t{query}')
    
    start = time.time()
    cursor.execute(query)
    records = cursor.fetchall()
    end = time.time()
    final_time = round(end - start, 2) 
    colnames = [desc[0] for desc in cursor.description]

    print('==============')
    print(f'Finished in {final_time}')
    print('==============')
    
    print("RESULTS (first 10)")
    c = 0
    for row in records:
        c += 1
        for col in colnames:
            print(col, end=' |')
        print()
        
        for val in row:
            print(val, end=' |')
        
        if c == 10:
            break

cursor.close()
connection.close()
print("PostgreSQL connection is closed")