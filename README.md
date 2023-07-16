# MAD Deployment Service

This service is responsible for deploying the MAD application.
It is based on Docker and Docker Compose.
Kubernetes is not supported at the moment. (WIP)

# :whale: Docker Deployment

All relevant Docker Compose files are located in the `compose` folder.

## :clipboard: Prequisites

1. Install Docker
2. Install Docker Compose

## :rocket: Quickstart

```
cd compose
docker compose -f configurations.yaml -f infrastructure.yaml -f services.yaml up
```

## :building_construction: Infrastructure

The infrastructure is defined in the `infrastructure.yaml` file.
It contains the following services:

- Keycloak
- Database for Keycloak
- Traefik
- RabbitMQ

## :briefcase: Services

The services are defined in the `services.yaml` file.
It contains the following services:

- Webapp
- Lesson Service
- Database for Lesson Service
- Scoreboard Service
- Database for Scoreboard Service
- MAD 4Shell Service - Safe - No log4j vulnerability
- MAD 4Shell Service - Vulnerable - With log4j vulnerability
- Jekyll Service - Documentation

# :scroll: License

MIT License (see LICENSE file)
