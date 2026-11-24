#!/usr/bin/env bash
set -euo pipefail

psql \
  --username "$POSTGRES_USER" \
  --dbname "$POSTGRES_DB" \
  --set ON_ERROR_STOP=1 \
  --set replication_password="$REPLICATION_PASSWORD" <<'SQL'
CREATE ROLE replicador WITH LOGIN REPLICATION PASSWORD :'replication_password';
SQL
