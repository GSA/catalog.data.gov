#!/bin/bash

# write usage
function usage {
  echo "Usage: $0 catalog_app_name maintenance_mode"
  exit 1
}

if [ $# -ne 2 ] ; then
    usage
fi

# get mode value from maintenance_mode
case "$2" in
    "Scheduled_Maintenance")
        maintenance_mode="MAINTENANCE"
        ;;
    "Unscheduled_Downtime")
        maintenance_mode="DOWN"
        ;;
    "Federal_Shutdown")
        maintenance_mode="FEDERAL-SHUTDOWN"
        ;;
    *)
        maintenance_mode="NORMAL"
        ;;
esac

# set for catalog-web
if [ "$1" == "catalog-web" ] || [ "$1" == "both" ] ; then
    # compare with existing env value, run cf set-env only if it's different or not set
    current_mode=$(cf env catalog-proxy | grep CATALOG_WEB_MODE | awk '{print $2}')
    if [ "$current_mode" != "$maintenance_mode" ] ; then
        cf set-env catalog-proxy CATALOG_WEB_MODE $maintenance_mode
        need_restart=true
    fi
fi

# set for catalog-admin
if [ "$1" == "catalog-admin" ] || [ "$1" == "both" ] ; then
    # compare with existing env value, run cf set-env only if it's different or not set
    current_mode=$(cf env catalog-proxy | grep CATALOG_ADMIN_MODE | awk '{print $2}')
    if [ "$current_mode" != "$maintenance_mode" ] ; then
        cf set-env catalog-proxy CATALOG_ADMIN_MODE $maintenance_mode
        need_restart=true
    fi
fi

# restart catalog-proxy if needed
if [ "$need_restart" == "true" ] ; then
    cf restart catalog-proxy --strategy rolling
fi
