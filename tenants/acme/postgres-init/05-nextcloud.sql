DO
$$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'nextcloud') THEN
    CREATE DATABASE nextcloud;
  END IF;
END
$$;

DO
$$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'nextcloud') THEN
    CREATE USER nextcloud WITH PASSWORD '${NEXTCLOUD_DB_PASSWORD}';
  END IF;
END
$$;

GRANT ALL PRIVILEGES ON DATABASE nextcloud TO nextcloud;
