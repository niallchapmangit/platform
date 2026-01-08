DO
$$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'orangehrm') THEN
    CREATE DATABASE orangehrm;
  END IF;
END
$$;

DO
$$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'orangehrm') THEN
    CREATE USER orangehrm WITH PASSWORD '${ORANGEHRM_DB_PASSWORD}';
  END IF;
END
$$;

GRANT ALL PRIVILEGES ON DATABASE orangehrm TO orangehrm;
