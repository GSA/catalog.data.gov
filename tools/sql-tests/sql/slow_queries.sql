SELECT pid, age(query_start, clock_timestamp()), 
       state, usename, query 
FROM pg_stat_activity 
WHERE 
    query NOT ILIKE '%pg_stat_activity%' 
    AND state <> 'idle'
ORDER BY query_start desc;