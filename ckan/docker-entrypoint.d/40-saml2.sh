echo "looking for saml2auth at: $CKAN__PLUGINS"

if [[ "$CKAN__PLUGINS" == *"saml2auth"* ]]
then
    echo "ENABLING SAML2"
    export CKAN_SITE_URL="https://localhost:8443"
    export CKANEXT__SAML2AUTH__ENABLE_CKAN_INTERNAL_LOGIN=false
else
    echo "NOT ENABLING SAML2"
fi