#!/bin/bash

# Docker Compose wrapper to handle both docker-compose and docker compose
if command -v docker-compose &> /dev/null; then
    exec docker-compose "$@"
elif docker compose version &> /dev/null; then
    exec docker compose "$@"
else
    echo "Error: Neither docker-compose nor docker compose found" >&2
    exit 1
fi