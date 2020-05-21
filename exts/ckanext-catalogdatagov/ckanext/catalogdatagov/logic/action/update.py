import datetime
import json
import logging
from sqlalchemy import exc

from ckanext.harvest.logic.action.update import (
    _make_scheduled_jobs, harvest_job_list, HarvestJob,
    HarvestObject, resubmit_jobs, resubmit_objects, and_,
    toolkit, get_action, config, get_gather_publisher,
    PackageSearchIndex, harvest_job_dictize, logic)
from ckan.logic import chained_action
from ckan.plugins.toolkit import check_access
from ckan.lib.mailer import mail_recipient


log = logging.getLogger(__name__)


@chained_action
def harvest_jobs_run(up_func, context, data_dict):
    log.info('Harvest job run: %r', data_dict)
    check_access('harvest_jobs_run', context, data_dict)

    model = context['model']
    session = context['session']

    source_id = data_dict.get('source_id')

    if not source_id:
        _make_scheduled_jobs(context, data_dict)

    context['return_objects'] = False

    # Not sure if this is needed
    # set_harvest_system_info(
    #     context, 'last_run_time', datetime.datetime.utcnow())

    # Flag finished jobs as such
    jobs = harvest_job_list(
        context, {'source_id': source_id, 'status': u'Running'})

    if len(jobs):
        log.info('Job found')        

        package_index = PackageSearchIndex()

        for job in jobs:
            log.info('Job info {}'.format(job))
            if job['gather_finished']:
                log.info('Job finished')
                objects = session.query(HarvestObject.id) \
                    .filter(HarvestObject.harvest_job_id == job['id']) \
                    .filter(and_(
                            (HarvestObject.state != u'COMPLETE'),
                            (HarvestObject.state != u'ERROR'),
                            (HarvestObject.state != u'STUCK')
                            )) \
                    .order_by(HarvestObject.import_finished.desc())

                if objects.count() == 0:
                    log.info('0 Objects')
                    msg = ''  # message to be emailed for fixed packages
                    job_obj = HarvestJob.get(job['id'])

                    # look for packages with no current harvest objects
                    # and relink them by marking last complete harvest object
                    # current
                    pkgs_no_current = set()
                    sql = '''
                        WITH temp_ho AS (
                          SELECT DISTINCT package_id
                                  FROM harvest_object
                                  WHERE current
                        )
                        SELECT DISTINCT harvest_object.package_id
                        FROM harvest_object
                        LEFT JOIN temp_ho
                        ON harvest_object.package_id = temp_ho.package_id
                        JOIN package
                        ON harvest_object.package_id = package.id
                        WHERE
                            package.state = 'active'
                        AND
                            temp_ho.package_id IS NULL
                        AND
                            harvest_object.state = 'COMPLETE'
                        AND
                            harvest_object.harvest_source_id = :harvest_source_id
                        '''
                    results = model.Session.execute(
                        sql, {'harvest_source_id': job_obj.source_id})

                    for row in results:
                        pkgs_no_current.add(row['package_id'])

                    if len(pkgs_no_current) > 0:
                        log_message = '%s packages to be relinked for ' \
                                'source %s' % (len(pkgs_no_current),
                                               job_obj.source_id)
                        msg += log_message + '\n'
                        log.info(log_message)

                    # set last complete harvest object to be current
                    sql = '''
                        UPDATE harvest_object
                        SET current = 't'
                        WHERE
                            package_id = :id
                        AND
                            state = 'COMPLETE'
                        AND
                            import_finished = (
                                SELECT MAX(import_finished)
                                FROM harvest_object
                                WHERE
                                    state = 'COMPLETE'
                                AND
                                    package_id = :id
                            )
                        RETURNING 1
                    '''

                    for id in pkgs_no_current:
                        result = model.Session.execute(
                            sql, {'id': id}).fetchall()
                        model.Session.commit()

                        if result:
                            search.rebuild(id)
                            log_message = '%s relinked' % id
                            msg += log_message + '\n'
                            log.info(log_message)
                        else:
                            log_message = '%s has no valid harvest object.' % id
                            msg += log_message + '\n'
                            log.info(log_message)

                    # look for packages with no harvest object and remove them
                    pkgs_no_harvest_object = set()
                    source_dataset = model.Package.get(job_obj.source_id)
                    owner_org = source_dataset.owner_org
                    sql = '''
                        SELECT package.id
                        FROM package
                        LEFT JOIN harvest_object
                        ON package.id = harvest_object.package_id
                        LEFT JOIN package_extra
                        ON package.id = package_extra.package_id
                        AND package_extra.key = 'metadata-source'
                        AND package_extra.value = 'dms'
                        WHERE
                            harvest_object.package_id is null
                        AND
                            package_extra.package_id is null
                        AND
                            package.type='dataset'
                        AND
                            package.state='active'
                        AND
                            package.owner_org=:owner_org
                    '''
                    results = model.Session.execute(
                        sql, {'owner_org': owner_org})

                    for row in results:
                        pkgs_no_harvest_object.add(row['id'])

                    if len(pkgs_no_harvest_object) > 0:
                        log_message = '%s packages to be removed for source %s' % (
                                len(pkgs_no_harvest_object),
                                job_obj.source_id
                        )
                        msg += log_message + '\n'
                        log.info(log_message)

                    for id in pkgs_no_harvest_object:
                        try:
                            logic.get_action(
                                'package_delete')(context, {"id": id})
                        except Exception, e:
                            log_message = 'Error deleting %s' % id
                            msg += log_message + '\n'
                            log.info(log_message)
                        else:
                            log_message = '%s removed' % id
                            msg += log_message + '\n'
                            log.info(log_message)

                    # email a list of fixed packages
                    if msg:
                        email_address = config.get('email_to')
                        email = {'recipient_name': email_address,
                                 'recipient_email': email_address,
                                 'subject': 'Packages fixed ' +
                                            str(datetime.datetime.now()),
                                 'body': msg,
                                 }
                        try:
                            mail_recipient(**email)
                        except Exception, e:
                            log.error('Error: %s; email: %s' % (e, email))

                    # finally we can call this job finished
                    job_obj.status = u'Finished'
                    last_object = session.query(HarvestObject) \
                        .filter(HarvestObject.harvest_job_id == job['id']) \
                        .filter(HarvestObject.import_finished != None) \
                        .order_by(HarvestObject.import_finished.desc()) \
                        .first()

                    if last_object and last_object.import_finished:
                        job_obj.finished = last_object.import_finished
                    else:
                        job_obj.finished = datetime.datetime.utcnow()

                    job_obj.save()

                    # recreate job for datajson collection or the like.
                    source = job_obj.source
                    source_config = json.loads(source.config or '{}')
                    datajson_collection = source_config.get(
                        'datajson_collection')
                    if datajson_collection == 'parents_run':
                        new_job = HarvestJob()
                        new_job.source = source
                        new_job.save()
                        source_config['datajson_collection'] = 'children_run'
                        source.config = json.dumps(source_config)
                        source.save()
                    elif datajson_collection:
                        # reset the key if 'children_run', or anything.
                        source_config.pop("datajson_collection", None)
                        source.config = json.dumps(source_config)
                        source.save()

                    if config.get('ckanext.harvest.email') == 'on':
                        # email body

                        sql = '''select name from package where id = :source_id;'''

                        q = model.Session.execute(
                            sql, {'source_id': job_obj.source_id})

                        for row in q:
                            harvest_name = str(row['name'])

                        job_url = config.get('ckan.site_url') + '/harvest/' + harvest_name + '/job/' + job_obj.id

                        msg = 'Here is the summary of latest harvest job for your organization in Data.gov\n\n'

                        sql = '''select g.title as org, s.title as job_title from member m
                               join public.group g on m.group_id = g.id
                               join harvest_source s on s.id = m.table_id
                               where table_id = :source_id;'''

                        q = model.Session.execute(
                            sql, {'source_id': job_obj.source_id})

                        for row in q:
                            msg += 'Organization: ' + str(row['org']) + '\n\n'
                            msg += 'Harvest Job Title: ' + str(row['job_title']) + '\n\n'

                        msg += 'Date of Harvest: ' + str(job_obj.created) + ' GMT\n\n'

                        out = {
                            'last_job': None,
                        }

                        out['last_job'] = harvest_job_dictize(job_obj, context)

                        msg += 'Records in Error: ' + str(out['last_job']['stats'].get('errored', 0)) + '\n'
                        msg += 'Records Added: ' + str(out['last_job']['stats'].get('added', 0)) + '\n'
                        msg += 'Records Updated: ' + str(out['last_job']['stats'].get('updated', 0)) + '\n'
                        msg += 'Records Deleted: ' + str(out['last_job']['stats'].get('deleted', 0)) + '\n\n'

                        obj_error = ''
                        job_error = ''
                        all_updates = ''

                        sql = '''select hoe.message as msg from harvest_object ho
                              inner join harvest_object_error hoe on hoe.harvest_object_id = ho.id
                              where ho.harvest_job_id = :job_id;'''

                        q = model.Session.execute(
                            sql, {'job_id': job_obj.id})

                        for row in q:
                            obj_error += row['msg'] + '\n'

                        # get all packages added, updated and deleted by harvest job
                        sql = '''select ho.package_id as ho_package_id, ho.harvest_source_id, ho.report_status as ho_package_status, package.title as package_title
                                from harvest_object ho
                                inner join package on package.id = ho.package_id
                                where ho.harvest_job_id = :job_id and (ho.report_status = 'added' or ho.report_status = 'updated' or ho.report_status = 'deleted')
                                order by ho.report_status ASC;'''

                        q = model.Session.execute(sql, {'job_id': job_obj.id})
                        for row in q:
                            if row['ho_package_status'] is not None and row['ho_package_id'] is not None and row['package_title'] is not None:
                                all_updates += row['ho_package_status'] + ' , ' + row['ho_package_id'] + ', ' + row['package_title'] + '\n'

                        if(all_updates != ''):
                            msg += 'Summary\n\n' + all_updates + '\n\n'

                        # log.info('message in email:',all_updates)
                        sql = '''select message from harvest_gather_error where harvest_job_id = :job_id; '''
                        q = model.Session.execute(
                            sql, {'job_id': job_obj.id})
                        for row in q:
                            job_error += row['message'] + '\n'

                        if (obj_error != '' or job_error != ''):
                            msg += 'Error Summary\n\n'

                        if (obj_error != ''):
                            msg += 'Document Error\n' + obj_error + '\n\n'

                        if (job_error != ''):
                            msg += 'Job Errors\n' + job_error + '\n\n'

                        msg += '\n--\nYou are receiving this email because you are currently the administrator for your organization in Data.gov. Please do not reply to this email as it was sent from a non-monitored address. Please feel free to contact us at www.data.gov/contact for any questions or feedback.'
                        msg += '\n\nIf you have an admin/editor account in Data.gov catalog, you can view the detailed job report at the following url. You will need to log in first using link https://catalog.data.gov/user/login, then go to this url:'
                        msg += '\n\nhttps://admin-' + job_url

                        # get recipients
                        sql = '''select group_id from member where table_id = :source_id;'''
                        q = model.Session.execute(sql, {'source_id': job_obj.source_id})

                        for row in q:
                            all_emails = []

                            # emails from org admin
                            sql = '''select email from public.user u
                                  join member m on m.table_id = u.id
                                  where m.capacity = 'admin' and m.state = 'active' and u.state = 'active' and m.group_id = :group_id;'''
                            q1 = model.Session.execute(
                                sql, {'group_id': row['group_id']})
                            for row1 in q1:
                                _email = str(row1['email']).lower()
                                if _email:
                                    all_emails.append(_email)

                            # emails from org email_list
                            sql = '''SELECT value FROM group_extra
                                   WHERE state = 'active' AND key = 'email_list'
                                   AND group_id = :group_id'''
                            result = model.Session.execute(
                                sql, {'group_id': row['group_id']}).fetchone()

                            if result:
                                org_emails = result[0].strip()
                                if org_emails:
                                    org_email_list = org_emails.replace(
                                        ';', ' ').replace(',', ' ').split()
                                    for org_email in org_email_list:
                                        all_emails.append(org_email.lower())

                            if all_emails:
                                email = {
                                    'recipient_emails': all_emails,
                                    'subject': 'Data.gov Latest Harvest Job Report for ' + harvest_name.capitalize(),
                                    'body': msg
                                }
                                try:
                                    # GSA for uses bcc_recipients functio
                                    # TODO define what to do here
                                    mail_recipient(**email)
                                except Exception:
                                    pass

                    # Reindex the harvest source dataset so it has the latest
                    # status
                    # get_action('harvest_source_reindex')(context,
                    #     {'id': job_obj.source.id})
                    if 'extras_as_string' in context:
                        del context['extras_as_string']

                    context.update({'validate': False, 'ignore_auth': True})
                    package_dict = logic.get_action(
                        'package_show')(context, {'id': job_obj.source.id})

                    if package_dict:
                        package_index.index_package(package_dict)

    # Check if there are pending harvest jobs
    jobs = harvest_job_list(
        context, {'source_id': source_id, 'status': u'New'})
    if len(jobs) == 0:
        log.info('No new harvest jobs.')

    # Send each job to the gather queue
    publisher = get_gather_publisher()
    sent_jobs = []
    for job in jobs:
        context['detailed'] = False
        harvest_source_show = toolkit.get_action('harvest_source_show')
        source = harvest_source_show(context, {'id': job['source_id']})
        # source = harvest_source_show(context,{'id':source_id})
        if source['active']:
            job_obj = HarvestJob.get(job['id'])
            job_obj.status = job['status'] = u'Running'
            job_obj.save()
            publisher.send({'harvest_job_id': job['id']})
            log.info('Sent job %s to the gather queue' % job['id'])
            sent_jobs.append(job)

    publisher.close()

    return sent_jobs
