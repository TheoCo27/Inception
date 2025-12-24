# ----------------------------
# WordPress Dockerfile - Inception
# ----------------------------

# 1️⃣ Base Debian
FROM debian:bookworm

# 2️⃣ Installer PHP, extensions et outils
RUN apt-get update && apt-get install -y \
    php-fpm \
    php-mysql \
    php-gd \
    php-curl \
    php-mbstring \
    php-xml \
    php-zip \
    wget \
    curl \
    tar \
    mariadb-client \
    unzip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 3️⃣ Installer WP-CLI
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# 4️⃣ Créer le répertoire de travail et télécharger WordPress
WORKDIR /var/www/html
RUN wget https://wordpress.org/latest.tar.gz \
    && tar -xzf latest.tar.gz \
    && rm latest.tar.gz \
    && mv wordpress/* wordpress/.* . 2>/dev/null || true \
    && rm -rf wordpress

# 5️⃣ Permissions
RUN chown -R www-data:www-data /var/www/html

# 6️⃣ Copier configuration PHP-FPM et script setup
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/setup_wp.sh /usr/local/bin/setup_wp.sh
RUN chmod +x /usr/local/bin/setup_wp.sh

# 7️⃣ Exposer le port PHP-FPM
EXPOSE 9000

# 8️⃣ Lancer le script d'initialisation au démarrage
ENTRYPOINT ["/usr/local/bin/setup_wp.sh"]
