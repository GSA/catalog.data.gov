from ckan.logic import chained_action
import logging
from ckan.plugins.toolkit import check_access


logger = logging.getLogger(__name__)


@chained_action
def harvest_jobs_run(up_func, context, data_dict):
    logger.info('Override function harvest_jobs_run started')
    check_access('harvest_jobs_run', context, data_dict)
    raise ValueError('Test')
    return
