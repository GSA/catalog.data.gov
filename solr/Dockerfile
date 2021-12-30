FROM solr:8.11-slim
MAINTAINER Open Knowledge


########################
## CKAN Specific Changes
## Pulled from https://github.com/ckan/ckan-solr/blob/master/solr-8/Dockerfile
########################

EXPOSE 8983

ENV SOLR_CORE ckan
ARG CKAN_BRANCH="dev-v2.9"

ENV SOLR_CONFIG_DIR="/opt/solr/server/solr/configsets"
ENV SOLR_SCHEMA_FILE="$SOLR_CONFIG_DIR/ckan/conf/managed-schema"

# Set user to root for initial configuration
USER root

# Create a CKAN configset by copying the default one
RUN cp -R $SOLR_CONFIG_DIR/_default $SOLR_CONFIG_DIR/ckan

# Update the schema
ADD https://raw.githubusercontent.com/ckan/ckan/$CKAN_BRANCH/ckan/config/solr/schema.xml $SOLR_SCHEMA_FILE
RUN chmod 644 $SOLR_SCHEMA_FILE


#######################
## GSA Specific Changes (also need root user)
#######################

# Add curl to access API routes
RUN apt-get update && apt-get install -y curl

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
#   'chosen.jquery', 'jquery.cookie', 'jquery.blockui', 'jquery.timeago',
#   'jquery.sammy', 'jquery.ajaxfileupload' NO known vulnerabilities
#   'jquery.form' ALL versions vulnerable -- https://snyk.io/vuln/npm:jquery-form
# 'jquery.min.js' is used in two place (1x each), but it's easier to keep the
# old name than to do an in-place string replacement with perl like below
ADD https://cdnjs.cloudflare.com/ajax/libs/jquery/3.6.0/jquery.min.js \
/opt/solr/server/solr-webapp/webapp/libs/jquery-3.6.0.min.js
ADD https://cdnjs.cloudflare.com/ajax/libs/jquery/3.6.0/jquery.min.js \
/opt/solr/server/solr-webapp/webapp/js/lib/jquery-3.6.0.min.js
# https://snyk.io/vuln/npm:jstree
ADD https://cdnjs.cloudflare.com/ajax/libs/jstree/3.3.11/jstree.min.js \
/opt/solr/server/solr-webapp/webapp/libs/jquery.jstree.js
ADD https://cdnjs.cloudflare.com/ajax/libs/jstree/3.3.11/jstree.min.js \
/opt/solr/server/solr-webapp/webapp/js/lib/jquery.jstree.js
# Make sure user 'solr' owns and has permissions for the new libraries
RUN chmod -R 644 /opt/solr/server/solr-webapp/webapp/libs/*.js
RUN chmod -R 644 /opt/solr/server/solr-webapp/webapp/js/lib/*.js
RUN chown -R $SOLR_USER:$SOLR_USER /opt/solr/server/solr-webapp/webapp/
# Update references to jquery
RUN sed -i 's/jquery-2.1.3.min.js/jquery-3.6.0.min.js/' \
    /opt/solr/server/solr-webapp/webapp/index.html
RUN sed -i 's/jquery-1.7.2.min.js/jquery-3.6.0.min.js/' \
    /opt/solr/example/files/conf/velocity/head.vm
RUN sed -i 's/jquery-1.7.2.min.js/jquery-3.6.0.min.js/' \
    /opt/solr/server/solr/configsets/sample_techproducts_configs/conf/velocity/head.vm


# Fix Issue https://github.com/GSA/datagov-deploy/issues/3283
# Disable directory listing
RUN perl -0777  -i -pe 's/ \
    <param-name>dirAllowed<\/param-name>\n.*<param-value>true<\/param-value>/ \
    <param-name>dirAllowed<\/param-name>\n      <param-value>false<\/param-value>/igs' \
    /opt/solr/server/etc/webdefault.xml


# Incorporate Fix from https://stackoverflow.com/a/31320697
ADD solrconfig.xml $SOLR_CONFIG_DIR/ckan/conf/solrconfig.xml

# Fim from https://github.com/ckan/ckan/issues/5585#issuecomment-953586246
RUN sed -i "s/<defaultSearchField>text<\/defaultSearchField>/<df>text<\/df>/" $SOLR_SCHEMA_FILE
RUN sed -i "s/<solrQueryParser defaultOperator=\"AND\"\/>/<solrQueryParser q.op=\"AND\"\/>/" $SOLR_SCHEMA_FILE

# Giving ownership to user 'solr'
RUN mkdir -p /opt/solr/server/solr/$SOLR_CORE/data/index
RUN chown -R $SOLR_USER:$SOLR_USER /opt/solr/server/solr/
# 
# Set user to 'solr' for to comply with solr security
USER solr

CMD ["sh", "-c", "solr-precreate ckan $SOLR_CONFIG_DIR/ckan"]
