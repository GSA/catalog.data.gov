FROM maven:3-jdk-11 as java

FROM python:3.8

# Install Dependencies
# - Download Saxon jar for FGDC2ISO transform (geodatagov)
# - Various Linux Packages
#     (dependencies for cryptography and vim and ckanext-spatial and geodatagov)
ENV JAVA_HOME=/usr/local/openjdk-11
COPY --from=java $JAVA_HOME $JAVA_HOME
RUN echo PATH=$PATH:$HOME/bin:$JAVA_HOME/bin >> /etc/profile
ARG saxon_ver=9.9.1-7
ADD \
  https://repo1.maven.org/maven2/net/sf/saxon/Saxon-HE/${saxon_ver}/Saxon-HE-${saxon_ver}.jar \
  /usr/lib/jvm/java-11-openjdk/saxon/saxon.jar

RUN apt-get update -y && \
  apt-get install -y \
    openssl libssl-dev libffi-dev pkg-config libxml2-dev libxmlsec1-dev libxmlsec1-openssl \
    vim zip libgeos-dev proj-bin cron

COPY requirements.txt ${APP_DIR}
RUN pip3 install --upgrade pip && pip3 install -r requirements.txt --ignore-installed

COPY freeze-requirements.sh /usr/local/bin
COPY docker-entrypoint.d/* /docker-entrypoint.d/


# CKAN Setup Files
RUN mkdir -p /srv/app && mkdir -p /var/lib/ckan
ENV APP_DIR=/srv/app
ENV SRC_DIR=/srv/app/src
ENV CKAN_INI=${APP_DIR}/ckan.ini
ENV PIP_SRC=${SRC_DIR}
ENV CKAN_STORAGE_PATH=/var/lib/ckan

COPY setup/GSA_prerun.py ${APP_DIR}/
COPY setup/ckan.ini ${APP_DIR}/
COPY setup/who.ini ${APP_DIR}/
COPY saml2 ${APP_DIR}/saml2
# Reference upstream prerun.py
# NOTE: This is subject to break in the future
RUN wget -O /srv/app/prerun.py https://raw.githubusercontent.com/okfn/docker-ckan/f5f9d7c2988008b192c6d6085cc83062d0bfedcb/ckan-base/2.9/setup/prerun.py

# Install dev dependencies
RUN pip3 install flask_debugtoolbar

# In order for dependencies to be managed, python
# needs to be mapped to python3
RUN ln -s /usr/bin/python3 /usr/bin/python
