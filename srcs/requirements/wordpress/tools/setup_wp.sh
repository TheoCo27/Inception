#!/bin/bash
# Script d'entrypoint WordPress: attend la DB, configure WP, puis lance PHP-FPM.
# Mode strict pour fiabilite du bootstrap.
set -euo pipefail

# Meme logique que cote MariaDB: lit VAR ou VAR_FILE pour les secrets Docker.
load_secret() {
  # Nom de variable attendu.
  local var_name="$1"
  # Variante avec suffixe _FILE.
  local file_var_name="${var_name}_FILE"
  # Valeur directe potentielle.
  local var_value="${!var_name-}"
  # Chemin de fichier potentiel.
  local file_var_value="${!file_var_name-}"

  # Refuse une configuration ambigue (double definition).
  if [ -n "${var_value}" ] && [ -n "${file_var_value}" ]; then
    echo "Error: both ${var_name} and ${file_var_name} are set" >&2
    exit 1
  fi

  # Priorise la lecture depuis un fichier secret si present.
  if [ -n "${file_var_value}" ]; then
    # Erreur claire si le secret attendu n'existe pas.
    if [ ! -f "${file_var_value}" ]; then
      echo "Error: secret file not found: ${file_var_value}" >&2
      exit 1
    fi
    # Injecte la valeur du secret dans la variable cible.
    export "${var_name}=$(cat "${file_var_value}")"
    # Nettoie la variable de chemin apres lecture.
    unset "${file_var_name}"
  fi
}

# Charge les secrets applicatifs (DB + mots de passe users WP).
load_secret "WORDPRESS_DB_PASSWORD"
load_secret "WP_ADMIN_PASSWORD"
load_secret "WP_USER_PASSWORD"

# Chemin d'installation WordPress.
WP_PATH="/var/www/html"
# Fichier de configuration genere par WP-CLI.
WP_CONFIG="${WP_PATH}/wp-config.php"
# Alias WP-CLI centralise pour eviter les repetitions.
WP_CLI="wp --path=${WP_PATH} --allow-root"

# Variables DB
# Validation des variables critiques de connexion base de donnees.
: "${WORDPRESS_DB_NAME:?WORDPRESS_DB_NAME is not set}"
: "${WORDPRESS_DB_USER:?WORDPRESS_DB_USER is not set}"
: "${WORDPRESS_DB_PASSWORD:?WORDPRESS_DB_PASSWORD is not set}"
: "${WORDPRESS_DB_HOST:?WORDPRESS_DB_HOST is not set}"

# Variables WordPress (2 users: admin + user standard)
# Validation des variables necessaires a l'installation initiale.
: "${WP_ADMIN_USER:?WP_ADMIN_USER is not set}"
: "${WP_ADMIN_PASSWORD:?WP_ADMIN_PASSWORD is not set}"
: "${WP_ADMIN_EMAIL:?WP_ADMIN_EMAIL is not set}"
: "${WP_USER_LOGIN:?WP_USER_LOGIN is not set}"
: "${WP_USER_PASSWORD:?WP_USER_PASSWORD is not set}"
: "${WP_USER_EMAIL:?WP_USER_EMAIL is not set}"

# Valeurs par defaut si non definies dans .env.
WP_URL="${WP_URL:-https://localhost:8443}"
WP_TITLE="${WP_TITLE:-Inception}"
WP_USER_ROLE="${WP_USER_ROLE:-author}"

# Se place dans le dossier WordPress pour toutes les commandes suivantes.
cd "${WP_PATH}"

echo "Waiting for MariaDB..."
# Boucle d'attente active jusqu'a ce que MariaDB reponde au ping.
until mysqladmin ping \
  -h"${WORDPRESS_DB_HOST}" \
  -u"${WORDPRESS_DB_USER}" \
  -p"${WORDPRESS_DB_PASSWORD}" \
  --silent > /dev/null 2>&1; do
  # Evite de spammer la DB et laisse du temps au demarrage.
  sleep 2
done
echo "MariaDB is ready"

# Cree wp-config.php seulement si absent (idempotence).
if [ ! -f "${WP_CONFIG}" ]; then
  echo "Creating wp-config.php..."
  ${WP_CLI} config create \
    --dbname="${WORDPRESS_DB_NAME}" \
    --dbuser="${WORDPRESS_DB_USER}" \
    --dbpass="${WORDPRESS_DB_PASSWORD}" \
    --dbhost="${WORDPRESS_DB_HOST}" \
    --skip-check
  echo "wp-config.php created"
fi

# Installe le coeur WordPress seulement s'il n'est pas deja installe.
if ! ${WP_CLI} core is-installed > /dev/null 2>&1; then
  echo "Installing WordPress core..."
  ${WP_CLI} core install \
    --url="${WP_URL}" \
    --title="${WP_TITLE}" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${WP_ADMIN_PASSWORD}" \
    --admin_email="${WP_ADMIN_EMAIL}" \
    --skip-email
  echo "WordPress core installed"
fi

# Garde WordPress coherent avec l'URL exposee par nginx.
# Force les options URL a chaque demarrage pour eviter les desynchronisations.
${WP_CLI} option update home "${WP_URL}" > /dev/null
${WP_CLI} option update siteurl "${WP_URL}" > /dev/null

# Admin: cree si absent, sinon met a jour email/password.
# Garantit que le compte admin existe avec les bons attributs.
if ${WP_CLI} user get "${WP_ADMIN_USER}" > /dev/null 2>&1; then
  ${WP_CLI} user update "${WP_ADMIN_USER}" \
    --user_pass="${WP_ADMIN_PASSWORD}" \
    --user_email="${WP_ADMIN_EMAIL}" \
    --role=administrator > /dev/null
else
  ${WP_CLI} user create "${WP_ADMIN_USER}" "${WP_ADMIN_EMAIL}" \
    --role=administrator \
    --user_pass="${WP_ADMIN_PASSWORD}" > /dev/null
fi

# User standard: cree si absent, sinon met a jour email/password/role.
# Meme logique pour l'utilisateur non-admin du sujet.
if ${WP_CLI} user get "${WP_USER_LOGIN}" > /dev/null 2>&1; then
  ${WP_CLI} user update "${WP_USER_LOGIN}" \
    --user_pass="${WP_USER_PASSWORD}" \
    --user_email="${WP_USER_EMAIL}" \
    --role="${WP_USER_ROLE}" > /dev/null
else
  ${WP_CLI} user create "${WP_USER_LOGIN}" "${WP_USER_EMAIL}" \
    --role="${WP_USER_ROLE}" \
    --user_pass="${WP_USER_PASSWORD}" > /dev/null
fi

# Assure les droits fichiers corrects pour Nginx/PHP.
chown -R www-data:www-data "${WP_PATH}"

echo "Starting PHP-FPM..."
# Lance PHP-FPM au premier plan (process principal du conteneur).
exec php-fpm8.2 -F
