# MAD Deployment Service

This service is responsible for deploying the MAD application.
It is based on Docker and Docker Compose.
Kubernetes is not supported at the moment. (WIP)

# :whale: Docker Deployment

All relevant Docker Compose files are located in the `compose` folder.

## :clipboard: Prequisites

1. Install Docker
2. Install Docker Compose
3. Increase the memory limit of Docker to at least 12GB (16GB recommended) (WIP)

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

# :wheel_of_dharma: Kubernetes Deployment

# :clipboard: Prequisites

1. Install Minikube
2. Install kubectl
3. Install Helm

## Minikube

1. Install Minikube
2. Install kubectl
3. Start Minikube

   ```
   minikube start
   ```

4. Enable Ingress
   ```
   minikube addons enable ingress
   ```

### :rocket: Quickstart

```
cd kubernetes
helm install mad .
```

### Helpful Commands

#### Dashboard

```
minikube dashboard --url
```

# :scroll: License

MIT License (see LICENSE file)

```

```
