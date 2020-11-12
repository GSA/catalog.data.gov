import argparse
import os
import random
from locust import HttpUser, task, between


def generate_url(apache_urls_path='results.txt'):
    f = open(apache_urls_path, 'r')
    for line in f:
        yield line
generator = generate_url()


class AnonUser(HttpUser):
    wait_time = between(0.1, 0.2)

    @task
    def from_apache_logs(self):
        try:
            next_url = next(generator)
        except StopIteration:
            # finish 
            self.environment.runner.quit()
        self.client.get(next_url)
