.PHONY: all build clean copy-src local requirements setup test up update-dependencies

CKAN_HOME := /srv/app

all: build

ci:
	docker-compose up -d
	sleep 40
	docker-compose logs db
	docker-compose logs ckan

build:
	docker-compose build

clean:
	docker-compose down -v --remove-orphans

copy-src:
	docker cp catalog-app_ckan_1:$(CKAN_HOME)/src .

dev:
	docker-compose build
	docker-compose up

debug:
	docker-compose build
	docker-compose run --service-ports ckan

requirements:
	docker-compose run --rm -T ckan pip --quiet freeze > requirements-freeze.txt

test:
	docker-compose -f docker-compose.yml -f docker-compose.test.yml build
	docker-compose -f docker-compose.yml -f docker-compose.test.yml up --abort-on-container-exit test

update-dependencies:
	docker-compose run --rm -T ckan freeze-requirements.sh $(shell id -u) $(shell id -g) > ckan/requirements.txt

up:
	docker-compose up
