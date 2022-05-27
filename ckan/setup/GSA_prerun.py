import os
import sys
import time
try:
    from urllib.request import urlopen
    from urllib.error import URLError
except ImportError:
    from urllib2 import urlopen
    from urllib2 import URLError

import prerun as pr

RETRY = 5


def check_solr_connection(retry=None):
    if retry is None:
        retry = RETRY
    elif retry == 0:
        print("[prerun] Giving up after 5 tries...")
        sys.exit(1)

    url = os.environ.get("CKAN_SOLR_URL", "")
    search_url = "{url}/select/?q=*&wt=json".format(url=url)

    try:
        connection = urlopen(search_url)
    except URLError as e:
        print(str(e))
        print("[prerun] Unable to connect to solr, waiting...")
        time.sleep(10)
        check_solr_connection(retry=retry - 1)
    else:
        try:
            pythonified = str(connection.read()).replace('true', 'True')
            eval(pythonified)
        except TypeError:
            pass


if __name__ == "__main__":

    maintenance = os.environ.get("MAINTENANCE_MODE", "").lower() == "true"

    if maintenance:
        print("[prerun] Maintenance mode, skipping setup...")
    else:
        pr.check_main_db_connection()
        pr.init_db()
        pr.update_plugins()
        pr.check_datastore_db_connection()
        pr.init_datastore_db()
        # This function does not work, but solr is up
        # check_solr_connection()
        pr.create_sysadmin()
