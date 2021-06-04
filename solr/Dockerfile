FROM solr:6.6.6
#FROM solr:6.2-alpine
MAINTAINER Open Knowledge

# Enviroment
ENV SOLR_CORE ckan
ENV CKAN_VERSION dev-v2.7

# Change permissions for Solr user
USER root

# Create Directories
RUN mkdir -p /opt/solr/server/solr/$SOLR_CORE/conf
RUN mkdir -p /opt/solr/server/solr/$SOLR_CORE/data

# Adding Files
ADD solrconfig.xml \
schema.xml \
https://raw.githubusercontent.com/apache/lucene-solr/releases/lucene-solr/6.6.6/solr/server/solr/configsets/basic_configs/conf/currency.xml \
https://raw.githubusercontent.com/apache/lucene-solr/releases/lucene-solr/6.6.6/solr/server/solr/configsets/basic_configs/conf/synonyms.txt \
https://raw.githubusercontent.com/apache/lucene-solr/releases/lucene-solr/6.6.6/solr/server/solr/configsets/basic_configs/conf/stopwords.txt \
https://raw.githubusercontent.com/apache/lucene-solr/releases/lucene-solr/6.6.6/solr/server/solr/configsets/basic_configs/conf/protwords.txt \
https://raw.githubusercontent.com/apache/lucene-solr/releases/lucene-solr/6.6.6/solr/server/solr/configsets/data_driven_schema_configs/conf/elevate.xml \
/opt/solr/server/solr/$SOLR_CORE/conf/

# Create Core.properties
RUN echo name=$SOLR_CORE > /opt/solr/server/solr/$SOLR_CORE/core.properties

# Override running Solr as root
#ADD solr /opt/solr/bin/solr
#ADD start-local-solr /opt/docker-solr/scripts/start-local-solr
#ADD infinite.sh /opt/solr

# Giving ownership to Solr
RUN chown -R $SOLR_USER:$SOLR_USER /opt/solr/server/solr/$SOLR_CORE

#CMD ["bash", "/opt/solr/infinite.sh"]
RUN mkdir /opt/solr/server/solr/ckan/data/index && chown -R $SOLR_USER:$SOLR_USER /opt/solr/server/solr/ckan/data/index
USER solr
