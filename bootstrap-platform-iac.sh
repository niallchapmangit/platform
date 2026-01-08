#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"

echo "🏗️  Bootstrapping Infrastructure-as-Code platform repo..."
echo "📂 Root: $ROOT"

# -------------------------------------------------------------------
# Directory structure
# -------------------------------------------------------------------

mkdir -p \
  app-catalog/{keycloak,orangehrm,glpi,erpnext,nextcloud,rocketchat,vault} \
  base-compose \
  traefik \
  terraform/tenants \
  ci \
  tenants/acme/{keycloak,postgres-init}

# -------------------------------------------------------------------
# Helper
# -------------------------------------------------------------------

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
# Tenant definition
# -------------------------------------------------------------------

create_file tenants/acme/tenant.yaml <<'YAML'
tenant:
  name: acme
  domain: acme.example.com

infrastructure:
  region: lon1
  droplet_size: s-4vcpu-8gb

identity:
  realm: acme
  default_roles:
    - employee
    - manager
YAML

create_file tenants/acme/users.csv <<'CSV'
email,first_name,last_name,role
alice@acme.com,Alice,Smith,employee
bob@acme.com,Bob,Jones,manager
CSV

# -------------------------------------------------------------------
# Keycloak realm placeholder
# -------------------------------------------------------------------

create_file tenants/acme/keycloak/realm.json <<'JSON'
{
  "realm": "acme",
  "enabled": true,
  "roles": {
    "realm": [
      { "name": "employee" },
      { "name": "manager" }
    ]
  }
}
JSON

# -------------------------------------------------------------------
# Base compose
# -------------------------------------------------------------------

create_file base-compose/required.yml <<'YAML'
include:
  - ../app-catalog/keycloak/docker-compose.yml
  - ../app-catalog/orangehrm/docker-compose.yml
  - ../app-catalog/glpi/docker-compose.yml
  - ../app-catalog/erpnext/docker-compose.yml
  - ../app-catalog/nextcloud/docker-compose.yml
  - ../app-catalog/rocketchat/docker-compose.yml
YAML

# -------------------------------------------------------------------
# Traefik (repo-only)
# -------------------------------------------------------------------

create_file traefik/traefik.yml <<'YAML'
entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"

providers:
  docker:
    exposedByDefault: false

certificatesResolvers:
  letsencrypt:
    acme:
      email: admin@example.com
      storage: /letsencrypt/acme.json
      httpChallenge:
        entryPoint: web
YAML

create_file traefik/docker-compose.yml <<'YAML'
services:
  traefik:
    image: traefik:v3.0
    networks:
      - platform
networks:
  platform:
    external: true
YAML

mkdir -p traefik/letsencrypt
touch traefik/letsencrypt/acme.json

# -------------------------------------------------------------------
# Terraform skeleton
# -------------------------------------------------------------------

create_file terraform/providers.tf <<'HCL'
terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
    }
  }
}
HCL

create_file terraform/tenants/acme.tf <<'HCL'
# Tenant: acme
# Droplet, DNS, firewall will live here
HCL

# -------------------------------------------------------------------
# CI placeholders
# -------------------------------------------------------------------

create_file ci/generate-keycloak-users.py <<'PY'
# Reads users.csv and outputs Keycloak-compatible JSON
PY

create_file ci/pipeline.yml <<'YAML'
# GitHub Actions pipeline placeholder
YAML

# -------------------------------------------------------------------
# App catalog placeholders
# -------------------------------------------------------------------

for app in keycloak orangehrm glpi erpnext nextcloud rocketchat vault; do
  create_file "app-catalog/$app/docker-compose.yml" <<'YAML'
services: {}
YAML
done

# -------------------------------------------------------------------
# Git hygiene
# -------------------------------------------------------------------

create_file .gitignore <<'TXT'
.env
.DS_Store
__pycache__/
*.log
TXT

create_file README.md <<'MD'
# Open Source IT Infrastructure for SME

This repository is fully Infrastructure as Code.

Inputs:
- tenant.yaml
- users.csv

Outputs:
- Fully provisioned tenant
- DNS
- SSL
- Identity
- Applications
MD

echo "✅ Platform IaC bootstrap complete"
echo "👉 You can now git init && git push"

