#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

if [ -z "${ENABLE_SAML2:-}" ]; then
  # Nothing to do if SAML2 is not enabled
  return 0
fi

tmp_saml=$(mktemp)

cat <<EOF >> $tmp_saml
who.config_file = %(here)s/saml2/who.ini

## SAML2 Settings
saml2.issuer = urn:gov:gsa:SAML:2.0.profiles:sp:sso:gsa:catalog-dev
saml2.site_url = https://catalog-next.sandbox.datagov.us/
saml2.idp_url = https://idp.int.identitysandbox.gov/api/saml/auth2020
saml2.config_path = %(here)s/saml2

# Needed for login.gov
saml2.name_id_from_saml2_NameID = true

saml2.user_mapping =
  email~email
  fullname~email
  id~uuid
  name~email

saml2.organization_mapping =
  name~field_unique_id
  title~field_organization
  extras:organization_type~field_organization_type
EOF

paster --plugin=ckan config-tool production.ini -f "$tmp_saml"
# paster config-tool doesn't seem to handle multiline configuration. Hack it.
# TODO this is not idempotent and might screw up your config after a stop/start.
sed -i -e '/saml2.user_mapping/ a \
\ \ email~email\
\ \ fullname~email\
\ \ id~uuid\
\ \ name~email' production.ini
sed -i -e '/saml2.organization_mapping/ a \
\ \ name~field_unique_id\
\ \ title~field_organization\
\ \ extras:organization_type~field_organization_type' production.ini

# saml2 can only be enabled _after_ the configuration is set
CKAN__PLUGINS="${CKAN__PLUGINS} saml2"
rm -rf $tmp_saml
