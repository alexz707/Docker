#!/bin/bash
# Triggers Invoice Ninja V5 API export and uploads the ZIP to remote storage.
# This is a supplementary backup — use alongside DB dump and file backup.
#
# Required env vars:
#   INVOICENINJA_URL         base URL, e.g. https://invoiceninja.example.com
#   INVOICENINJA_API_TOKEN   admin API token
#
# Optional:
#   BACKUP_RETENTION_DAYS    (default: 30)
#   RCLONE_REMOTE            (default: destination)
#   RCLONE_BASE_PATH         (default: backups)

set -euo pipefail

RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"
REMOTE="${RCLONE_REMOTE:-destination}"
BASE_PATH="${RCLONE_BASE_PATH:-backups}"
DATE=$(date +%Y-%m-%d_%H-%M)

if [ -z "${INVOICENINJA_URL:-}" ] || [ -z "${INVOICENINJA_API_TOKEN:-}" ]; then
    echo "ERROR: INVOICENINJA_URL and INVOICENINJA_API_TOKEN must be set."
    exit 1
fi

FILE="/tmp/invoiceninja-export-${DATE}.zip"

echo "[$(date)] Requesting Invoice Ninja export..."

if ! HTTP_STATUS=$(curl -s -o "$FILE" -w "%{http_code}" \
    -X POST "${INVOICENINJA_URL}/api/v1/export" \
    -H "X-API-Token: ${INVOICENINJA_API_TOKEN}" \
    -H "X-Requested-With: XMLHttpRequest" \
    -H "Content-Type: application/json" \
    -d '{"send_email": false}'); then
    echo "ERROR: curl failed to connect to ${INVOICENINJA_URL} (network error or unreachable host)."
    rm -f "$FILE"
    exit 1
fi

echo "[$(date)] HTTP status: ${HTTP_STATUS}"

if [ "$HTTP_STATUS" -lt 200 ] || [ "$HTTP_STATUS" -ge 300 ]; then
    echo "ERROR: Invoice Ninja export returned HTTP ${HTTP_STATUS}."
    echo "Response body: $(cat "$FILE")"
    rm -f "$FILE"
    exit 1
fi

if [ ! -s "$FILE" ]; then
    echo "WARNING: Export response was empty (export may be async/email-based). Skipping upload."
    rm -f "$FILE"
    exit 0
fi

echo "[$(date)] Uploading export to ${REMOTE}:${BASE_PATH}/invoiceninja-export/"
rclone copyto "$FILE" "${REMOTE}:${BASE_PATH}/invoiceninja-export/${DATE}/export.zip"

CUTOFF=$(date -d "@$(($(date +%s) - RETENTION_DAYS * 86400))" +%Y-%m-%d)
echo "[$(date)] Pruning export backups older than ${RETENTION_DAYS} days (before ${CUTOFF})"
rclone lsf --dirs-only "${REMOTE}:${BASE_PATH}/invoiceninja-export/" 2>/dev/null | while read -r dir; do
    dir_date="${dir%/}"
    if [[ "$dir_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && [[ "$dir_date" < "$CUTOFF" ]]; then
        echo "[$(date)] Purging old export directory: ${dir_date}"
        rclone purge "${REMOTE}:${BASE_PATH}/invoiceninja-export/${dir_date}" || true
    fi
done

rm "$FILE"
echo "[$(date)] Invoice Ninja export backup done."
