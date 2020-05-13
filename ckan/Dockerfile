FROM openknowledge/ckan-dev:2.8
# Inherit from here: https://github.com/okfn/docker-ckan/blob/master/ckan-dev/2.8/Dockerfile
# And then from here: https://github.com/okfn/docker-ckan/blob/master/ckan-base/2.8/Dockerfile

MAINTAINER Your Name Here <you@example.com>

# Set timezone
ARG TZ
RUN cp /usr/share/zoneinfo/$TZ /etc/localtime
RUN echo $TZ > /etc/timezone

# Fix shapely lib error to install shapely
# TODO consider moving to Alpine>=3.11 or to Bionic
RUN echo "@edge http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories
RUN echo "@edge-testing http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

RUN apk update && \
  apk add --update --force-overwrite "geos-dev@edge-testing" && \
  rm -rf /var/cache/apk/*

COPY requirements.txt ${APP_DIR}

RUN pip install -r requirements.txt
