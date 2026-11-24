#!/usr/bin/env bash
set -euo pipefail

wait_for_node() {
  local host="$1"
  until pg_isready --host "$host" --username "$POSTGRES_USER" --dbname "$POSTGRES_DB"; do
    sleep 2
  done
}

wait_for_node nodo-a
wait_for_node nodo-b

connection_to() {
  local host="$1"
  printf 'host=%s port=5432 dbname=%s user=%s password=%s' \
    "$host" "$POSTGRES_DB" "$REPLICATION_USER" "$REPLICATION_PASSWORD"
}

ensure_subscription() {
  local local_node="$1"
  local local_sub_name="$2"
  local remote_host="$3"
  local connection
  connection="$(connection_to "$remote_host")"

  local existing
  existing="$(PGPASSWORD="$POSTGRES_PASSWORD" psql \
    --host "$local_node" \
    --username "$POSTGRES_USER" \
    --dbname "$POSTGRES_DB" \
    --tuples-only --no-align \
    --command "SELECT 1 FROM pg_subscription WHERE subname = '$local_sub_name';")"

  if [[ "$existing" != "1" ]]; then
    PGPASSWORD="$POSTGRES_PASSWORD" psql \
      --host "$local_node" \
      --username "$POSTGRES_USER" \
      --dbname "$POSTGRES_DB" \
      --set ON_ERROR_STOP=1 \
      --command "CREATE SUBSCRIPTION $local_sub_name CONNECTION '$connection' PUBLICATION pub_farmacia WITH (copy_data = false, origin = 'none');"
  fi
}

ensure_subscription nodo-a sub_desde_nodo_b nodo-b
ensure_subscription nodo-b sub_desde_nodo_a nodo-a

echo "Suscripciones bidireccionales configuradas."
