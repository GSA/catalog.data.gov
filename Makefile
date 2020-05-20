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

harvest:
	echo "\n\n****************** Ensure that the ckan container is up when running this command :) ***\n\n" && python3 ./tools/harvest_source_import/import_harvest_sources.py --origin_url=https://catalog.data.gov --destination_url=http://ckan:5000 --destination_api_key=${API} --source_type=csw --destination_owner_org=my_owner_name_or_id --limit=10
 
# TODO waiting for consensus package management solution
# update-dependencies:
#	docker-compose run --rm -T ckan pip --quiet freeze > requirements-freeze.txt
#	docker-compose run --rm -T ckan pip install -r ${CKAN_HOME}/requirements-freeze.txt

up:
	docker-compose up
