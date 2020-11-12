from locust import HttpUser, TaskSet, task
import random

fname = "/scripts/locust-catalognext-urls"
with open (fname, "r") as urlfile:
    data = urlfile.readlines()

class BasicTaskSet(TaskSet):

    @task(1)
    def index(self):
        global data
        url = random.choice(data)
        self.client.get(url)

class BasicTasks(HttpUser):
    tasks = [BasicTaskSet]
    min_wait = 5000
    max_wait = 9000