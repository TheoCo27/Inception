# DEV_DOC.md

## 1) Environment Setup From Scratch

### Prerequisites

Install these tools on your machine:

- Docker Engine / Docker Desktop
- Docker Compose (v2)
- GNU Make
- A shell (`bash` or `zsh`)

Verify installation:

```bash
docker --version
docker compose version
make --version
```

### Local host mapping

Add this line to your host file (`/etc/hosts`) so the domain resolves locally:

```txt
127.0.0.1 tcohen.42.fr
```

### Configuration file

Project config is stored in:

- `srcs/.env`

Make sure this file contains at least:

- `MYSQL_DATABASE`
- `MYSQL_USER`
- `WORDPRESS_DB_HOST`
- `WORDPRESS_DB_NAME`
- `WORDPRESS_DB_USER`
- `WP_URL`
- `WP_TITLE`
- `WP_ADMIN_USER`
- `WP_ADMIN_EMAIL`
- `WP_USER_LOGIN`
- `WP_USER_EMAIL`
- `WP_USER_ROLE`

### Secrets

Secrets are read from files in `secrets/`:

- `secrets/db_root_password.txt`
- `secrets/db_password.txt`
- `secrets/wp_admin_password.txt`
- `secrets/wp_user_password.txt`

If needed, create/update them:

```bash
mkdir -p secrets
printf 'RootPassChangeMe\n' > secrets/db_root_password.txt
printf 'DbPassChangeMe\n' > secrets/db_password.txt
printf 'WpAdminPassChangeMe\n' > secrets/wp_admin_password.txt
printf 'WpUserPassChangeMe\n' > secrets/wp_user_password.txt
```

## 2) Build and Launch

From project root:

```bash
make up
```

This command builds images and starts the full stack (`mariadb`, `wordpress`, `nginx`) using:

- `srcs/docker-compose.yml`
- It also creates bind-mount directories automatically:
  - `${HOME}/data/mariadb`
  - `${HOME}/data/wordpress`

Stop the stack:

```bash
make down
```

## 3) Useful Commands for Containers and Volumes

Main Make targets:

```bash
make up
make down
make start
make stop
make restart
make logs
make ps
make clean
make fclean
```

Direct Docker Compose commands:

```bash
docker compose -f srcs/docker-compose.yml ps
docker compose -f srcs/docker-compose.yml logs -f
docker compose -f srcs/docker-compose.yml exec -T wordpress wp --info --allow-root
docker compose -f srcs/docker-compose.yml down -v
```

Volume inspection:

```bash
docker volume ls | grep srcs_
docker volume inspect srcs_wordpress_data
docker volume inspect srcs_mariadb_data
```

## 4) Data Storage and Persistence

The project uses named Docker volumes:

- `mariadb_data` mounted to `/var/lib/mysql` in `mariadb`
- `wordpress_data` mounted to `/var/www/html` in `wordpress` and `nginx`

Persistence behavior:

- `make down`: containers/network removed, volumes kept, data persists
- `make fclean` or `docker compose ... down -v`: volumes removed, data reset

What persists:

- MariaDB database content (users, posts, settings)
- WordPress files and uploads (`wp-content/uploads`, plugins/themes/files)
