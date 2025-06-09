#!/bin/sh

set -e 

# If an argument was provided, use it as the service name prefix. 
# Otherwise default to "catalog".
app_name=${1:-catalog}

# Get the current space and trim leading whitespace
space=$(cf target | grep space | cut -d : -f 2 | xargs)

# Production and staging should use bigger DB and Redis instances
if [ "$space" = "prod" ] || [ "$space" = "staging" ]; then
    cf service "${app_name}-db"    > /dev/null 2>&1 || cf create-service aws-rds medium-psql-redundant "${app_name}-db"                 --wait&
    cf service "${app_name}-redis" > /dev/null 2>&1 || cf create-service aws-elasticache-redis redis-3node "${app_name}-redis"  --wait&
else
    cf service "${app_name}-db"    > /dev/null 2>&1 || cf create-service aws-rds small-psql "${app_name}-db"                    --wait&
    cf service "${app_name}-redis" > /dev/null 2>&1 || cf create-service aws-elasticache-redis redis-dev "${app_name}-redis"    --wait&
fi

# TODO: update if and when the service broker reverts to `ssb-solr-gsa-datagov-<space>`
cf service "${app_name}-solr"      > /dev/null 2>&1 || cf create-service solr-on-ecs base "${app_name}-solr" -c solr/service-config-${space}.json -b "ssb-solrcloud-gsa-datagov-${space}" --wait&

# Wait until all the services are ready
wait

# Check that all the services are in a healthy state. (The OSBAPI spec says that
# the "last operation" should include "succeeded".)
success=0;
for service in "${app_name}-db" "${app_name}-redis" "${app_name}-solr" 
do
    status=$(cf service "$service" | grep 'status:\s*.\+$' )
    echo "$service $status"
    if ! echo "$status" | grep -q 'succeeded' ; then
        success=1;
    fi
done
exit $success
