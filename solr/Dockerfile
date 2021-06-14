FROM solr:6.6.6-slim
MAINTAINER Open Knowledge

# Enviroment
ENV SOLR_CORE ckan
ENV CKAN_VERSION dev-v2.7

# Set user to root for initial configuration
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

# Fix Issue https://github.com/GSA/datagov-deploy/issues/3285
# Update the angularjs library files
ADD https://cdnjs.cloudflare.com/ajax/libs/angular.js/1.8.2/angular.min.js \
https://cdnjs.cloudflare.com/ajax/libs/angular.js/1.8.2/angular.js \
https://cdnjs.cloudflare.com/ajax/libs/angular-route/1.8.2/angular-route.js \
https://cdnjs.cloudflare.com/ajax/libs/angular-route/1.8.2/angular-route.min.js \
https://cdnjs.cloudflare.com/ajax/libs/angular-sanitize/1.8.2/angular-sanitize.js \
https://cdnjs.cloudflare.com/ajax/libs/angular-sanitize/1.8.2/angular-sanitize.min.js \
https://cdnjs.cloudflare.com/ajax/libs/angular-cookies/1.8.2/angular-cookies.js \
https://cdnjs.cloudflare.com/ajax/libs/angular-cookies/1.8.2/angular-cookies.min.js \
https://cdnjs.cloudflare.com/ajax/libs/angular-resource/1.8.2/angular-resource.min.js \
/opt/solr/server/solr-webapp/webapp/libs/

# Fix Issue 
# Update jQuery library files
# 'chosen.jquery', 'jquery.cookie', 'jquery.blockui', 'jquery.timeago',
# 'jquery.sammy', 'jquery.ajaxfileupload' NO known vulnerabilities
# 'jquery.form' ALL versions vulnerable -- https://snyk.io/vuln/npm:jquery-form
# 'jquery.min.js' is used in two place (1x each), but it's easier to keep the
# old name than to do an in-place string replacement with perl like below
ADD https://cdnjs.cloudflare.com/ajax/libs/jquery/3.6.0/jquery.min.js \
/opt/solr/server/solr-webapp/webapp/libs/jquery-2.1.3.min.js
ADD https://cdnjs.cloudflare.com/ajax/libs/jquery/3.6.0/jquery.min.js \
/opt/solr/server/solr-webapp/webapp/js/lib/jquery-1.7.2.min.js
# https://snyk.io/vuln/npm:jstree
ADD https://cdnjs.cloudflare.com/ajax/libs/jstree/3.3.11/jstree.min.js \
/opt/solr/server/solr-webapp/webapp/libs/jquery.jstree.js
ADD https://cdnjs.cloudflare.com/ajax/libs/jstree/3.3.11/jstree.min.js \
/opt/solr/server/solr-webapp/webapp/js/lib/jquery.jstree.js

# Fix Issue https://github.com/GSA/datagov-deploy/issues/3283
# Disable directory listing
RUN perl -0777  -i -pe 's/ \
    <param-name>dirAllowed<\/param-name>\n.*<param-value>true<\/param-value>/ \
    <param-name>dirAllowed<\/param-name>\n      <param-value>false<\/param-value>/igs' \
    /opt/solr/server/etc/webdefault.xml

# Create Core.properties
RUN echo name=$SOLR_CORE > /opt/solr/server/solr/$SOLR_CORE/core.properties

# Giving ownership to Solr
RUN mkdir /opt/solr/server/solr/$SOLR_CORE/data/index
RUN chown -R $SOLR_USER:$SOLR_USER /opt/solr/server/solr/

# Set user to 'solr' for to comply with solr security
USER solr
