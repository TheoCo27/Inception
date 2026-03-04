# USER_DOC.md

## 1) Stack Overview

This project runs a WordPress website with three services:

- `nginx`: HTTPS web server (public entry point).
- `wordpress`: PHP-FPM + WordPress application.
- `mariadb`: database used by WordPress.

Persistent data is stored in Docker volumes:

- `wordpress_data`: WordPress files and uploads.
- `mariadb_data`: MariaDB data.

Sensitive passwords are managed with Docker secrets (files in `secrets/`).

## 2) Start and Stop the Project

Run commands from the project root.

Start everything:

```bash
make up
```

Stop and remove containers/network (keep volumes):

```bash
make down
```

Other useful commands:

```bash
make stop      # stop containers
make start     # start stopped containers
make restart   # restart containers
make logs      # follow logs
make ps        # show service status
```

Full cleanup (removes volumes too):

```bash
make fclean
```

## 3) Access Website and Admin Panel

Before access, add this host entry on your machine:

```txt
127.0.0.1 tcohen.42.fr
```

Website:

- `https://tcohen.42.fr`

Admin panel:

- `https://tcohen.42.fr/wp-admin`

Note: the HTTPS certificate is self-signed, so your browser will show a security warning.

## 4) Locate and Manage Credentials

Non-sensitive config is in:

- `srcs/.env`

Passwords are in:

- `secrets/db_root_password.txt`
- `secrets/db_password.txt`
- `secrets/wp_admin_password.txt`
- `secrets/wp_user_password.txt`

How to update credentials:

1. Edit the secret file(s).
2. Restart the stack:
   - `make down && make up`

Important:

- Changing WordPress user passwords is applied at startup by the setup script.
- If you change database passwords on an existing database, you may need a full reset:
  - `make fclean && make up`

## 5) Check Services Health

Check service status:

```bash
make ps
```

Check logs:

```bash
make logs
```

Quick connectivity checks:

```bash
curl -kI https://tcohen.42.fr
curl -I http://tcohen.42.fr
```

Expected result:

- HTTPS responds.
- HTTP should not be accessible.
