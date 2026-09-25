#!/usr/bin/env bash
set -euo pipefail

# Arbeitsverzeichnis auf den Skript-Pfad setzen
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 1. Umgebungsvariablen (.env) robust laden (ohne xargs-Quote-Probleme)
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

LOG_FILE="${SCRIPT_DIR}/init_quelldaten.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=================================================="
echo "Initialisierung der Quellsysteme gestartet: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=================================================="

# Container-Namen aus docker-compose.yaml
CONTAINER_IS="dwh_source_inventarsystem_db"
CONTAINER_TS="dwh_source_ticketsystem_db"

# ------------------------------------------------------------
# 1. Inventarsystem initialisieren & befüllen
# ------------------------------------------------------------
echo "[$(date '+%H:%M:%S')] [Inventarsystem] Schema anlegen..."
docker exec -i "$CONTAINER_IS" psql \
    -U "$IS_DB_USER" \
    -d "$IS_DB_NAME" \
    -v ON_ERROR_STOP=1 \
    < "../sql/01_init_inventarsystem.sql"

echo "[$(date '+%H:%M:%S')] [Inventarsystem] Beispieldaten laden..."
docker exec -i "$CONTAINER_IS" psql \
    -U "$IS_DB_USER" \
    -d "$IS_DB_NAME" \
    -v ON_ERROR_STOP=1 \
    < "../sql/Beispieldaten/beispieldaten_inventarsystem.sql"

# ------------------------------------------------------------
# 2. Ticketsystem initialisieren & befüllen
# ------------------------------------------------------------
echo "[$(date '+%H:%M:%S')] [Ticketsystem] Schema anlegen..."
docker exec -i "$CONTAINER_TS" psql \
    -U "$TS_DB_USER" \
    -d "$TS_DB_NAME" \
    -v ON_ERROR_STOP=1 \
    < "../sql/01_init_ticketsystem.sql"

echo "[$(date '+%H:%M:%S')] [Ticketsystem] Beispieldaten laden..."
docker exec -i "$CONTAINER_TS" psql \
    -U "$TS_DB_USER" \
    -d "$TS_DB_NAME" \
    -v ON_ERROR_STOP=1 \
    < "../sql/Beispieldaten/beispieldaten_ticketsystem.sql"

echo "=================================================="
echo "Init-Quelldaten erfolgreich beendet: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=================================================="
