# Nom logique du projet.
NAME = inception

# Binaire Compose utilise pour orchestrer les services.
COMPOSE = docker-compose
# Chemin du fichier compose principal.
COMPOSE_FILE = srcs/docker-compose.yml

# Cible par defaut: lance la stack.
all: up

# Build + demarrage en arriere-plan.
up:
	$(COMPOSE) -f $(COMPOSE_FILE) up -d --build

# Arret et suppression des conteneurs/reseaux du projet.
down:
	$(COMPOSE) -f $(COMPOSE_FILE) down

# Demarre les conteneurs existants sans rebuild.
start:
	$(COMPOSE) -f $(COMPOSE_FILE) start

# Stoppe les conteneurs sans les supprimer.
stop:
	$(COMPOSE) -f $(COMPOSE_FILE) stop

# Redemarre les conteneurs existants.
restart:
	$(COMPOSE) -f $(COMPOSE_FILE) restart

# Suit les logs en temps reel.
logs:
	$(COMPOSE) -f $(COMPOSE_FILE) logs -f

# Affiche l'etat des services.
ps:
	$(COMPOSE) -f $(COMPOSE_FILE) ps

# Nettoyage global Docker (images/cache/containers non utilises).
# Important: peut supprimer des artefacts hors projet.
clean: down
	docker system prune -af

# Nettoyage complet avec volumes Docker en plus.
# Important: peut entrainer une perte de donnees persistantes.
fclean: down
	docker system prune -af --volumes

# Rebuild complet: wipe puis relance.
re: fclean up

docker-data-root:
	@echo "Run this on your Linux VM:"
	@echo "  sudo ./srcs/scripts/configure_docker_data_root.sh /home/$${USER}/data/docker"

# Declare les cibles non-fichiers pour eviter les conflits de noms.
.PHONY: all up down start stop restart logs ps clean fclean re docker-data-root
