FROM openknowledge/ckan-dev:2.9
# Inherit from here: https://github.com/okfn/docker-ckan/blob/master/ckan-dev/2.9/Dockerfile
# And then from here: https://github.com/okfn/docker-ckan/blob/master/ckan-base/2.9/Dockerfile

ENV GIT_BRANCH=2.9

# add dependencies for cryptography and vim
RUN apk add libressl-dev musl-dev libffi-dev xmlsec vim xmlsec-dev openjdk11
# Download Saxon jar for FGDC2ISO transform (geodatagov)
ARG saxon_ver=9.9.1-7
ADD \
  https://repo1.maven.org/maven2/net/sf/saxon/Saxon-HE/${saxon_ver}/Saxon-HE-${saxon_ver}.jar \
  /usr/lib/jvm/java-11-openjdk/saxon/saxon.jar

# Add dependencies for ckanext-spatial and geodatagov
RUN apk add geos-dev proj proj-util proj-dev

COPY requirements.txt ${APP_DIR}

RUN pip3 install --upgrade pip && pip3 install -r requirements.txt --ignore-installed

COPY freeze-requirements.sh /usr/local/bin
COPY docker-entrypoint.d/* /docker-entrypoint.d/

# Not currently in use in development
COPY setup/gunicorn.conf.py ${APP_DIR}/
COPY setup/server_start.sh ${APP_DIR}/

# Custom prerun script for Solr 8
COPY setup/GSA_prerun.py ${APP_DIR}/

COPY saml2 ${APP_DIR}/saml2

# COPY the ini test file to the container 
COPY test-catalog-next.ini ${SRC_DIR}/ckan

# In order for dependencies to be managed, python
# needs to be mapped to python3
RUN ln -s /usr/bin/python3 /usr/bin/python

# In order to run CKAN harvester command to finalize
# harvests, we need to setup a cron for the run command
COPY setup/harvest-check-cron /etc/crontabs/root

# RUN sudo -u ckan -EH pip3 install git+https://github.com/nickumia-reisys/werkzeug@e1f6527604ab30e4b46b5430a5fb97e7a7055cd7#egg=werkzeug
