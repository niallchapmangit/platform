DO
$$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'erpnext') THEN
    CREATE DATABASE erpnext;
  END IF;
END
$$;

DO
$$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'erpnext') THEN
    CREATE USER erpnext WITH PASSWORD '${ERPNEXT_DB_PASSWORD}';
  END IF;
END
$$;

GRANT ALL PRIVILEGES ON DATABASE erpnext TO erpnext;
