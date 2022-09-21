[![GitHub Actions](https://github.com/gsa/catalog.data.gov/actions/workflows/publish.yml/badge.svg)](https://github.com/GSA/catalog.data.gov/actions/workflows/publish.yml)


# catalog.data.gov


This is a local development harness for catalog.data.gov.


## Usage

The _only_  deployable artifact associated with this repository is the
`requirements.txt` file. See github actions
for full configuration in live environments.

The live environment is different than the development environment in
a number of ways. Changes made in this repo that work correctly in the
development environment may require additional steps to be taken in
order to make sure the application is deployable to the live
environment:

- If you need to add or change a dependency, you should make that
  change in the `ckan/requirements.in`, run `make update-dependencies`
  and commit the changed files.  (See the section below on
  requirements for details.)  Good news: no other changes are required!
  
- If you need to add or change configuration that lives in the
  application *ini* file (such as a plugin), you will also need to 
  update the configuration file template at `ckan/setup/ckan.ini`.
  
- If you find you need to modify the `ckan/Dockerfile` to add OS
  packages or install software, other changes may need to be made to
  the cloud.gov buildpack.  Please bring these situations to the team's
  attention.

## Development

### Requirements

We assume your environment is already setup with these tools.

- [GNU Make](https://www.gnu.org/software/make/)
- [Docker Compose](https://docs.docker.com/compose/overview/)


### Getting started

Build and start the docker containers.

    $ make build up

Open your web browser to [localhost:5000](http://localhost:5000) (or [ckan:5000](http://ckan:5000) if you add ckan to your `hosts` file).  
You can log into your instance with user `admin`, password `password`.

Run the integration tests.

    $ make test

Stop and remove the containers and volumes associated with this setup.

    $ make clean

 See `.env` to override settings. Some settings may require a re-build (`make
 clean build`).

*Note: the solr configuration has a locking mechanism that only allows one
solr to access its data at a time.  There are two methods to recover solr in
this state.  `make clear-solr-volume` destroys all of the solr data and starts
from scratch.  `make unlock-solr-volume` unlocks the data to allow another
solr to access it.  BE CAREFUL when running the `make unlock-solr-volume`
command!  If two solrs are talking to the same volume, the data may corrupt
and would need to be destroyed anyway.*

### Test extensions

To test extensions locally you can run
_TODO: update this for pytest_

```
docker-compose exec ckan bash
nosetests --ckan --with-pylons=src/ckan/test-catalog-next.ini src/ckanext-datagovtheme/ckanext/datagovtheme/
nosetests --ckan --with-pylons=src/ckan/test-catalog-next.ini src/ckanext-datagovtheme/ckanext/datajson/
nosetests --ckan --with-pylons=src/ckan/test-catalog-next.ini src/ckanext-datagovtheme/ckanext/geodatagov/
```

### Run Cypress Tests

To test the UI and e2e user tests, run

    $ make test

#### Run Cypress tests interactively

To run cypress tests locally, cypress needs to be installed first.
Run `npm install cypress`.

At this point, you will need to manually change the .env file to
have `CKAN_SITE_URL=http://localhost:5000`. This is to cover for 
a docker bug upstream: https://github.com/docker/compose/issues/7423

Then, you can run `make cypress`. For WSL or complex installation, please see
a data.gov team member or follow the steps laid out
[here](https://nickymeuleman.netlify.app/blog/gui-on-wsl2-cypress#vcxsrv).

## Deploying to cloud.gov

Copy `vars.yml.template` to `vars.yml`, and customize the values in that file. Then, assuming [you're logged in for the Cloud Foundry CLI](https://cloud.gov/docs/getting-started/setup/):

To make sure that python packages are compatible with cloud.gov buildpaks, the following script updates and caches all the Python package requirements.  The script has an optional parameter `[build]` to build the base cloudfoundry image.  This parameter must be invoked at least once before the requirements can be vendored.

```sh
./vendor-requirements.sh [build]
```

Create the database used by CKAN itself. You have to wait a bit for the datastore DB to be available (see [the cloud.gov instructions on how to know when it's up](https://cloud.gov/docs/services/relational-database/#instance-creation-time)).

    $ cf create-service aws-rds small-psql ${app_name}-db -c '{"version": "11"}'

Create the Redis service for cache

    $ cf create-service aws-elasticache-redis redis-dev ${app_name}-redis

Create the SOLR service for data search

    $ cf create-service solr-cloud base ${app_name}-solr -c solr/service-config.json -b ssb-solr-gsa-datagov-development

Create the secrets service to store secret environment variables. See
[Secrets](#secrets) below.

You should now be able to visit `https://[ROUTE]`, where `[ROUTE]` is the route reported by `cf app ${app_name}`.


### Secrets

ips on managing
[secrets](https://github.com/GSA/datagov-deploy/wiki/Cloud.gov-Cheat-Sheet#secrets-management).
When creating the service for the first time, use `create-user-provided-service`
instead of update.

    $ cf update-user-provided-service ${app_name}-secrets -p 'CKAN___BEAKER__SESSION_SECRET, SAML2_PRIVATE_KEY'

Name | Description | Where to find
---- | ----------- | -------------
CKAN___BEAKER__SESSION__SECRET | Session secret for encrypting CKAN sessions. | `pwgen -s 32 1`
SAML2_PRIVATE_KEY | Base64 encoded SAML2 key matching the certificate configured for Login.gov | [Google Drive](https://drive.google.com/drive/u/0/folders/1VguFPRiRb1Ljnm_6UShryHWDofX0xBnU)


## Login.gov integration

We use Login.gov as our
[SAML2](https://github.com/GSA/datagov-deploy/wiki/SAML2-authentication)
Identity Provider (IdP). Production apps use the production Login.gov instance
while other apps use the Login.gov identity sandbox.

Each year in March, Login.gov rotates their credentials. See our
[wiki](https://github.com/GSA/datagov-deploy/wiki/SAML2-authentication#working-with-logingov)
for details.

Our Service Provider (SP) certificate and key are provided in through
environment variable and user-provided service.

The Login.gov IdP metadata is stored in file under `ckan/setup/`.


## On Docker CKAN 2.9 images

The repository extends the Open Knowledge Foundation `ckan-dev:2.9` docker
image. The `ckan-base:2.9` image, if needed for some reasons, is available via
dockerhub with the aformentioned tag, as referenced in [OKF's docker-ckan
repository](https://github.com/okfn/docker-ckan).


## Public docker image

If build pass tests a docker-image will be published in the docker hub: https://hub.docker.com/r/datagov/catalog-next.  
This image will be used in extensions to test.  

## Note on requirements

The source of truth about package dependencies is managed with
*pip* kept in `ckan/requirements.txt`.  The base OKFN Docker image we are using,
though, doesn't install all dependencies we need.  We have modified our ckan image
(`ckan/Dockerfile`) to install frozen requirements from
`ckan/requirements.txt` at image build time to help ensure all
developers are working with the same set of requirements.

The Makefile target *update-dependencies* will use pip to generate a new
`requirements.txt` and update `ckan/requirements.txt`.

    $ make update-dependencies

To support cloud.gov installation via normal python buildpack, there is a
symbolic link `requirements.txt` that references
`ckan/requirements.txt`.

### Adding new extensions in requirements
If you try to add and extension and it didn't work you should 
try `chown user:user -R .` (in the _catalog.data.gov_ repo folder) 
because if you run docker as 
superuser and then as a regular user won't be able to add 
the folder for the new extension

### Procedure for updating a dependency

1.  Add/change the dependency in `ckan/requirements.in`
2.  Run `make update-dependencies build clean test`
3.  Make sure to commit `ckan/requirements.txt` and `ckan/requirements.in`
    to make the change permanent.

## Create an extension

You can use the ckan template in much the same way as a source install, only
executing the command inside the CKAN container and setting the mounted `src/`
folder as output:

    $ docker-compose exec ckan /bin/bash -c \
    "ckan generate extension"

The new extension will be created in the `src/` folder. You might need to change
the owner of its folder to have the appropriate permissions.


## Running the debugger (pdb / ipdb)

To run a container and be able to add a breakpoint with `pdb` or `ipdb`, run the
`ckan-dev` container with the `--service-ports` option:

    docker-compose run --service-ports ckan

This will start a new container, displaying the standard output in your
terminal. If you add a breakpoint in a source file in the `src` folder (`import
pdb; pdb.set_trace()`) you will be able to inspect it in this terminal next time
the code is executed.
If you are testing a harvest process (gather/fetch/run), try turning off the command
to start in the background in the `ckan/docker-entrypoint.d/10-setup-harvest.sh`.
Then, run the relevant command manually (`make harvest-fetch-queue`) after startup.

## SAML2

To enable the ckanext-saml2 extension, add `saml2auth` to `CKAN__PLUGINS` list in the `.env` file and then access to https://localhost:8443/dataset
Open your web browser to [localhost:8443](https://localhost:8443).  
You can log into your instance with you login.gov user. 


## CI

Continuous Integration via [GitHub Actions](https://github.com/GSA/catalog.data.gov/actions/workflows/commit.yml).

Continuous Deployment via [GitHub Actions](https://github.com/GSA/catalog.data.gov/actions/workflows/publish.yml).
