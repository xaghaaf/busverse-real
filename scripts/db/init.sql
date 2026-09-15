DO $$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'busverse') THEN
      CREATE ROLE busverse WITH LOGIN PASSWORD 'busverse_dev_password' SUPERUSER;
   END IF;
END
$$;

SELECT 'CREATE DATABASE busverse_real OWNER busverse'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'busverse_real')\gexec

\c busverse_real

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
