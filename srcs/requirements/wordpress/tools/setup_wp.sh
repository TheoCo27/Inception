#!/bin/bash
set -e

sleep 5

WP_PATH="/var/www/html"
WP_CONFIG="$WP_PATH/wp-config.php"

# Vérification des variables d'environnement
: "${WORDPRESS_DB_NAME:?WORDPRESS_DB_NAME is not set}"
: "${WORDPRESS_DB_USER:?WORDPRESS_DB_USER is not set}"
: "${WORDPRESS_DB_PASSWORD:?WORDPRESS_DB_PASSWORD is not set}"
: "${WORDPRESS_DB_HOST:?WORDPRESS_DB_HOST is not set}"

cd "$WP_PATH"

# ⏳ Attendre que MariaDB soit prête
echo "⏳ Waiting for MariaDB..."
until mysql -h"$WORDPRESS_DB_HOST" -u"$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" "$WORDPRESS_DB_NAME" &> /dev/null; do
  sleep 2
done
echo "✅ MariaDB ready"

# 1️⃣ Créer wp-config.php avec wp-cli
if [ ! -f "$WP_CONFIG" ]; then
    echo "🛠 Création de wp-config.php avec wp-cli..."

    wp config create \
        --dbname="$WORDPRESS_DB_NAME" \
        --dbuser="$WORDPRESS_DB_USER" \
        --dbpass="$WORDPRESS_DB_PASSWORD" \
        --dbhost="$WORDPRESS_DB_HOST" \
        --skip-check \
        --allow-root

    echo "✅ wp-config.php créé"
fi

# 2️⃣ Permissions correctes
chown -R www-data:www-data "$WP_PATH"

# 3️⃣ Lancer PHP-FPM en avant-plan
echo "🚀 Démarrage de PHP-FPM..."
exec php-fpm8.2 -F
