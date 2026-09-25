#!/usr/bin/env bash
set -euo pipefail

# Arbeitsverzeichnis auf das Skriptverzeichnis setzen
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 1. Umgebungsvariablen (.env) aus dem Elternverzeichnis laden
ENV_FILE="../.env"
if [ -f "$ENV_FILE" ]; then
    set -a
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +a
else
    echo "Fehler: $ENV_FILE Datei nicht gefunden!" >&2
    exit 1
fi

LOG_FILE="${SCRIPT_DIR}/etl_pipeline.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=================================================="
echo "ETL-Pipeline gestartet: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=================================================="

# Ziel-Container und Zugangsdaten aus .env
CONTAINER_NAME="dwh_analytics_db"
DB_USER="${DWH_DB_USER}"
DB_NAME="${DWH_DB_NAME}"

# 2. Regelmäßige Transformationsskripte (ohne 02_staging_init.sql!)
SQL_FILES=(
    "../sql/03_etl_staging.sql"
    "../sql/04_core_layer.sql"
    # "../sql/05_business_star.sql"  # Aktivieren, sobald vorhanden
)

for sql_file in "${SQL_FILES[@]}"; do
    if [ ! -f "$sql_file" ]; then
        echo "FEHLER: Datei $sql_file existiert nicht!" >&2
        exit 1
    fi
    echo "[$(date '+%H:%M:%S')] Führe $sql_file aus..."
    docker exec -i "$CONTAINER_NAME" psql \
        -U "$DB_USER" \
        -d "$DB_NAME" \
        -v ON_ERROR_STOP=1 \
        < "$sql_file"
done

echo "=================================================="
echo "ETL-Pipeline erfolgreich beendet: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=================================================="
