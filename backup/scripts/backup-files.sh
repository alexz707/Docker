#!/bin/bash
# Backs up file paths (mounted volumes) via rclone.
#
# Required env vars per source (replace <NAME> with a short identifier):
#   FILE_BACKUPS             space-separated list of names, e.g. "invoiceninja-storage invoiceninja-env"
#   FILE_PATH_<NAME>         path inside the container to back up (mount your volume here)
#
# Optional:
#   BACKUP_RETENTION_DAYS    (default: 30)
#   RCLONE_REMOTE            (default: destination)
#   RCLONE_BASE_PATH         (default: backups)
#   FILE_EXCLUDE_<NAME>      rclone exclude pattern(s), comma-separated
#                            e.g. "framework/cache/**,framework/sessions/**,logs/**"

set -euo pipefail

RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"
REMOTE="${RCLONE_REMOTE:-destination}"
BASE_PATH="${RCLONE_BASE_PATH-backups}"
REMOTE_ROOT="${REMOTE}:${BASE_PATH:+${BASE_PATH}/}"
DATE=$(date +%Y-%m-%d)

if [ -z "${FILE_BACKUPS:-}" ]; then
    echo "No FILE_BACKUPS configured, skipping file backup."
    exit 0
fi

for NAME in $FILE_BACKUPS; do
    PATH_VAR="FILE_PATH_${NAME}"
    EXCLUDE_VAR="FILE_EXCLUDE_${NAME}"

    SOURCE="${!PATH_VAR:-}"
    EXCLUDES="${!EXCLUDE_VAR:-}"

    if [ -z "$SOURCE" ]; then
        echo "ERROR: FILE_PATH_${NAME} is not set. Skipping."
        continue
    fi

    if [ ! -e "$SOURCE" ]; then
        echo "WARNING: Source path '${SOURCE}' does not exist. Skipping ${NAME}."
        continue
    fi

    RCLONE_ARGS=()
    if [ -n "$EXCLUDES" ]; then
        IFS=',' read -ra EXCL_LIST <<< "$EXCLUDES"
        for excl in "${EXCL_LIST[@]}"; do
            RCLONE_ARGS+=("--exclude" "$excl")
        done
    fi

    echo "[$(date)] Backing up files: ${NAME} from ${SOURCE}"
    rclone sync "$SOURCE" "${REMOTE_ROOT}files/${NAME}/${DATE}/" "${RCLONE_ARGS[@]}"

    CUTOFF=$(date -d "@$(($(date +%s) - RETENTION_DAYS * 86400))" +%Y-%m-%d)
    echo "[$(date)] Pruning date-based backups older than ${RETENTION_DAYS} days (before ${CUTOFF}) for ${NAME}"
    rclone lsf --dirs-only "${REMOTE_ROOT}files/${NAME}/" 2>/dev/null | while read -r dir; do
        dir_date="${dir%/}"
        if [[ "$dir_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && [[ "$dir_date" < "$CUTOFF" ]]; then
            echo "[$(date)] Purging old backup directory: ${dir_date}"
            rclone purge "${REMOTE_ROOT}files/${NAME}/${dir_date}" || true
        fi
    done

    echo "[$(date)] Done: ${NAME}"
done
