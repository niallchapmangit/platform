#!/usr/bin/env bash
set -euo pipefail

BASE="/Users/niall.chapman/Documents/Personal/platform"
TENANT="acme"
TENANT_DIR="$BASE/tenants/$TENANT"
INIT_DIR="$TENANT_DIR/postgres-init"
INFRA_FILE="$TENANT_DIR/infra.yml"

echo "📁 Creating postgres-init directory..."
mkdir -p "$INIT_DIR"

create_sql () {
  local path="$1"
  if [ -f "$path" ]; then
    echo "⚠️  Skipping existing $path"
  else
    echo "📝 Creating $path"
    cat > "$path"
  fi
}

# ------------------------------------------------------------------
# SQL FILES
# ------------------------------------------------------------------

create_sql "$INIT_DIR/01-keycloak.sql" <<'SQL'
DO
$$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'keycloak') THEN
    CREATE DATABASE keycloak;
  END IF;
END
$$;

DO
$$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'keycloak') THEN
    CREATE USER keycloak WITH PASSWORD '${KEYCLOAK_DB_PASSWORD}';
  END IF;
END
$$;

GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;
SQL

# ------------------------------------------------------------------

create_sql "$INIT_DIR/02-orangehrm.sql" <<'SQL'
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
SQL

# ------------------------------------------------------------------

create_sql "$INIT_DIR/03-glpi.sql" <<'SQL'
DO
$$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'glpi') THEN
    CREATE DATABASE glpi;
  END IF;
END
$$;

DO
$$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'glpi') THEN
    CREATE USER glpi WITH PASSWORD '${GLPI_DB_PASSWORD}';
  END IF;
END
$$;

GRANT ALL PRIVILEGES ON DATABASE glpi TO glpi;
SQL

# ------------------------------------------------------------------

create_sql "$INIT_DIR/04-erpnext.sql" <<'SQL'
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
SQL

# ------------------------------------------------------------------

create_sql "$INIT_DIR/05-nextcloud.sql" <<'SQL'
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
SQL

# ------------------------------------------------------------------
# PATCH infra.yml (safe, idempotent)
# ------------------------------------------------------------------

echo "🔧 Ensuring infra.yml mounts postgres-init..."

if ! grep -q "docker-entrypoint-initdb.d" "$INFRA_FILE"; then
  awk '
  $1=="postgres:" { in_pg=1 }
  in_pg && $1=="volumes:" {
    print
    print "      - ./postgres-init:/docker-entrypoint-initdb.d"
    next
  }
  { print }
  ' "$INFRA_FILE" > "$INFRA_FILE.tmp"

  mv "$INFRA_FILE.tmp" "$INFRA_FILE"
  echo "✅ infra.yml updated"
else
  echo "⚠️  infra.yml already configured"
fi

echo "✅ Postgres init bootstrap complete"

