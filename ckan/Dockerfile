FROM openknowledge/ckan-dev:2.8
# Inherit from here: https://github.com/okfn/docker-ckan/blob/master/ckan-dev/2.8/Dockerfile
# And then from here: https://github.com/okfn/docker-ckan/blob/master/ckan-base/2.8/Dockerfile

ENV GIT_BRANCH=2.8

# add dependencies for cryptography and vim
RUN apk add libressl-dev musl-dev libffi-dev xmlsec vim

# Fix shapely lib error. Install geos
# TODO consider moving to Alpine>=3.11 or to Bionic

ADD http://download.osgeo.org/geos/geos-3.7.0.tar.bz2 /geos/geos.tar.bz2
RUN tar xf /geos/geos.tar.bz2 -C /geos --strip-components=1
RUN cd /geos && \
    ./configure && \
    make -j 1 && \
    make install

COPY requirements.txt ${APP_DIR}

RUN pip install --upgrade pip && pip install -r requirements.txt
RUN pip install poetry==1.0.10
COPY freeze-requirements.sh /usr/local/bin
COPY docker-entrypoint.d/* /docker-entrypoint.d/

# Not currently in use in development
COPY setup/server_start.sh ${APP_DIR}/

COPY saml2 ${APP_DIR}/saml2

# COPY the ini test file to the container 
COPY test-catalog-next.ini ${SRC_DIR}/ckan

ARG EXTRA_PLUGINS
ARG ENABLE_SAML2
ARG CKAN_URL

ENV CKAN_SITE_URL=${CKAN_URL:-http://ckan:5000}
ENV ENABLE_SAML2=${ENABLE_SAML2:-}
ENV CKAN__PLUGINS="envvars image_view text_view recline_view datastore datapusher datagov_harvest ckan_harvester geodatagov datajson datajson_harvest geodatagov_miscs z3950_harvester arcgis_harvester geodatagov_geoportal_harvester waf_harvester_collection geodatagov_csw_harvester geodatagov_doc_harvester geodatagov_waf_harvester spatial_metadata spatial_query report qa archiver spatial_harvest_metadata_api datagovtheme datagovcatalog googleanalyticsbasic dcat dcat_json_interface structured_data ${EXTRA_PLUGINS:-}"
