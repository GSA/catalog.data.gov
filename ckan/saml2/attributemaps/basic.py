import six
from ckan.common import config


def get_map_from_settings():
    """ Get custom settings from CKAN config
        e.g. 
         - ckanext.saml2auth.attribute_map.fro.urn:mace:dir:attribute-def:aRecord = aRecord
         - ckanext.saml2auth.attribute_map.fro.urn:mace:dir:attribute-def:aliasedEntryName = aRealiasedEntryNamecord
         
         - ckanext.saml2auth.attribute_map.to.aRecord = urn:mace:dir:attribute-def:aRecord
         - ckanext.saml2auth.attribute_map.to.aliasedEntryName = urn:mace:dir:attribute-def:aliasedEntryName
         """

    res = {
        "identifier": "urn:oasis:names:tc:SAML:2.0:attrname-format:basic",
        "fro": {},
        "to": {}
    }

    for k, v in six.iteritems(config):
        if k.startswith('ckanext.saml2auth.attribute_map.fro.'):
            key = k.replace('ckanext.saml2auth.attribute_map.fro.', '')
            res['fro'][key] = v
        elif k.startswith('ckanext.saml2auth.attribute_map.to.'):
            key = k.replace('ckanext.saml2auth.attribute_map.to.', '')
            res['to'][key] = v

    return res

MAP = get_map_from_settings()
