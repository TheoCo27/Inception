#!/bin/bash
set -e

WP_CONFIG="/var/www/html/wp-config.php"

# 1️⃣ Créer wp-config.php si absent
if [ ! -f "$WP_CONFIG" ]; then
    echo "🛠 Création de wp-config.php..."
    cp /var/www/html/wp-config-sample.php "$WP_CONFIG"
    sed -i "s/database_name_here/${WORDPRESS_DB_NAME}/" "$WP_CONFIG"
    sed -i "s/username_here/${WORDPRESS_DB_USER}/" "$WP_CONFIG"
    sed -i "s/password_here/${WORDPRESS_DB_PASSWORD}/" "$WP_CONFIG"
    sed -i "s/localhost/${WORDPRESS_DB_HOST}/" "$WP_CONFIG"

    # Générer les clés de sécurité
    SALTS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
    if [ -n "$SALTS" ]; then
        echo "$SALTS" >> "$WP_CONFIG"
    fi

    echo "✅ wp-config.php créé"
fi

# 2️⃣ Assurer les permissions
chown -R www-data:www-data /var/www/html

# 3️⃣ Lancer PHP-FPM en avant-plan
echo "🚀 Démarrage de PHP-FPM..."
exec php-fpm8.2 -F
