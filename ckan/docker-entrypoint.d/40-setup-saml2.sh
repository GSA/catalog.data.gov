if [[ "$CKAN__PLUGINS" == *"saml2"* ]]; then
    echo "Setup ckanext-saml2"
    paster --plugin=ckanext-saml2 saml2 create --config=$CKAN_INI
else
    echo "Skipping saml2 initialization"
fi
