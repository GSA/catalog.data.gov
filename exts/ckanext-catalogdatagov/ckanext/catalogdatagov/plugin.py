import ckan.plugins as plugins
import ckan.plugins.toolkit as toolkit
from ckanext.catalogdatagov.logic.action.update import harvest_jobs_run


class CatalogdatagovPlugin(plugins.SingletonPlugin):
    plugins.implements(plugins.IConfigurer)
    plugins.implements(plugins.IActions)

    # IConfigurer

    def update_config(self, config_):
        toolkit.add_template_directory(config_, 'templates')
        toolkit.add_public_directory(config_, 'public')
        toolkit.add_resource('fanstatic', 'catalogdatagov')

    # IActions

    def get_actions(self):
        '''
        Define custom functions (or ovveride existing ones).
        Availbale via API /api/action/{action-name}
        '''

        return {
            'harvest_jobs_run': harvest_jobs_run
        }
