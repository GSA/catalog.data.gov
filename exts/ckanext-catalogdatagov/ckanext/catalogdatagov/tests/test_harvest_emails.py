from mock import patch
from nose.tools import assert_equal

from ckantoolkit.tests import factories as ckan_factories
from ckantoolkit.tests.helpers import reset_db, FunctionalTestBase

from ckan import plugins as p
from ckan.plugins import toolkit
from ckan import model

import ckanext.harvest.model as harvest_model
from ckanext.harvest.model import HarvestGatherError, HarvestObjectError, HarvestObject, HarvestJob
from ckanext.harvest.logic import HarvestJobExists
from ckanext.harvest.logic.action.update import send_error_mail


class TestHarvestErrorMail(FunctionalTestBase):
    @classmethod
    def setup_class(cls):
        super(TestHarvestErrorMail, cls).setup_class()
        reset_db()
        harvest_model.setup()

    @classmethod
    def teardown_class(cls):
        super(TestHarvestErrorMail, cls).teardown_class()
        reset_db()

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
            'source_type': 'test-nose',
        }

        try:
            harvest_source = toolkit.get_action('harvest_source_create')(
                context,
                source_dict
            )
        except toolkit.ValidationError:
            harvest_source = toolkit.get_action('harvest_source_show')(
                context,
                {'id': source_dict['name']}
            )
            pass

        try:
            job = toolkit.get_action('harvest_job_create')(context, {
                'source_id': harvest_source['id'], 'run': True})
        except HarvestJobExists:
            job = toolkit.get_action('harvest_job_show')(context, {
                'id': harvest_source['status']['last_job']['id']})
            pass

        toolkit.get_action('harvest_jobs_run')(context, {})
        toolkit.get_action('harvest_source_reindex')(context, {'id': harvest_source['id']})
        return context, harvest_source, job

    def _create_harvest_source_with_owner_org_and_job_if_not_existing(self):
        site_user = toolkit.get_action('get_site_user')(
            {'model': model, 'ignore_auth': True}, {})['name']

        context = {
            'user': site_user,
            'model': model,
            'session': model.Session,
            'ignore_auth': True,
        }

        test_org = ckan_factories.Organization()
        test_other_org = ckan_factories.Organization()
        org_admin_user = ckan_factories.User()
        org_member_user = ckan_factories.User()
        other_org_admin_user = ckan_factories.User()

        toolkit.get_action('organization_member_create')(
            context.copy(),
            {
                'id': test_org['id'],
                'username': org_admin_user['name'],
                'role': 'admin'
            }
        )

        toolkit.get_action('organization_member_create')(
            context.copy(),
            {
                'id': test_org['id'],
                'username': org_member_user['name'],
                'role': 'member'
            }
        )

        toolkit.get_action('organization_member_create')(
            context.copy(),
            {
                'id': test_other_org['id'],
                'username': other_org_admin_user['name'],
                'role': 'admin'
            }
        )

        source_dict = {
            'title': 'Test Source',
            'name': 'test-source',
            'url': 'basic_test',
            'source_type': 'test-nose',
            'owner_org': test_org['id'],
            'run': True
        }

        try:
            harvest_source = toolkit.get_action('harvest_source_create')(
                context.copy(),
                source_dict
            )
        except toolkit.ValidationError:
            harvest_source = toolkit.get_action('harvest_source_show')(
                context.copy(),
                {'id': source_dict['name']}
            )
            pass

        try:
            job = toolkit.get_action('harvest_job_create')(context.copy(), {
                'source_id': harvest_source['id'], 'run': True})
        except HarvestJobExists:
            job = toolkit.get_action('harvest_job_show')(context.copy(), {
                'id': harvest_source['status']['last_job']['id']})
            pass

        toolkit.get_action('harvest_jobs_run')(context.copy(), {})
        toolkit.get_action('harvest_source_reindex')(context.copy(), {'id': harvest_source['id']})
        return context, harvest_source, job

    @patch('ckan.lib.mailer.mail_recipient')
    def test_error_mail_not_sent(self, mock_mailer_mail_recipient):
        context, harvest_source, job = self._create_harvest_source_and_job_if_not_existing()

        status = toolkit.get_action('harvest_source_show_status')(context, {'id': harvest_source['id']})

        send_error_mail(
            context,
            harvest_source['id'],
            status
        )
        assert_equal(0, status['last_job']['stats']['errored'])
        assert mock_mailer_mail_recipient.not_called

    @patch('ckan.lib.mailer.mail_recipient')
    def test_error_mail_sent(self, mock_mailer_mail_recipient):
        context, harvest_source, job = self._create_harvest_source_and_job_if_not_existing()

        # create a HarvestGatherError
        job_model = HarvestJob.get(job['id'])
        msg = 'System error - No harvester could be found for source type %s' % job_model.source.type
        err = HarvestGatherError(message=msg, job=job_model)
        err.save()

        status = toolkit.get_action('harvest_source_show_status')(context, {'id': harvest_source['id']})

        send_error_mail(
            context,
            harvest_source['id'],
            status
        )

        assert_equal(1, status['last_job']['stats']['errored'])
        assert mock_mailer_mail_recipient.called

    @patch('ckan.lib.mailer.mail_recipient')
    def test_error_mail_sent_with_object_error(self, mock_mailer_mail_recipient):

        context, harvest_source, harvest_job = self._create_harvest_source_and_job_if_not_existing()

        data_dict = {
            'guid': 'guid',
            'content': 'content',
            'job_id': harvest_job['id'],
            'extras': {'a key': 'a value'},
            'source_id': harvest_source['id']
        }
        harvest_object = toolkit.get_action('harvest_object_create')(
            context, data_dict)

        harvest_object_model = HarvestObject.get(harvest_object['id'])

        # create a HarvestObjectError
        msg = 'HarvestObjectError occured: %s' % harvest_job['id']
        harvest_object_error = HarvestObjectError(message=msg, object=harvest_object_model)
        harvest_object_error.save()

        status = toolkit.get_action('harvest_source_show_status')(context, {'id': harvest_source['id']})

        send_error_mail(
            context,
            harvest_source['id'],
            status
        )

        assert_equal(1, status['last_job']['stats']['errored'])
        assert mock_mailer_mail_recipient.called

    @patch('ckan.lib.mailer.mail_recipient')
    def test_error_mail_sent_with_org(self, mock_mailer_mail_recipient):
        context, harvest_source, job = self._create_harvest_source_with_owner_org_and_job_if_not_existing()

        # create a HarvestGatherError
        job_model = HarvestJob.get(job['id'])
        msg = 'System error - No harvester could be found for source type %s' % job_model.source.type
        err = HarvestGatherError(message=msg, job=job_model)
        err.save()

        status = toolkit.get_action('harvest_source_show_status')(context, {'id': harvest_source['id']})

        send_error_mail(
            context,
            harvest_source['id'],
            status
        )

        assert_equal(1, status['last_job']['stats']['errored'])
        assert mock_mailer_mail_recipient.called
        assert_equal(2, mock_mailer_mail_recipient.call_count)