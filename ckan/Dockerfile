FROM openknowledge/ckan-dev:2.9
# Inherit from here: https://github.com/okfn/docker-ckan/blob/master/ckan-dev/2.9/Dockerfile
# And then from here: https://github.com/okfn/docker-ckan/blob/master/ckan-base/2.9/Dockerfile

ENV GIT_BRANCH=2.9

# add dependencies for cryptography and vim
RUN apk add libressl-dev musl-dev libffi-dev xmlsec vim xmlsec-dev

# Add dependencies for ckanext-spatial and geodatagov
RUN apk add geos-dev proj proj-util proj-dev

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

# In order for dependencies to be managed, python
# needs to be mapped to python3
RUN ln -s /usr/bin/python3 /usr/bin/python

# RUN sudo -u ckan -EH pip3 install git+https://github.com/nickumia-reisys/werkzeug@e1f6527604ab30e4b46b5430a5fb97e7a7055cd7#egg=werkzeug