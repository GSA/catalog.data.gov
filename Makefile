.PHONY: all build clean copy-src local requirements setup test up update-dependencies

CKAN_HOME := /srv/app

all: build

ci:
	docker-compose up -d
	sleep 40

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

quick-test:
	# if local environment is already build and running 
	docker-compose -f docker-compose.yml -f docker-compose.test.yml build test
	docker-compose -f docker-compose.yml -f docker-compose.test.yml up --abort-on-container-exit test

update-dependencies:
	docker-compose run --rm -T ckan freeze-requirements.sh $(shell id -u) $(shell id -g)
	cp requirements/requirements.txt ckan/requirements.txt
up:
	docker-compose up

test-import-tool:
	cd tools/harvest_source_import && \
		pip install --upgrade pip  && \
		pip install -r dev-requirements.txt && \
		flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics  && \
		flake8 . --count --exit-zero --max-complexity=10 --max-line-length=127 --statistics  && \
		python -m pytest --vcr-record=none tests/

lint-all:
	docker-compose exec ckan \
		bash -c "cd $(CKAN_HOME)/src && \
		 		 pip install --upgrade pip  && \
				 pip install flake8 && \
				 flake8 . --count --select=E9 --show-source --statistics"

generate-openess-report:
	# generate report at /report/openness
	docker-compose exec ckan paster --plugin=ckanext-report report generate openness


update-tracking-info:
	# https://docs.ckan.org/en/2.8/maintaining/tracking.html
	docker-compose exec ckan paster --plugin=ckan tracking update

rebuild-search-index:
	docker-compose exec ckan paster --plugin=ckan search-index rebuild

update-qa-info:
	# QA is performed when a dataset/resource is archived, or you can run it manually using a paster command:
	docker-compose exec ckan paster --plugin=ckanext-qa qa update

update-archiver-info:
	docker-compose exec ckan paster --plugin=ckanext-archiver archiver update

generate-all-reports:
	docker-compose exec ckan paster --plugin=ckanext-report report generate

ckan-worker:
	docker-compose exec ckan paster --plugin=ckan jobs worker bulk

archiver-worker:
	export C_FORCE_ROOT=1  # celery don't want to run as root
	docker-compose exec ckan paster --plugin=ckanext-archiver celeryd2 run all

harvest-fetch-queue:
	docker-compose exec ckan paster --plugin=ckanext-harvest harvester fetch_consumer

harvest-gather-queue:
	docker-compose exec ckan paster --plugin=ckanext-harvest harvester gather_consumer

harvest-check-finished-jobs:
	docker-compose exec ckan paster --plugin=ckanext-harvest harvester run

test-extensions:
	# test our extensions

	# deal with the CKAN path
	docker-compose exec ckan bash -c "ln -sf $(CKAN_HOME)/src/ckan $(CKAN_HOME)/ckan"
	
	# full test geodatagov
	docker-compose exec ckan bash -c \
		"cd $(CKAN_HOME)/src/ckanext-geodatagov && \
		 nosetests --ckan --with-pylons=test.ini ckanext/geodatagov/tests --nologcapture"
	
	# full test datajson
	docker-compose exec ckan bash -c \
		"cd $(CKAN_HOME)/src/ckanext-datajson && \
		 nosetests --ckan --with-pylons=test.ini ckanext/datajson/tests --nologcapture"
	
	# full test datagovtheme
	docker-compose exec ckan bash -c \
		"cd $(CKAN_HOME)/src/ckanext-datagovtheme && \
		 nosetests --ckan --with-pylons=test.ini ckanext/datagovtheme/tests --nologcapture"
