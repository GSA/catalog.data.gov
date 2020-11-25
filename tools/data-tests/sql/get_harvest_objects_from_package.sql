SELECT 
    harvest_object.id AS harvest_object_id, 
    harvest_object.guid AS harvest_object_guid, 
    harvest_object.current AS harvest_object_current, 
    harvest_object.gathered AS harvest_object_gathered, 
    harvest_object.fetch_started AS harvest_object_fetch_started, 
    harvest_object.content AS harvest_object_content, 
    harvest_object.fetch_finished AS harvest_object_fetch_finished, 
    harvest_object.import_started AS harvest_object_import_started, 
    harvest_object.import_finished AS harvest_object_import_finished, 
    harvest_object.state AS harvest_object_state, 
    harvest_object.metadata_modified_date AS harvest_object_metadata_modified_date, 
    harvest_object.retry_times AS harvest_object_retry_times, 
    harvest_object.harvest_job_id AS harvest_object_harvest_job_id, 
    harvest_object.harvest_source_id AS harvest_object_harvest_source_id, 
    harvest_object.package_id AS harvest_object_package_id, 
    harvest_object.report_status AS harvest_object_report_status 

    FROM 
        harvest_object 
    WHERE 
        harvest_object.package_id = '{{ package_id }}';