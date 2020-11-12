import argparse
import os
import random
from locust import HttpUser, task, between

        
class AnonUser(HttpUser):
    wait_time = between(1, 2)

    @task
    def index(self):
        self.client.get('/')
    
    @task
    def harvest(self):
        self.client.get('/harvest')
    
    @task
    def orgs(self):
        self.client.get('/organization')

    @task
    def groups(self):
        self.client.get('/group')
