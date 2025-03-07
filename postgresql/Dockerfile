FROM postgis/postgis:15-3.4-alpine

# Customize default user/pass/db
ENV POSTGRES_DB ckan
ENV POSTGRES_USER ckan
ARG POSTGRES_PASSWORD
ARG DATASTORE_READONLY_PASSWORD


# Include extra setup scripts (eg datastore)
ADD docker-entrypoint-initdb.d /docker-entrypoint-initdb.d
ADD https://github.com/GSA/datagov-deploy/raw/71936f004be1882a506362670b82c710c64ef796/ansible/roles/software/ec2/ansible/files/locations.sql.gz /docker-entrypoint-initdb.d/locations.sql.gz
RUN chmod 666 /docker-entrypoint-initdb.d/locations.sql.gz
