[![CircleCI](https://circleci.com/gh/GSA/catalog.data.gov.svg?style=svg)](https://circleci.com/gh/GSA/catalog.data.gov)


# catalog.data.gov


This is a local development harness for catalog.data.gov.


## Usage

The _only_  deployable artifact associated with this repository is the
`requirements-freeze.txt` file. See [datagov-deploy](https://github.com/GSA/datagov-deploy)
for full configuration in live environments.


## Development

### Requirements

We assume your environment is already setup with these tools.

- [GNU Make](https://www.gnu.org/software/make/)
- [Docker Compose](https://docs.docker.com/compose/overview/)


### Getting started

Build and start the docker containers.

    $ make build up

Add `127.0.0.1 ckan` to your `/etc/hosts` file.

Open your web browser to [ckan:5000](http://ckan:5000/user/login). You can log
into your instance with user `admin`, password `password`.

Run the integration tests.

    $ make test

Stop and remove the containers and volumes associated with this setup.

    $ make clean

 See `.env` to override settings. Some settings may require a re-build (`make
 clean build`).


## On Docker CKAN 2.8 images

The repository extends the Open Knowledge Foundation `ckan-dev:2.8` docker
image. The `ckan-base:2.8` image, if needed for some reasons, is available via
dockerhub with the aformentioned tag, as referenced in [OKF's docker-ckan
repository](https://github.com/okfn/docker-ckan).


## Note on requirements

The source of truth about package dependencies is managed with
*pipenv* kept in `requirements/Pipfile` and
`requirements/Pipfile.lock`.  The base OKFN Docker image we are using,
though, doesn't know about *pipenv*.  We have modified our ckan image
(`ckan/Dockerfile`) to install frozen requirements from
`ckan/requirements.txt` at image build time to help ensure all
developers are working with the same set of requirements.

The Makefile target *update-dependencies* will use pipenv to generate a new
`Pipfile.lock` and update `ckan/requirements.txt`. _Note: Please be patient.
pipenv can take several minutes to re-generate a lock file (in once case even up
to 17 minutes)._

To support sandbox installation via the ansible playbooks, there is a
symbolic link `requirements-freeze.txt` that references
`ckan/requirements.txt`.

### Procedure for updating a dependency

1.  Add/change the dependency in `requirements/Pipfile`
2.  Run `make update-dependencies build test`
3.  Make sure to commit `ckan/requirements.txt` `requirements/Pipfile`
    and `requirements/Pipfile.lock` to make the change permanent.

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


## Applying patches

When building the project you can apply patches by placing them in the
`/patches` directory.


## CI

Continuous Integration via [Circle
CI](https://app.circleci.com/pipelines/github/GSA/catalog.data.gov).

To configure Continuous Delivery, see
[datagov-deploy](https://github.com/GSA/datagov-deploy#circleci-setup) for how
to setup CircleCI.
