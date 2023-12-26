FROM postgis/postgis:12-3.3-alpine

# Customize default user/pass/db
ENV POSTGRES_DB ckan
ENV POSTGRES_USER ckan
ARG POSTGRES_PASSWORD
ARG DATASTORE_READONLY_PASSWORD


# Include extra setup scripts (eg datastore)
ADD docker-entrypoint-initdb.d /docker-entrypoint-initdb.d
