#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "Error: this script must be run on Linux."
  exit 1
fi

if [[ "${EUID}" -ne 0 ]]; then
  echo "Error: run this script with sudo."
  echo "Example: sudo ./scripts/configure_docker_data_root.sh /home/<login>/data/docker"
  exit 1
fi

LOGIN_USER="${SUDO_USER:-${USER:-}}"
if [[ -z "${LOGIN_USER}" || "${LOGIN_USER}" == "root" ]]; then
  echo "Error: could not detect non-root login user."
  echo "Pass an explicit path, for example:"
  echo "  sudo ./scripts/configure_docker_data_root.sh /home/<login>/data/docker"
  exit 1
fi

TARGET_DIR="${1:-/home/${LOGIN_USER}/data/docker}"
DOCKER_DAEMON_DIR="/etc/docker"
DOCKER_DAEMON_FILE="${DOCKER_DAEMON_DIR}/daemon.json"
BACKUP_FILE="${DOCKER_DAEMON_FILE}.bak.$(date +%Y%m%d-%H%M%S)"

echo "Configuring Docker data-root to: ${TARGET_DIR}"
mkdir -p "${TARGET_DIR}"
mkdir -p "${DOCKER_DAEMON_DIR}"

if [[ -f "${DOCKER_DAEMON_FILE}" ]]; then
  cp "${DOCKER_DAEMON_FILE}" "${BACKUP_FILE}"
  echo "Existing daemon.json backup: ${BACKUP_FILE}"
fi

cat > "${DOCKER_DAEMON_FILE}" <<EOF
{
  "data-root": "${TARGET_DIR}"
}
EOF

echo "Restarting Docker daemon..."
systemctl restart docker

echo "Done."
echo "Verify with:"
echo "  docker info | grep 'Docker Root Dir'"
