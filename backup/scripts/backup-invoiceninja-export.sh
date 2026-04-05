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

HTTP_STATUS=$(curl -s -o "$FILE" -w "%{http_code}" \
    -X POST "${INVOICENINJA_URL}/api/v1/export" \
    -H "X-API-Token: ${INVOICENINJA_API_TOKEN}" \
    -H "X-Requested-With: XMLHttpRequest" \
    -H "Content-Type: application/json" \
    -d '{"send_email": false}')

if [ "$HTTP_STATUS" -lt 200 ] || [ "$HTTP_STATUS" -ge 300 ]; then
    echo "ERROR: Invoice Ninja export returned HTTP ${HTTP_STATUS}. Skipping upload."
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

echo "[$(date)] Pruning old exports older than ${RETENTION_DAYS} days"
rclone delete --min-age "${RETENTION_DAYS}d" "${REMOTE}:${BASE_PATH}/invoiceninja-export/" \
    --rmdirs || true

rm "$FILE"
echo "[$(date)] Invoice Ninja export backup done."
