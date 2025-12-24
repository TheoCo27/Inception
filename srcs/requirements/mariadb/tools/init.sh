#!/bin/bash
set -e

# Initialisation si /var/lib/mysql vide
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "🛠 Initialisation MariaDB..."
    mysqld --initialize-insecure --user=mysql --datadir=/var/lib/mysql
fi

# Lancer MariaDB temporaire
mysqld_safe --datadir=/var/lib/mysql &
PID=$!

# Attendre que MariaDB soit prêt
until mysqladmin ping --silent; do
    sleep 1
done

# Configurer root et l’utilisateur WordPress
mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

# Arrêter temporairement MariaDB
mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown

# Lancer MariaDB en avant-plan
exec mysqld_safe --datadir=/var/lib/mysql
