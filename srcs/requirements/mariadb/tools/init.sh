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
SOCKET="/run/mysqld/mysqld.sock"

# Initialisation uniquement si le volume est vide.
if [ ! -d "${DATADIR}/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    mysqld --initialize-insecure --user=mysql --datadir="${DATADIR}"

    echo "Starting temporary MariaDB for first-time setup..."
    mysqld_safe --datadir="${DATADIR}" --skip-networking &
    PID=$!

    echo "Waiting for temporary MariaDB..."
    until mysqladmin --protocol=socket --socket="${SOCKET}" ping --silent > /dev/null 2>&1; do
        sleep 1
    done

    mysql --protocol=socket --socket="${SOCKET}" -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

    echo "Stopping temporary MariaDB..."
    kill "${PID}"
    wait "${PID}" 2>/dev/null || true
fi

echo "Starting MariaDB..."
exec mysqld_safe --datadir="${DATADIR}"
