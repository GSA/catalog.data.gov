FROM python:3.8

# Install Dependencies
# - Download Saxon jar for FGDC2ISO transform (geodatagov)
# - Various Linux Packages
#     (dependencies for cryptography and vim and ckanext-spatial and geodatagov)

RUN apt-get update -y && \
  apt-get install -y \
    openssl libssl-dev libffi-dev pkg-config libxml2-dev libxmlsec1-dev libxmlsec1-openssl \
    vim zip libgeos-dev proj-bin cron default-jre

ARG saxon_ver=9.9.1-7
ADD \
  https://repo1.maven.org/maven2/net/sf/saxon/Saxon-HE/${saxon_ver}/Saxon-HE-${saxon_ver}.jar \
  $JAVA_HOME/saxon/saxon.jar
ENV CLASSPATH=$JAVA_HOME/saxon/saxon.jar

COPY requirements.txt ${APP_DIR}
RUN pip3 install --upgrade pip && pip3 install -r requirements.txt --ignore-installed

COPY freeze-requirements.sh /usr/local/bin
COPY docker-entrypoint.d/* /docker-entrypoint.d/


# CKAN Setup Variables
ENV APP_DIR=/srv/app
ENV SRC_DIR=/srv/app/src
ENV SRC_EXTENSIONS_DIR=/srv/app/src_extensions
ENV CKAN_INI=${APP_DIR}/ckan.ini
ENV PIP_SRC=${SRC_DIR}
ENV CKAN_STORAGE_PATH=/var/lib/ckan
RUN mkdir -p $CKAN_STORAGE_PATH $APP_DIR $SRC_EXTENSIONS_DIR

# CKAN Setup Files
# Our production ckan.ini messes with local login
# (so we need to generate a new one)
COPY setup/prerun.py ${APP_DIR}/
RUN ckan generate config ${CKAN_INI}
COPY setup/who.ini ${APP_DIR}/
COPY saml2 ${APP_DIR}/saml2

# Install dev dependencies
RUN pip3 install flask_debugtoolbar

# In order for dependencies to be managed, python
# needs to be mapped to python3
RUN ln -s /usr/bin/python3 /usr/bin/python
