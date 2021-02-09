CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder;
CREATE EXTENSION IF NOT EXISTS postgis_topology;
ALTER SCHEMA tiger OWNER TO {user};
ALTER SCHEMA tiger_data OWNER TO {user};
ALTER SCHEMA topology OWNER TO {user};
CREATE FUNCTION exec(text) RETURNS text LANGUAGE PLPGSQL VOLATILE AS $f$ BEGIN EXECUTE $1; RETURN $1; END; $f$;                              
SELECT exec('ALTER TABLE ' || quote_ident(s.nspname) || '.' || quote_ident(s.relname) || ' OWNER TO {user};')
    FROM (
        SELECT nspname, relname
        FROM pg_class c JOIN pg_namespace n ON (c.relnamespace = n.oid) 
        WHERE nspname IN ('tiger','topology', 'tiger_data') AND
    relkind IN ('r','S','v') ORDER BY relkind = 'S')
s;  

SET search_path=public,tiger;