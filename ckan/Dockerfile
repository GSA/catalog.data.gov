FROM openknowledge/ckan-dev:2.9
# Inherit from here: https://github.com/okfn/docker-ckan/blob/master/ckan-dev/2.8/Dockerfile
# And then from here: https://github.com/okfn/docker-ckan/blob/master/ckan-base/2.8/Dockerfile

ENV GIT_BRANCH=2.9

# add dependencies for cryptography and vim
RUN apk add libressl-dev musl-dev libffi-dev xmlsec vim xmlsec-dev

# Fix shapely lib error. Install geos
# TODO consider moving to Alpine>=3.11 or to Bionic

ADD http://download.osgeo.org/geos/geos-3.7.0.tar.bz2 /geos/geos.tar.bz2
RUN tar xf /geos/geos.tar.bz2 -C /geos --strip-components=1
RUN cd /geos && \
    ./configure && \
    make -j 1 && \
    make install

COPY requirements.txt ${APP_DIR}

RUN pip3 install --upgrade pip && sudo -u ckan -EH pip3 install -r requirements.txt --ignore-installed

COPY freeze-requirements.sh /usr/local/bin
COPY docker-entrypoint.d/* /docker-entrypoint.d/

# Not currently in use in development
COPY setup/gunicorn.conf.py ${APP_DIR}/
COPY setup/server_start.sh ${APP_DIR}/

COPY saml2 ${APP_DIR}/saml2

# COPY the ini test file to the container 
COPY test-catalog-next.ini ${SRC_DIR}/ckan
