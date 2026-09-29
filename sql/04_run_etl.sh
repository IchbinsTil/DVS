#!/usr/bin/env bash
# =========================================================
# Startet den ETL-Lauf im Postgres-Container.
# Container-Name unten anpassen.
#
# Automatisierung per Cron auf dem Docker-Host (täglich 04:00):
#   0 4 * * * /opt/dwh/04_run_etl.sh >> /var/log/dwh_etl.log 2>&1
# =========================================================
set -euo pipefail

CONTAINER="postgres"
DB="datawarehouse"
DB_USER="postgres"

echo "$(date '+%F %T') ETL-Lauf gestartet"

docker exec "$CONTAINER" psql -U "$DB_USER" -d "$DB" \
    -v ON_ERROR_STOP=1 \
    -c "CALL etl.load_dwh();"

echo "$(date '+%F %T') ETL-Lauf beendet"
