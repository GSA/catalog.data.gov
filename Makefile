.PHONY: all build clean copy-src local setup test up update-dependencies

CKAN_HOME := /srv/app

all: build

ci:
	docker-compose up -d

build:
	docker build -t ghcr.io/gsa/catalog.data.gov:latest ckan/
	docker build -t ghcr.io/gsa/catalog.data.gov.solr:latest solr/
	docker build -t ghcr.io/gsa/catalog.data.gov.db:latest postgresql/
	docker-compose build

clean:
	docker-compose down -v --remove-orphans

copy-src:
	docker cp catalog-app_ckan_1:$(CKAN_HOME)/src .

cypress:
	# Turn on local system, and open cypress in interactive mode
	docker-compose up -d && cd e2e && CYPRESS_USER=admin CYPRESS_USER_PASSWORD=password CYPRESS_BASE_URL=http://localhost:5000 npx cypress open

dev:
	docker build -t ghcr.io/gsa/catalog.data.gov:latest ckan/
	docker-compose build
	docker-compose up

debug:
	docker build -t ghcr.io/gsa/catalog.data.gov:latest ckan/
	docker-compose build
	docker-compose run --service-ports ckan

test:
	# docker build -t ghcr.io/gsa/catalog.data.gov:latest ckan/
	docker-compose -f docker-compose.yml -f docker-compose.test.yml build
	docker-compose -f docker-compose.yml -f docker-compose.test.yml up --abort-on-container-exit test

quick-bat-test:
	# if local environment is already build and running 
	docker-compose -f docker-compose.yml -f docker-compose.test.yml up --abort-on-container-exit test

update-dependencies:
	docker-compose run --rm -T ckan /app/ckan/freeze-requirements.sh $(shell id -u) $(shell id -g)

up:
	docker-compose up ckan

test-import-tool:
	cd tools/harvest_source_import && \
		pip install pip==20.3.3  && \
		pip install -r dev-requirements.txt && \
		flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics  && \
		flake8 . --count --exit-zero --max-complexity=10 --max-line-length=127 --statistics  && \
		python -m pytest --vcr-record=none tests/

lint-all:
	docker-compose exec -T ckan \
		bash -c "cd $(CKAN_HOME)/src && \
		 		 pip install pip==20.3.3  && \
				 pip install flake8 && \
				 flake8 . --count --select=E9 --show-source --statistics"

generate-openess-report:
	# generate report at /report/openness
	docker-compose exec ckan report generate openness


update-tracking-info:
	# https://docs.ckan.org/en/2.8/maintaining/tracking.html
	docker-compose exec ckan ckan tracking update

rebuild-search-index:
	docker-compose exec ckan ckan search-index rebuild

update-qa-info:
	# QA is performed when a dataset/resource is archived, or you can run it manually using a ckan command:
	docker-compose exec ckan ckan qa update

update-archiver-info:
	docker-compose exec ckan ckan archiver update

generate-all-reports:
	docker-compose exec ckan ckan report generate

ckan-worker:
	docker-compose exec ckan ckan jobs worker bulk

archiver-worker:
	export C_FORCE_ROOT=1  # celery don't want to run as root
	docker-compose exec ckan ckan celeryd2 run all

harvest-fetch-queue:
	docker-compose exec ckan ckan harvester fetch-consumer

harvest-gather-queue:
	docker-compose exec ckan ckan harvester gather-consumer

harvest-check-finished-jobs:
	docker-compose exec ckan ckan harvester run

test-extensions:
	# test our extensions

	# deal with the CKAN path
	docker-compose exec ckan bash -c "ln -sf $(CKAN_HOME)/src/ckan $(CKAN_HOME)/ckan"
	
	# full test datajson
	docker-compose exec ckan bash -c \
		"cd $(CKAN_HOME)/src/ckanext-datajson && \
		 nosetests --ckan --with-pylons=$(CKAN_HOME)/src/ckan/test-catalog-next.ini ckanext/datajson/tests --debug=ckanext"
	
	# full test datagovtheme
	docker-compose exec ckan bash -c \
		"cd $(CKAN_HOME)/src/ckanext-datagovtheme && \
		 nosetests --ckan --with-pylons=$(CKAN_HOME)/src/ckan/test-catalog-next.ini ckanext/datagovtheme/tests --debug=ckanext"

	# full test geodatagov
	docker-compose exec ckan bash -c \
		"cd $(CKAN_HOME)/src/ckanext-geodatagov && \
		 nosetests --ckan --with-pylons=$(CKAN_HOME)/src/ckan/test-catalog-next.ini ckanext/geodatagov/tests --debug=ckanext"

	# full test geodatagov
	docker-compose exec ckan bash -c \
		"cd $(CKAN_HOME)/src/ckanext-datagovdatalog && \
		 nosetests --ckan --with-pylons=$(CKAN_HOME)/src/ckan/test-catalog-next.ini ckanext/datagovdatalog/tests --debug=ckanext"
