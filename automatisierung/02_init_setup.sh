#!/usr/bin/env bash
set -euo pipefail

# Arbeitsverzeichnis auf den Pfad dieses Skripts festlegen
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 1. Umgebungsvariablen (.env) aus dem übergeordneten Verzeichnis laden
ENV_FILE="../.env"
if [ -f "$ENV_FILE" ]; then
    set -a
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +a
else
    echo "Fehler: Datei $ENV_FILE wurde nicht gefunden!" >&2
    exit 1
fi

echo "[$(date '+%H:%M:%S')] Initialisiere Staging & FDW auf DWH (${DWH_DB_NAME})..."

# 2. Setup-Skript mit Variablenübergabe im DWH-Container ausführen
docker exec -i dwh_analytics_db psql \
    -U "${DWH_DB_USER}" \
    -d "${DWH_DB_NAME}" \
    -v ON_ERROR_STOP=1 \
    -v ts_user="${TS_DB_USER}" \
    -v ts_password="${TS_DB_PASSWORD}" \
    -v is_user="${IS_DB_USER}" \
    -v is_password="${IS_DB_PASSWORD}" \
    < ../sql/02_staging_init.sql

echo "[$(date '+%H:%M:%S')] FDW-Setup erfolgreich abgeschlossen."
