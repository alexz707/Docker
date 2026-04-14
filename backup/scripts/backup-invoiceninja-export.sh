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
BASE_PATH="${RCLONE_BASE_PATH-backups}"
REMOTE_ROOT="${REMOTE}:${BASE_PATH:+${BASE_PATH}/}"
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

# Invoice Ninja returns 200 with {"message":"Processing","url":"..."} for async exports
DOWNLOAD_URL=$(jq -r '.url // empty' "$FILE" 2>/dev/null)
rm -f "$FILE"

if [ -z "$DOWNLOAD_URL" ]; then
    echo "ERROR: Could not parse download URL from export response."
    exit 1
fi

echo "[$(date)] Export queued. Polling for download: ${DOWNLOAD_URL}"

ZIP_FILE="/tmp/invoiceninja-export-${DATE}.zip"
MAX_ATTEMPTS=12
SLEEP_SECONDS=10

for attempt in $(seq 1 "$MAX_ATTEMPTS"); do
    echo "[$(date)] Attempt ${attempt}/${MAX_ATTEMPTS} — waiting ${SLEEP_SECONDS}s..."
    sleep "$SLEEP_SECONDS"

    DL_STATUS=$(curl -s -o "$ZIP_FILE" -w "%{http_code}" "$DOWNLOAD_URL") || {
        echo "WARNING: curl failed on attempt ${attempt}, retrying..."
        continue
    }

    if [ "$DL_STATUS" = "200" ] && [ -s "$ZIP_FILE" ]; then
        # If the response is still JSON (still processing), keep waiting
        if jq -e '.message' "$ZIP_FILE" > /dev/null 2>&1; then
            echo "[$(date)] Still processing (attempt ${attempt})..."
            rm -f "$ZIP_FILE"
            continue
        fi
        echo "[$(date)] Export ready after attempt ${attempt}."
        break
    fi

    if [ "$attempt" = "$MAX_ATTEMPTS" ]; then
        echo "ERROR: Export not ready after ${MAX_ATTEMPTS} attempts. Last HTTP status: ${DL_STATUS}"
        rm -f "$ZIP_FILE"
        exit 1
    fi
done

echo "[$(date)] Uploading export to ${REMOTE_ROOT}invoiceninja-export/"
rclone copyto "$ZIP_FILE" "${REMOTE_ROOT}invoiceninja-export/${DATE}/export.zip"
rm -f "$ZIP_FILE"

CUTOFF=$(date -d "@$(($(date +%s) - RETENTION_DAYS * 86400))" +%Y-%m-%d)
echo "[$(date)] Pruning export backups older than ${RETENTION_DAYS} days (before ${CUTOFF})"
rclone lsf --dirs-only "${REMOTE_ROOT}invoiceninja-export/" 2>/dev/null | while read -r dir; do
    dir_date="${dir%/}"
    if [[ "$dir_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && [[ "$dir_date" < "$CUTOFF" ]]; then
        echo "[$(date)] Purging old export directory: ${dir_date}"
        rclone purge "${REMOTE_ROOT}invoiceninja-export/${dir_date}" || true
    fi
done

echo "[$(date)] Invoice Ninja export backup done."
