#!/bin/bash
# Backs up one or more MySQL/MariaDB databases.
#
# Required env vars per database (replace <NAME> with a short identifier, e.g. "billing"):
#   MYSQL_DATABASES          space-separated list of names, e.g. "billing smsgateway ninja"
#   MYSQL_HOST_<NAME>
#   MYSQL_PORT_<NAME>        (default: 3306)
#   MYSQL_USER_<NAME>
#   MYSQL_PASS_<NAME>
#   MYSQL_DB_<NAME>          actual database name on the server
#
# Optional:
#   BACKUP_RETENTION_DAYS    how many days to keep remote backups (default: 30)
#   RCLONE_REMOTE            rclone remote name (default: destination)
#   RCLONE_BASE_PATH         base path on remote (default: backups)
#
# Secondary DB restore (e.g. all-inkl.com):
#   SECONDARY_MYSQL_ENABLED  true/false (default: false)
#   SECONDARY_MYSQL_HOST
#   SECONDARY_MYSQL_PORT     (default: 3306)
#   SECONDARY_MYSQL_USER
#   SECONDARY_MYSQL_PASS
#   SECONDARY_MYSQL_DB_<NAME>  target DB name on secondary server

set -euo pipefail

RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"
REMOTE="${RCLONE_REMOTE:-destination}"
BASE_PATH="${RCLONE_BASE_PATH:-backups}"
DATE=$(date +%Y-%m-%d_%H-%M)
SECONDARY_ENABLED="${SECONDARY_MYSQL_ENABLED:-false}"

if [ -z "${MYSQL_DATABASES:-}" ]; then
    echo "ERROR: MYSQL_DATABASES is not set."
    exit 1
fi

for NAME in $MYSQL_DATABASES; do
    HOST_VAR="MYSQL_HOST_${NAME}"
    PORT_VAR="MYSQL_PORT_${NAME}"
    USER_VAR="MYSQL_USER_${NAME}"
    PASS_VAR="MYSQL_PASS_${NAME}"
    DB_VAR="MYSQL_DB_${NAME}"

    HOST="${!HOST_VAR:-}"
    PORT="${!PORT_VAR:-3306}"
    USER="${!USER_VAR:-}"
    PASS="${!PASS_VAR:-}"
    DB="${!DB_VAR:-}"

    if [ -z "$HOST" ] || [ -z "$USER" ] || [ -z "$DB" ]; then
        echo "ERROR: Missing config for database '${NAME}' (need HOST, USER, DB). Skipping."
        continue
    fi

    FILE="/tmp/${NAME}_${DATE}.sql.gz"
    echo "[$(date)] Backing up database: ${NAME} (${DB} on ${HOST})"

    mysqldump \
        --host="$HOST" \
        --port="$PORT" \
        --user="$USER" \
        --password="$PASS" \
        --single-transaction \
        --routines \
        --triggers \
        "$DB" | gzip > "$FILE"

    echo "[$(date)] Uploading ${NAME} dump to ${REMOTE}:${BASE_PATH}/db/${NAME}/"
    rclone copyto "$FILE" "${REMOTE}:${BASE_PATH}/db/${NAME}/${NAME}_${DATE}.sql.gz"

    echo "[$(date)] Pruning remote backups older than ${RETENTION_DAYS} days for ${NAME}"
    rclone delete --min-age "${RETENTION_DAYS}d" "${REMOTE}:${BASE_PATH}/db/${NAME}/" || true

    if [ "$SECONDARY_ENABLED" = "true" ]; then
        SEC_DB_VAR="SECONDARY_MYSQL_DB_${NAME}"
        SEC_DB="${!SEC_DB_VAR:-}"
        SEC_HOST="${SECONDARY_MYSQL_HOST:-}"
        SEC_PORT="${SECONDARY_MYSQL_PORT:-3306}"
        SEC_USER="${SECONDARY_MYSQL_USER:-}"
        SEC_PASS="${SECONDARY_MYSQL_PASS:-}"

        if [ -z "$SEC_DB" ] || [ -z "$SEC_HOST" ] || [ -z "$SEC_USER" ]; then
            echo "WARNING: Secondary DB config incomplete for '${NAME}', skipping secondary restore."
        else
            echo "[$(date)] Restoring ${NAME} to secondary DB: ${SEC_DB} on ${SEC_HOST}"
            zcat "$FILE" | mysql \
                --host="$SEC_HOST" \
                --port="$SEC_PORT" \
                --user="$SEC_USER" \
                --password="$SEC_PASS" \
                "$SEC_DB"
        fi
    fi

    rm "$FILE"
    echo "[$(date)] Done: ${NAME}"
done
