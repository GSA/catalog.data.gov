import os
import psycopg2
import requests
import sys
import subprocess
import time
try:
    from urllib.request import urlopen
    from urllib.error import URLError
except ImportError:
    from urllib2 import urlopen
    from urllib2 import URLError

import prerun as pr

RETRY = 5


def init_db():

    db_command = ["ckan", "-c", pr.ckan_ini, "db", "init"]
    print("[prerun] Initializing or upgrading db - start")
    try:
        subprocess.check_output(db_command, stderr=subprocess.STDOUT)
        print("[prerun] Initializing or upgrading db - end")
    except subprocess.CalledProcessError as e:
        # GSA FIX: e.output is bytes upstream
        if "OperationalError" in str(e.output):
            print(e.output)
            print("[prerun] Database not ready, waiting a bit before exit...")
            time.sleep(5)
            sys.exit(1)
        else:
            print(e.output)
            raise e


def check_solr_connection(retry=None):
    if retry is None:
        retry = RETRY
    elif retry == 0:
        print("[prerun] Giving up after 5 tries...")
        sys.exit(1)

    CKAN_SOLR_USER = os.environ.get("CKAN_SOLR_USER", "")
    CKAN_SOLR_PASSWORD = os.environ.get("CKAN_SOLR_PASSWORD", "")
    url = os.environ.get("CKAN_SOLR_URL", "").replace('http://', f'http://{CKAN_SOLR_USER}:{CKAN_SOLR_PASSWORD}@')
    search_url = "{url}/select/?q=*&wt=json".format(url=url)

    try:
        # Using requests to add username and password to URL
        connection = requests.request("GET", search_url)
    except URLError as e:
        print(str(e))
        print("[prerun] Unable to connect to solr, waiting...")
        time.sleep(10)
        check_solr_connection(retry=retry - 1)
    else:
        # GSA FIX: convert Solr 'true' to Python 'True'
        try:
            pythonified = str(connection.text).replace('true', 'True')
            eval(pythonified)
        except TypeError:
            pass


if __name__ == "__main__":

    maintenance = os.environ.get("MAINTENANCE_MODE", "").lower() == "true"

    if maintenance:
        print("[prerun] Maintenance mode, skipping setup...")
    else:
        pr.check_main_db_connection()
        init_db()
        pr.update_plugins()
        pr.check_datastore_db_connection()
        pr.init_datastore_db()
        check_solr_connection()
        pr.create_sysadmin()
