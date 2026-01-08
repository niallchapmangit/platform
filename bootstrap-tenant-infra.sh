#!/usr/bin/env bash
set -euo pipefail

BASE="/Users/niall.chapman/Documents/Personal/platform"
TENANT="acme"
TENANT_DIR="$BASE/tenants/$TENANT"

echo "📁 Creating tenant infra directory..."
mkdir -p "$TENANT_DIR"

create_file () {
  local path="$1"
  if [ -f "$path" ]; then
    echo "⚠️  Skipping existing $path"
  else
    echo "📝 Creating $path"
    cat > "$path"
  fi
}

# -------------------------------------------------------------------

create_file "$TENANT_DIR/infra.yml" <<'YAML'
services:
  postgres:
    image: postgres:16
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_SUPERUSER}
      POSTGRES_PASSWORD: ${POSTGRES_SUPERUSER_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - tenant

  mongo:
    image: mongo:7
    restart: unless-stopped
    volumes:
      - mongo_data:/data/db
    networks:
      - tenant

  redis:
    image: redis:7
    restart: unless-stopped
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    networks:
      - tenant

volumes:
  postgres_data:
  mongo_data:
  redis_data:

networks:
  tenant:
    name: tenant_acme
YAML

# -------------------------------------------------------------------

create_file "$TENANT_DIR/.env" <<'ENV'
# General
DOMAIN=acme.example.com

# Postgres
POSTGRES_SUPERUSER=platform
POSTGRES_SUPERUSER_PASSWORD=change_me

# App DB Users (create later via init scripts)
KEYCLOAK_DB_USER=keycloak
KEYCLOAK_DB_PASSWORD=change_me

ORANGEHRM_DB_USER=orangehrm
ORANGEHRM_DB_PASSWORD=change_me

GLPI_DB_USER=glpi
GLPI_DB_PASSWORD=change_me

ERPNEXT_DB_PASSWORD=change_me

NEXTCLOUD_DB_USER=nextcloud
NEXTCLOUD_DB_PASSWORD=change_me

# Keycloak Admin
KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=change_me

# Vault (platform-level)
VAULT_ROOT_TOKEN=change_me
ENV

echo "✅ Tenant infrastructure bootstrap complete"

