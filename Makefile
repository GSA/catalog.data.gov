.PHONY: all build clean copy-src local setup test up update-dependencies

CKAN_HOME := /srv/app

all: build

# ###############################################
# Core commands
# ###############################################

build:
	docker-compose build --parallel

ci:
	docker-compose up -d

clean:
	docker-compose down -v --remove-orphans

cypress:
	# Turn on local system, and open cypress in interactive mode
	# If you haven't remapped localhost > ckan, you should change baseURL to "http://localhost:5000" in `e2e/cypress.json`
	docker-compose up -d && cd e2e && CYPRESS_USER=admin CYPRESS_USER_PASSWORD=password npx cypress@7.3.0 open

dev:
	docker build -t ghcr.io/gsa/catalog.data.gov:latest ckan/
	docker-compose build
	docker-compose up

debug:
	docker build -t ghcr.io/gsa/catalog.data.gov:latest ckan/
	docker-compose build
	docker-compose run --service-ports ckan

up:
	docker-compose up $(ARGS)

update-dependencies:
	docker-compose run --rm -T ckan /app/ckan/freeze-requirements.sh $(shell id -u) $(shell id -g)

# ###############################################
# Test commands
# ###############################################

test:
	# docker build -t ghcr.io/gsa/catalog.data.gov:latest ckan/
	docker-compose -f docker-compose.yml -f docker-compose.test.yml build
	docker-compose -f docker-compose.yml -f docker-compose.test.yml up --abort-on-container-exit test

quick-bat-test:
	# if local environment is already build and running
	docker-compose -f docker-compose.yml -f docker-compose.test.yml up --abort-on-container-exit test

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

# ###############################################
# Helper commands
# ###############################################

clear-solr-volume:
	# Destructive
	docker stop $(shell docker volume rm catalogdatagov_solr_data 2>&1 | cut -d "[" -f2 | cut -d "]" -f1)
	docker rm $(shell docker volume rm catalogdatagov_solr_data 2>&1 | cut -d "[" -f2 | cut -d "]" -f1)
	docker volume rm catalogdatagov_solr_data

unlock-solr-volume:
	# Corruptible
	docker-compose run solr /bin/bash -c "rm -rf /var/solr/data/ckan/data/index/write.lock"

search-index-rebuild:
	docker-compose exec ckan /bin/bash -c "ckan search-index rebuild"

copy-src:
	docker cp catalog-app_ckan_1:$(CKAN_HOME)/src .

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

qa:
ifeq (${PARAMS}, all)
	# PARAMS=all make qa
	docker-compose exec ckan ckan report generate
else ifeq (${PARAMS}, openness)
	# PARAMS=openness make qa
	# generate report at /report/openness
	docker-compose exec ckan ckan report generate openness
else ifeq (${PARAMS}, update)
	# PARAMS=update make qa
	# QA is performed when a dataset/resource is archived, or you can run it manually using a ckan command:
	docker-compose exec ckan ckan qa update
else ifeq (${PARAMS}, archive)
	# PARAMS=archive make qa
	# Archive datasets to perform QA
	docker-compose exec ckan ckan archiver update --queue bulk
else ifeq (${PARAMS}, worker)
	# PARAMS=worker make qa
	docker-compose exec ckan ckan jobs worker bulk
endif

update-tracking-info:
	# https://docs.ckan.org/en/2.8/maintaining/tracking.html
	docker-compose exec ckan ckan tracking update

harvest:
	# Pass any of the following arguments to run them
	# ARGS=run make harvest
	# ARGS=gather-consumer make harvest
	# ARGS=fetch-consumer make harvest
	docker-compose exec ckan ckan harvester $(ARGS)
