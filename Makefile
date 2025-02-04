# Variables
COMPOSE = docker compose
SERVICE = webserver
CONTAINER_NAME = nginx-curl-server

# Colors for pretty printing
GREEN = \033[0;32m
RED = \033[0;31m
NC = \033[0m # No Color

.PHONY: help build start stop restart status logs clean prune

# Default target when just running 'make'
help:
	@echo "Available commands:"
	@echo "  ${GREEN}make build${NC}      - Build the Docker image"
	@echo "  ${GREEN}make start${NC}      - Start the containers"
	@echo "  ${GREEN}make stop${NC}       - Stop the containers"
	@echo "  ${GREEN}make restart${NC}    - Restart the containers"
	@echo "  ${GREEN}make status${NC}     - Show container status"
	@echo "  ${GREEN}make logs${NC}       - Show container logs"
	@echo "  ${GREEN}make clean${NC}      - Stop and remove containers"
	@echo "  ${GREEN}make prune${NC}      - Clean and remove all unused Docker resources"
	@echo "  ${GREEN}make reload${NC}     - Reload the NGINX configuration"

# Build the Docker image
build:
	@echo "${GREEN}Building Docker image...${NC}"
	$(COMPOSE) build --no-cache

# Start the containers
start:
	@echo "${GREEN}Starting containers...${NC}"
	$(COMPOSE) up -d
	@echo "${GREEN}Containers started successfully${NC}"
	@make status

# Stop the containers
stop:
	@echo "${RED}Stopping containers...${NC}"
	$(COMPOSE) stop
	@echo "${RED}Containers stopped${NC}"

# Restart the containers
restart:
	@echo "${GREEN}Restarting containers...${NC}"
	@make stop
	@make start

# Show container status
status:
	@echo "${GREEN}Container status:${NC}"
	$(COMPOSE) ps

# Show container logs
logs:
	@echo "${GREEN}Container logs:${NC}"
	$(COMPOSE) logs -f $(SERVICE)

# Clean up containers
clean:
	@echo "${RED}Cleaning up containers...${NC}"
	$(COMPOSE) down
	@echo "${RED}Containers removed${NC}"

# Prune unused Docker resources
prune:
	@echo "${RED}Pruning unused Docker resources...${NC}"
	docker system prune -af
	@echo "${RED}Unused resources removed${NC}"

# Reload NGINX configuration
reload:
	@echo "${GREEN}Reloading NGINX configuration...${NC}"
	curl -s http://localhost/_reload
	@echo "${GREEN}Configuration reloaded${NC}"

# Create required directories on NAS
setup-nas:
	@echo "${GREEN}Creating directories on NAS...${NC}"
	mkdir -p /Docker/nginx-curl/html
	mkdir -p /Docker/nginx-curl/config
	@echo "${GREEN}NAS directories created${NC}"
