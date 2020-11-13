import argparse
import os
import re
import random
from locust import HttpUser, task, between


def generate_url(apache_urls_path='results.txt'):
    f = open(apache_urls_path, 'r')
    for line in f:
        yield line
generator = generate_url()


class AnonUser(HttpUser):
    wait_time = between(0.1, 0.2)

    def get_name(self, next_url):
        if next_url.startswith('/organization'): return 'org'
        elif next_url.startswith('/group'): return 'group'
        elif next_url.startswith('/dataset'):return 'dataset'
        elif next_url.startswith('/harvest'): return 'harvest'
        elif next_url.startswith('/api'): return 'api'
        else: return None

    @task
    def from_apache_logs(self):
        try:
            next_url = next(generator)
        except StopIteration:
            # finish 
            self.environment.runner.quit()
        
        # to skip thousand of lines we need to group this call using names
        name = self.get_name(next_url)
        if name is None:
            # look for language URLs
            URL_REGEX = r'\/(?P<lang>([A-Za-z_-]+))\/(?P<main>.*)'
            compiled = re.compile(URL_REGEX)
        
            match = compiled.match(next_url)
            if match is None:
                print('Not match for \n\t[{}]'.format(next_url))
            else:
                data = match.groupdict()
                name = self.get_name("/" + data['main'])
                if name is not None:
                    name = 'LANG_' + name

        if name is None:        
            name = 'others'
            print('{} not recognized'.format(next_url))
            
        self.client.get(next_url, name=name)
