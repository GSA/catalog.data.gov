FROM openknowledge/ckan-dev:2.8
# Inherit from here: https://github.com/okfn/docker-ckan/blob/master/ckan-dev/2.8/Dockerfile
# And then from here: https://github.com/okfn/docker-ckan/blob/master/ckan-base/2.8/Dockerfile

MAINTAINER Your Name Here <you@example.com>

# Set timezone
ARG TZ
RUN cp /usr/share/zoneinfo/$TZ /etc/localtime
RUN echo $TZ > /etc/timezone

# add dependencies for cryptography and vim

RUN apk add libressl-dev musl-dev libffi-dev vim

# Fix shapely lib error. Install geos
# TODO consider moving to Alpine>=3.11 or to Bionic

ADD http://download.osgeo.org/geos/geos-3.7.0.tar.bz2 /geos/geos.tar.bz2
RUN tar xf /geos/geos.tar.bz2 -C /geos --strip-components=1
RUN cd /geos && \
    ./configure && \
    make -j 1 && \
    make install

COPY requirements.txt ${APP_DIR}

RUN cd ${SRC_DIR}/ckan && \
    git remote add gsa https://github.com/GSA/ckan.git && \
    git fetch gsa && \
    git checkout gsa/datagov-newcatalog

# remove CKAN from req file. It fails because of the ckan/ckan repo from the base image.
RUN sed -i '/GSA\/ckan\.git/d' ${APP_DIR}/requirements.txt

RUN pip install -r requirements.txt
RUN pip install poetry
COPY freeze-requirements.sh /usr/local/bin
COPY docker-entrypoint.d/* /docker-entrypoint.d/

 