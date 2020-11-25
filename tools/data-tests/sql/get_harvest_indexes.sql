SELECT 
    tablename, indexname, indexdef 
FROM 
    pg_indexes 
WHERE 
    tablename IN (
        'harvest_object',
        'harvest_source',
        'harvest_job',
        'harvest_object_extra',
        'harvest_gather_error',
        'harvest_object_error',
        'harvest_log');