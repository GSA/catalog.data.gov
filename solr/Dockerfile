FROM solr:8.11-slim
MAINTAINER Open Knowledge

USER root

#######################
## GSA Specific Changes (also need root user)
#######################

# Add curl to access API routes
RUN apt-get update && apt-get install -y curl vim stunnel4 git

# Install EFS Dependencies
RUN git clone --depth 1 --branch v2.1.0 https://github.com/aws/efs-utils && \
  cd efs-utils && \
  apt-get -y install binutils rustc cargo pkg-config libssl-dev && \
  ./build-deb.sh && \
  apt-get -y install ./build/amazon-efs-utils*deb

# Install hostname resolution dependencies
RUN apt-get install -y dnsutils

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


# Giving ownership to user 'solr'
RUN mkdir -p /opt/solr/server/solr/$SOLR_CORE/data/index
RUN chown -R $SOLR_USER:$SOLR_USER /opt/solr/server/solr/

# Leave user as 'root' since we need to mount EFS volume which requires root
# The user will be set back to 'solr' before solr is started
# Starting Solr can be done with something like...
# su -c "init-var-solr; precreate-core ckan /tmp/ckan_config; chown -R 8983:8983 /var/solr/data; solr-fg -m <ram>" -m solr

# CMD ["sh", "-c", "solr-precreate ckan $SOLR_CONFIG_DIR/ckan"]
