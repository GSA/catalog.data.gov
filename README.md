# catalog.data.gov local development environment

[![CircleCI](https://circleci.com/gh/GSA/catalog.data.gov.svg?style=svg)](https://circleci.com/gh/GSA/catalog.data.gov)

This is a local development harness for catalog.data.gov.

## Getting started

Run `make build up` to build and run the docker images. 

Add `127.0.0.1 ckan` to your `/etc/hosts` file

CKAN will run locally on `ckan:5000`

The `CKAN_SITE_URL`, `CKAN_SYSADMIN_NAME`, and `CKAN_SYSADMIN_PASSWORD` are found in the .env file.

## Tests

Run `make test` to run the smoke tests for the catalog app.

## Clean up

Run `make clean` to stop and remove the containers and volumes associated with this setup.

## Deployable artifacts

The _only_  deployable resource associated with this repository is the `requirements-freeze.txt` file.

## Harvesting

Run `API=xxxx-xxxxx-xxxxx-xxxxx make harvest` to run the harvest import script. Make sure that there is a local catalog instance up and running at http://localhost:5000. This will harvest the first 10 harvest sources from https://catalog.data.gov.

## On Docker CKAN 2.8 images

The repository extends the Open Knowledge Foundation `ckan-dev:2.8` docker image. The `ckan-base:2.8` image, if needed for some reasons, is available via dockerhub with the aformentioned tag, as referenced in [OKF's docker-ckan repository](https://github.com/okfn/docker-ckan).

## Note on requirements

We use a `requirements.txt` file to easily install add new requirements for development.
However, this installation uses the `requirements-freeze.txt` to instantiate the local development environment and the test environment.

Coming soon: better local package management. For the moment, add requirements to `requirements-freeze.txt` and rebuild, OR add an apropriate `requirements.txt` file (default CKAN 2.8 would be a good place to start), and uncoment the `make requirements` command in `Makefile`

## Create an extension

You can use the paster template in much the same way as a source install, only executing the command inside the CKAN container and setting the mounted `src/` folder as output:

    docker-compose -f docker-compose.yml exec ckan-dev /bin/bash -c "paster --plugin=ckan create -t ckanext ckanext-myext -o /srv/app/src_extensions"

The new extension will be created in the `src/` folder. You might need to change the owner of its folder to have the appropiate permissions.

## Running the debugger (pdb / ipdb)

To run a container and be able to add a breakpoint with `pdb` or `ipdb`, run the `ckan-dev` container with the `--service-ports` option:

    docker-compose -f docker-compose.dev.yml run --service-ports ckan-dev

This will start a new container, displaying the standard output in your terminal. If you add a breakpoint in a source file in the `src` folder (`import pdb; pdb.set_trace()`) you will be able to inspect it in this terminal next time the code is executed.

## Applying patches

When building the project you can apply patches by placing them in the `/patches` directory.

## CI

Continuous Integration via [Circle CI](https://app.circleci.com/pipelines/github/GSA/catalog.data.gov)

