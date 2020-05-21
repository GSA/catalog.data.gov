import logging
from mock import patch
from nose.tools import assert_equal

from ckantoolkit.tests import factories as ckan_factories
from ckantoolkit.tests.helpers import reset_db, FunctionalTestBase

from ckan import plugins as p
from ckan.plugins import toolkit
from ckan import model
from ckan.lib.base import config

import ckanext.harvest.model as harvest_model
from ckanext.harvest.model import HarvestGatherError, HarvestObjectError, HarvestObject, HarvestJob
from ckanext.harvest.logic import HarvestJobExists
from ckanext.harvest.logic.action.update import send_error_mail
# from ckanext.catalogdatagov.logic.action.update import harvest_jobs_run


logger = logging.getLogger(__name__)


class TestNotifications:

    @patch('ckan.lib.mailer.mail_recipient')
    def test_error_mail_not_sent(self, mock_mailer_mail_recipient):

        config['ckan.harvest.mq.type'] = 'redis'
        config['ckan.harvest.mq.hostname'] = 'redis'
        config['ckan.harvest.mq.port'] = 6379
        config['ckan.harvest.mq.redis_db'] = 1
        config['ckan.harvest.log_level'] = 'info'
        config['ckan.harvest.log_scope'] = 0
        config['ckan.harvest.email'] = 'on'

        logger.info('Test error mail not sent')
        context, harvest_source, job = self._create_harvest_source_and_job_if_not_existing()

        status = toolkit.get_action('harvest_source_show_status')(context, {'id': harvest_source['id']})

        send_error_mail(
            context,
            harvest_source['id'],
            status
        )
        # validate that even if there is no error, 
        assert_equal(0, status['last_job']['stats']['errored'])
        # ... the email is being sent anyway
        assert mock_mailer_mail_recipient.called

    @classmethod
    def setup_class(cls):
        
        if not p.plugin_loaded('harvest'):
            logger.info("Loading harvest plugin")
            p.load('harvest')
            p.load('datajson')
            p.load('ckan_harvester')
            p.load('catalogdatagov')
        
    @classmethod
    def teardown_class(cls):

        logger.info("Unloading plugin")
        p.unload('harvest')
        p.unload('datajson')
        p.unload('ckan_harvester')
        p.unload('catalogdatagov')

    def _create_harvest_source_and_job_if_not_existing(self):
        site_user = toolkit.get_action('get_site_user')(
            {'model': model, 'ignore_auth': True}, {})['name']

        context = {
            'user': site_user,
            'model': model,
            'session': model.Session,
            'ignore_auth': True,
        }
        source_dict = {
            'title': 'Test Source',
            'name': 'test-source',
            'url': 'basic_test',
            'source_type': 'ckan',
        }

        try:
            create = toolkit.get_action('harvest_source_create')
            harvest_source = create(context, source_dict)
        except toolkit.ValidationError:
            show = toolkit.get_action('harvest_source_show')
            harvest_source = show(context, {'id': source_dict['name']})
            pass

        try:
            job = toolkit.get_action('harvest_job_create')(context, {
                'source_id': harvest_source['id'], 'run': True})
        except HarvestJobExists:
            job = toolkit.get_action('harvest_job_show')(context, {
                'id': harvest_source['status']['last_job']['id']})
            pass

        harvest_jobs_run = toolkit.get_action('harvest_jobs_run') 
        harvest_jobs_run(context, {})

        harvest_source_reindex = toolkit.get_action('harvest_source_reindex')
        harvest_source_reindex(context, {'id': harvest_source['id']})

        return context, harvest_source, job
    