#!/usr/bin/env bash
set -euo pipefail

BASE="/Users/niall.chapman/Documents/Personal/platform"

echo "📁 Creating directory structure..."
mkdir -p \
  "$BASE/base-compose" \
  "$BASE/tenants/acme" \
  "$BASE/app-catalog/keycloak" \
  "$BASE/app-catalog/orangehrm" \
  "$BASE/app-catalog/glpi" \
  "$BASE/app-catalog/erpnext" \
  "$BASE/app-catalog/nextcloud" \
  "$BASE/app-catalog/rocketchat" \
  "$BASE/app-catalog/vault"

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

create_file "$BASE/base-compose/required.yml" <<'YAML'
include:
  - ../app-catalog/keycloak/docker-compose.yml
  - ../app-catalog/orangehrm/docker-compose.yml
  - ../app-catalog/glpi/docker-compose.yml
  - ../app-catalog/erpnext/docker-compose.yml
  - ../app-catalog/nextcloud/docker-compose.yml
  - ../app-catalog/rocketchat/docker-compose.yml

networks:
  tenant:
    external: true
YAML

# -------------------------------------------------------------------

create_file "$BASE/app-catalog/keycloak/docker-compose.yml" <<'YAML'
services:
  keycloak:
    image: quay.io/keycloak/keycloak:24.0
    command: start
    environment:
      KC_DB: postgres
      KC_DB_URL: jdbc:postgresql://postgres:5432/keycloak
      KC_DB_USERNAME: ${KEYCLOAK_DB_USER}
      KC_DB_PASSWORD: ${KEYCLOAK_DB_PASSWORD}
      KEYCLOAK_ADMIN: ${KEYCLOAK_ADMIN}
      KEYCLOAK_ADMIN_PASSWORD: ${KEYCLOAK_ADMIN_PASSWORD}
    labels:
      - traefik.enable=true
      - traefik.http.routers.keycloak.rule=Host(`auth.${DOMAIN}`)
      - traefik.http.services.keycloak.loadbalancer.server.port=8080
    networks:
      - tenant
YAML

# -------------------------------------------------------------------

create_file "$BASE/app-catalog/orangehrm/docker-compose.yml" <<'YAML'
services:
  orangehrm:
    image: orangehrm/orangehrm:latest
    environment:
      ORANGEHRM_DATABASE_HOST: postgres
      ORANGEHRM_DATABASE_NAME: orangehrm
      ORANGEHRM_DATABASE_USER: ${ORANGEHRM_DB_USER}
      ORANGEHRM_DATABASE_PASSWORD: ${ORANGEHRM_DB_PASSWORD}
    labels:
      - traefik.enable=true
      - traefik.http.routers.orangehrm.rule=Host(`hr.${DOMAIN}`)
      - traefik.http.services.orangehrm.loadbalancer.server.port=80
    volumes:
      - orangehrm_data:/orangehrm
    networks:
      - tenant

volumes:
  orangehrm_data:
YAML

# -------------------------------------------------------------------

create_file "$BASE/app-catalog/glpi/docker-compose.yml" <<'YAML'
services:
  glpi:
    image: diouxx/glpi
    environment:
      MYSQL_HOST: postgres
      MYSQL_DATABASE: glpi
      MYSQL_USER: ${GLPI_DB_USER}
      MYSQL_PASSWORD: ${GLPI_DB_PASSWORD}
    labels:
      - traefik.enable=true
      - traefik.http.routers.glpi.rule=Host(`it.${DOMAIN}`)
      - traefik.http.services.glpi.loadbalancer.server.port=80
    volumes:
      - glpi_data:/var/www/html/glpi
    networks:
      - tenant

volumes:
  glpi_data:
YAML

# -------------------------------------------------------------------

create_file "$BASE/app-catalog/erpnext/docker-compose.yml" <<'YAML'
services:
  erpnext:
    image: frappe/erpnext:latest
    environment:
      SITE_NAME: erp.${DOMAIN}
      DB_HOST: postgres
      DB_NAME: erpnext
      DB_PASSWORD: ${ERPNEXT_DB_PASSWORD}
    labels:
      - traefik.enable=true
      - traefik.http.routers.erpnext.rule=Host(`erp.${DOMAIN}`)
      - traefik.http.services.erpnext.loadbalancer.server.port=8080
    volumes:
      - erpnext_data:/home/frappe/frappe-bench/sites
    networks:
      - tenant

volumes:
  erpnext_data:
YAML

# -------------------------------------------------------------------

create_file "$BASE/app-catalog/nextcloud/docker-compose.yml" <<'YAML'
services:
  nextcloud:
    image: nextcloud:28
    environment:
      POSTGRES_HOST: postgres
      POSTGRES_DB: nextcloud
      POSTGRES_USER: ${NEXTCLOUD_DB_USER}
      POSTGRES_PASSWORD: ${NEXTCLOUD_DB_PASSWORD}
    labels:
      - traefik.enable=true
      - traefik.http.routers.nextcloud.rule=Host(`cloud.${DOMAIN}`)
      - traefik.http.services.nextcloud.loadbalancer.server.port=80
    volumes:
      - nextcloud_data:/var/www/html
    networks:
      - tenant

volumes:
  nextcloud_data:
YAML

# -------------------------------------------------------------------

create_file "$BASE/app-catalog/rocketchat/docker-compose.yml" <<'YAML'
services:
  rocketchat:
    image: registry.rocket.chat/rocketchat/rocket.chat:6
    environment:
      MONGO_URL: mongodb://mongo:27017/rocketchat
      ROOT_URL: https://chat.${DOMAIN}
    labels:
      - traefik.enable=true
      - traefik.http.routers.rocketchat.rule=Host(`chat.${DOMAIN}`)
      - traefik.http.services.rocketchat.loadbalancer.server.port=3000
    networks:
      - tenant
YAML

# -------------------------------------------------------------------

create_file "$BASE/app-catalog/vault/docker-compose.yml" <<'YAML'
services:
  vault:
    image: hashicorp/vault:1.15
    cap_add:
      - IPC_LOCK
    environment:
      VAULT_DEV_ROOT_TOKEN_ID: ${VAULT_ROOT_TOKEN}
      VAULT_DEV_LISTEN_ADDRESS: 0.0.0.0:8200
    ports:
      - "8200:8200"
    volumes:
      - vault_data:/vault/file
    networks:
      - platform

volumes:
  vault_data:

networks:
  platform:
    name: platform
YAML

# -------------------------------------------------------------------

create_file "$BASE/tenants/acme/apps.yml" <<'YAML'
include:
  - ../../base-compose/required.yml

networks:
  tenant:
    name: tenant_acme
YAML

echo "✅ Platform bootstrap complete"

