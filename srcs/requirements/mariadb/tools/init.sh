#!/bin/bash
set -euo pipefail

load_secret() {
    local var_name="$1"
    local file_var_name="${var_name}_FILE"
    local var_value="${!var_name-}"
    local file_var_value="${!file_var_name-}"

    if [ -n "${var_value}" ] && [ -n "${file_var_value}" ]; then
        echo "Error: both ${var_name} and ${file_var_name} are set" >&2
        exit 1
    fi

    if [ -n "${file_var_value}" ]; then
        if [ ! -f "${file_var_value}" ]; then
            echo "Error: secret file not found: ${file_var_value}" >&2
            exit 1
        fi
        export "${var_name}=$(cat "${file_var_value}")"
        unset "${file_var_name}"
    fi
}

load_secret "MYSQL_PASSWORD"
load_secret "MYSQL_ROOT_PASSWORD"

: "${MYSQL_DATABASE:?MYSQL_DATABASE is not set}"
: "${MYSQL_USER:?MYSQL_USER is not set}"
: "${MYSQL_PASSWORD:?MYSQL_PASSWORD is not set}"
: "${MYSQL_ROOT_PASSWORD:?MYSQL_ROOT_PASSWORD is not set}"

DATADIR="/var/lib/mysql"
RUNDIR="/run/mysqld"
INIT_SQL="/tmp/mariadb-init.sql"

mkdir -p "${RUNDIR}"
chown -R mysql:mysql "${RUNDIR}" "${DATADIR}"

# Initialisation du datadir uniquement s'il est absent.
if [ ! -d "${DATADIR}/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    mysqld --initialize-insecure --user=mysql --datadir="${DATADIR}"
fi

cat > "${INIT_SQL}" <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

chmod 600 "${INIT_SQL}"
chown mysql:mysql "${INIT_SQL}"

echo "Starting MariaDB..."
exec mysqld --user=mysql --datadir="${DATADIR}" --init-file="${INIT_SQL}"
