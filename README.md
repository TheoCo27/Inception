*This project has been created as part of the 42 curriculum by tcohen.*

# Inception

## Description
Inception is a system administration project focused on containerized infrastructure with Docker.

The goal is to build and run a complete WordPress stack using isolated services, persistent data, secure secret handling, and controlled networking.

This repository provides:
- A MariaDB service for data storage.
- A WordPress (PHP-FPM) service for the application logic.
- An Nginx service as the HTTPS entry point.
- Docker volumes for persistence.
- Docker secrets for passwords.

## Project Description (Docker Architecture and Sources)
This project uses Docker Compose to orchestrate multiple services, each with a single responsibility:

- `mariadb`: database service.
- `wordpress`: WordPress + PHP-FPM setup/bootstrapping.
- `nginx`: reverse proxy / TLS endpoint.

### Source layout
- `srcs/docker-compose.yml`: stack definition (services, volumes, secrets, network).
- `srcs/requirements/mariadb/`: MariaDB image, config, initialization script.
- `srcs/requirements/wordpress/`: WordPress image, PHP-FPM config, setup script.
- `srcs/requirements/nginx/`: Nginx image and TLS/server configuration.
- `secrets/`: secret files (database and WordPress passwords).
- `Makefile`: project lifecycle shortcuts (`make up`, `make down`, etc.).
- `USER_DOC.md`: end-user/admin usage documentation.
- `DEV_DOC.md`: developer setup and operations documentation.

### Main design choices
- Split services by role (database / app / web server) for clarity and isolation.
- Use named volumes for stateful data (`mariadb_data`, `wordpress_data`).
- Use Docker secrets for sensitive values instead of plain-text passwords in `.env`.
- Keep only HTTPS publicly exposed.

## Technical Comparisons

### Virtual Machines vs Docker
- **Virtual Machines**: full guest OS, heavier resource usage, slower startup, stronger OS-level isolation.
- **Docker containers**: share host kernel, lightweight, fast startup, ideal for service-based development.
- **Choice here**: Docker, because the project requires service orchestration and reproducible environments with lower overhead.

### Secrets vs Environment Variables
- **Environment variables**: easy to use, but sensitive values can leak via process lists, logs, or inspection output.
- **Docker secrets**: mounted as files at runtime (`/run/secrets/...`), better separation for sensitive data.
- **Choice here**: secrets for passwords, `.env` for non-sensitive config.

### Docker Network vs Host Network
- **Docker bridge network**: isolated container network, explicit published ports, safer defaults.
- **Host network**: container shares host network stack, less isolation, potential port conflicts.
- **Choice here**: Docker bridge network, with controlled exposure of HTTPS only.

### Docker Volumes vs Bind Mounts
- **Volumes**: Docker-managed storage, stable lifecycle, portable across host path changes.
- **Bind mounts**: direct host path mapping, useful for live dev edits but tighter host coupling.
- **Choice here**: named volumes for reliable persistence of DB and WordPress data.

## Instructions

### Prerequisites
- Docker Engine / Docker Desktop
- Docker Compose v2
- GNU Make

### Local host configuration
Add this to your host file (`/etc/hosts`):

```txt
127.0.0.1 tcohen.42.fr
```

### Required configuration
1. Check `srcs/.env` for non-sensitive values.
2. Set secrets in:
   - `secrets/db_root_password.txt`
   - `secrets/db_password.txt`
   - `secrets/wp_admin_password.txt`
   - `secrets/wp_user_password.txt`

### Build and run
From repository root:

```bash
make up
```

Stop stack:

```bash
make down
```

Useful operations:

```bash
make ps
make logs
make restart
make fclean
```

## Usage
- Website: `https://tcohen.42.fr`
- Admin panel: `https://tcohen.42.fr/wp-admin`

Note: the TLS certificate is self-signed (browser warning is expected).

## Resources

### Core references
- Docker overview: https://www.nicelydev.com/docker
- Docker learning playlist: https://www.youtube.com/playlist?app=desktop&list=PLsz00TDipIfcc6X5TECsuk0YNGWIx5HMl
- Docker tutorial video: https://www.youtube.com/watch?app=desktop&v=Ud7Npgi6x8E
- Docker official docs: https://docs.docker.com/
- Docker Compose reference: https://docs.docker.com/compose/
- WordPress + WP-CLI docs: https://developer.wordpress.org/cli/commands/
- Nginx docs: https://nginx.org/en/docs/
- MariaDB docs: https://mariadb.com/kb/en/documentation/

### How AI was used in this project
AI was used as a productivity assistant, not as an authority.

Used for:
- Reducing repetitive tasks (documentation drafting, command templates, formatting).
- Generating troubleshooting hypotheses during setup/debugging.
- Proposing refactoring ideas for shell scripts and container configuration.

Not used blindly:
- Generated content was reviewed, tested, and adjusted manually.
- Configuration and scripts were validated with runtime checks (`make up`, logs, service status).
- Final choices were made based on understanding of the stack behavior.

Quality and ethics approach:
- Prompts were prepared after analyzing the problem context.
- Outputs were critically checked for correctness and relevance.
- Peer review is expected to challenge assumptions and catch blind spots.
- Only content that can be explained and defended during evaluation is kept.
