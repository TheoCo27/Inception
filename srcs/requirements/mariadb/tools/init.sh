#!/bin/bash
# Bash pour script d'entrypoint MariaDB.
# -e: stop si une commande echoue
# -u: erreur si variable non definie
# -o pipefail: propage les erreurs dans les pipelines
set -euo pipefail

# Lit une variable de secret au format VAR ou VAR_FILE (fichier Docker secret).
load_secret() {
    # Nom de la variable cible (ex: MYSQL_PASSWORD).
    local var_name="$1"
    # Nom de la variable "fichier" associee (ex: MYSQL_PASSWORD_FILE).
    local file_var_name="${var_name}_FILE"
    # Valeur eventuelle fournie directement.
    local var_value="${!var_name-}"
    # Valeur eventuelle fournie via chemin de fichier.
    local file_var_value="${!file_var_name-}"

    # Interdit de definir a la fois la valeur directe et la valeur fichier.
    if [ -n "${var_value}" ] && [ -n "${file_var_value}" ]; then
        echo "Error: both ${var_name} and ${file_var_name} are set" >&2
        exit 1
    fi

    # Si VAR_FILE est fourni, lit son contenu et exporte VAR.
    if [ -n "${file_var_value}" ]; then
        # Echec explicite si le secret attendu est absent.
        if [ ! -f "${file_var_value}" ]; then
            echo "Error: secret file not found: ${file_var_value}" >&2
            exit 1
        fi
        # Recupere le mot de passe depuis le fichier secret.
        export "${var_name}=$(cat "${file_var_value}")"
        # Supprime la variable *_FILE pour limiter l'exposition de chemins sensibles.
        unset "${file_var_name}"
    fi
}

# Charge les mots de passe depuis les secrets Docker.
load_secret "MYSQL_PASSWORD"
load_secret "MYSQL_ROOT_PASSWORD"

# Valide les variables obligatoires et stoppe avec message clair si manquantes.
: "${MYSQL_DATABASE:?MYSQL_DATABASE is not set}"
: "${MYSQL_USER:?MYSQL_USER is not set}"
: "${MYSQL_PASSWORD:?MYSQL_PASSWORD is not set}"
: "${MYSQL_ROOT_PASSWORD:?MYSQL_ROOT_PASSWORD is not set}"

# Dossier des donnees MariaDB (persistant via volume).
DATADIR="/var/lib/mysql"
# Dossier runtime pour socket, pid et fichiers temporaires.
RUNDIR="/run/mysqld"

# Cree le dossier runtime si absent.
mkdir -p "${RUNDIR}"
# Corrige les permissions pour que mysqld (user mysql) puisse lire/ecrire.
chown -R mysql:mysql "${RUNDIR}" "${DATADIR}"

# Use a per-start SQL file to avoid permission conflicts on container restart.
# Genere un fichier SQL temporaire unique execute au boot.
INIT_SQL="$(mktemp "${RUNDIR}/mariadb-init.XXXXXX.sql")"

# Initialisation du datadir uniquement s'il est absent.
if [ ! -d "${DATADIR}/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    # Cree les fichiers systeme MariaDB sans mot de passe initial.
    # Le mot de passe root est force juste apres via init SQL.
    mysqld --initialize-insecure --user=mysql --datadir="${DATADIR}"
fi

# Ecrit les commandes SQL de provisionning (idempotentes grace a IF NOT EXISTS).
cat > "${INIT_SQL}" <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

# Restreint la lecture du script SQL aux comptes privilegies.
chmod 640 "${INIT_SQL}"
chown root:mysql "${INIT_SQL}"

echo "Starting MariaDB..."
# Remplace le shell par mysqld en process principal du conteneur.
exec mysqld --user=mysql --datadir="${DATADIR}" --init-file="${INIT_SQL}"
