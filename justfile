image := "ghcr.io/eguefif/ecosim:latest"
stack := "ecosim"

default:
    @just --list

# Build the production image and push it to GHCR
push:
    docker build -t {{image}} .
    docker push {{image}}

# Deploy the stack and force the app service to pull the latest image
deploy:
    #!/usr/bin/env bash
    set -euo pipefail
    set -a && . ./.env.prod && set +a
    docker stack deploy --with-registry-auth -c docker-compose.prod.yml {{stack}}
    docker service update --force --with-registry-auth --image {{image}} {{stack}}_app

# Initialize the swarm on this host (run once on the manager)
init:
    docker swarm init
    sudo mkdir -p /opt/ecosim/letsencrypt
    @printf '\nSwarm initialized. Before running `just deploy`, create the secrets:\n\n'
    @printf "  printf '%%s' 'ecto://USER:PASS@HOST:5432/DB' | docker secret create database_url -\n"
    @printf "  mix phx.gen.secret | tr -d '\\\\n' | docker secret create secret_key_base -\n\n"
