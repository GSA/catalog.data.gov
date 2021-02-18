[![CircleCI](https://circleci.com/gh/GSA/catalog.data.gov.svg?style=svg)](https://circleci.com/gh/GSA/catalog.data.gov)


# catalog.data.gov


This is a local development harness for catalog.data.gov.


## Usage

The _only_  deployable artifact associated with this repository is the
`requirements-freeze.txt` file. See [datagov-deploy](https://github.com/GSA/datagov-deploy)
for full configuration in live environments.

The live environment is different than the development environment in
a number of ways. Changes made in this repo that work correctly in the
development environment may require additional steps to be taken in
order to make sure the application is deployable to the live
environment:

- If you need to add or change a dependency, you should make that
  change in the `requirements/pyproject.toml`, run `make update-dependencies`
  and commit the changed files.  (See the section below on
  requirements for details.)  Good news: no other changes are required!
  
- If you need to add or remove a plugin, you will also need to update
  the plugin list in
  [datagov-deploy](https://github.com/GSA/datagov-deploy) Currently,
  that means updating the value of `catalog_next_ckan_plugins_default` in
  `ansible/inventories/sandbox/group_vars/all/vars.yml`
  
- If you need to add or change configuration that lives in the
  application *ini* file, you will also need to update the
  configuration file template in
  [datagov-deploy](https://github.com/GSA/datagov-deploy) Currently,
  this means modifying
  `ansible/roles/software/ckan/catalog/ckan-app/templates/catalog-next/etc_ckan_production_ini.j2`.
  
- If you find you need to modify the `ckan/Dockerfile` to add OS
  packages or install software, other changes may need to be made to
  the ansible playbooks.  Please bring these situations to the team's
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

### Test extensions

To test extensions locally you can run

```
docker-compose exec ckan bash
nosetests --ckan --with-pylons=src/ckan/test-catalog-next.ini src/ckanext-datagovtheme/ckanext/datagovtheme/
nosetests --ckan --with-pylons=src/ckan/test-catalog-next.ini src/ckanext-datagovtheme/ckanext/datajson/
nosetests --ckan --with-pylons=src/ckan/test-catalog-next.ini src/ckanext-datagovtheme/ckanext/geodatagov/
```

## Deploying to cloud.gov

Copy `vars.yml.template` to `vars.yml`, and customize the values in that file. Then, assuming [you're logged in for the Cloud Foundry CLI](https://cloud.gov/docs/getting-started/setup/):

Update and cache all the Python package requirements

```sh
./vendor-requirements.sh
```

Create the database used by CKAN itself. You have to wait a bit for the datastore DB to be available (see [the cloud.gov instructions on how to know when it's up](https://cloud.gov/docs/services/relational-database/#instance-creation-time)).

    $ cf create-service aws-rds small-psql ${app_name}-db -c '{"version": 11}'

Create the Redis service for cache

    $ cf create-service aws-elasticache-redis redis-dev ${app_name}-redis

Create the user provided service for secrets

    $ cf cups ${app_name}-secrets -p "CKAN___BEAKER__SESSION__SECRET"

Deploy the Solr instance and the app.

    $ cf push --vars-file vars.yml

**Note that the automated deployment only deploys the application, any solr changes**
**(temporary until ssb is ready) needs to be deployed manually using `cf push --vars-file vars.yml catalog-solr`**

Ensure the inventory app can reach the Solr app.

    $ cf add-network-policy ${app_name} --destination-app ${app_name}-solr --protocol tcp --port 8983

You should now be able to visit `https://[ROUTE]`, where `[ROUTE]` is the route reported by `cf app ${app_name}`.

## On Docker CKAN 2.8 images

The repository extends the Open Knowledge Foundation `ckan-dev:2.8` docker
image. The `ckan-base:2.8` image, if needed for some reasons, is available via
dockerhub with the aformentioned tag, as referenced in [OKF's docker-ckan
repository](https://github.com/okfn/docker-ckan).


## Public docker image

If build pass tests a docker-image will be published in the docker hub: https://hub.docker.com/r/datagov/catalog-next.  
This image will be used in extensions to test.  

## Note on requirements

The source of truth about package dependencies is managed with
*poetry* kept in `requirements/pyproject.toml` and
`requirements/poetry.lock`.  The base OKFN Docker image we are using,
though, doesn't know about *poetry*.  We have modified our ckan image
(`ckan/Dockerfile`) to install frozen requirements from
`ckan/requirements.txt` at image build time to help ensure all
developers are working with the same set of requirements.

The Makefile target *update-dependencies* will use poetry to generate a new
`poetry.lock` and update `ckan/requirements.txt`. _Note: Please be patient.
poetry can take several minutes to re-generate a lock file (in once case even up
to 17 minutes)._

To support sandbox installation via the ansible playbooks, there is a
symbolic link `requirements-freeze.txt` that references
`ckan/requirements.txt`.

### Adding new extensions in requirements
If you try to add and extension and it didn't work you should 
try `chown user:user -R .` (in the _catalog.data.gov_ repo folder) 
because if you run docker as 
superuser and then as a regular user won't be able to add 
the folder for the new extension

### Procedure for updating a dependency

1.  Add/change the dependency in `requirements/pyproject.toml`
2.  Run `make update-dependencies build test`
3.  Make sure to commit `ckan/requirements.txt` `requirements/pyproject.toml`
    and `requirements/poetry.lock` to make the change permanent.

## Create an extension

You can use the paster template in much the same way as a source install, only
executing the command inside the CKAN container and setting the mounted `src/`
folder as output:

    $ docker-compose -f docker-compose.yml exec ckan-dev /bin/bash -c \
    "paster --plugin=ckan create -t ckanext ckanext-myext -o /srv/app/src_extensions"

The new extension will be created in the `src/` folder. You might need to change
the owner of its folder to have the appropriate permissions.


## Running the debugger (pdb / ipdb)

To run a container and be able to add a breakpoint with `pdb` or `ipdb`, run the
`ckan-dev` container with the `--service-ports` option:

    docker-compose -f docker-compose.dev.yml run --service-ports ckan-dev

This will start a new container, displaying the standard output in your
terminal. If you add a breakpoint in a source file in the `src` folder (`import
pdb; pdb.set_trace()`) you will be able to inspect it in this terminal next time
the code is executed.


## SAML2

To enable the ckanext-saml2 extension, add `saml2auth` to `CKAN__PLUGINS` list in the `.env` file and then access to https://localhost:8443/dataset
Open your web browser to [localhost:8443](https://localhost:8443).  
You can log into your instance with you login.gov user. 


## CI

Continuous Integration via [Circle
CI](https://app.circleci.com/pipelines/github/GSA/catalog.data.gov).

To configure Continuous Delivery, see
[datagov-deploy](https://github.com/GSA/datagov-deploy#circleci-setup) for how
to setup CircleCI.
