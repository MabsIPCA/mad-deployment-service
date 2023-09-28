# MAD Deployment Service

This service is responsible for deploying the MAD application.
It is based on Docker and Docker Compose.
Kubernetes is not supported at the moment. (WIP)

# :whale: Docker Deployment

All relevant Docker Compose files are located in the `compose` folder.

> **Warning:**
> On a Windows machine you may need to disable Internet Information Services (IIS) to use port 80 and for Keycloak to work properly. (WIP)

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
- Docs Service - Documentation

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

### Secrets

```bash
kubectl apply -f /k8s/envs/*.yaml
```

### Helpful Commands

#### Dashboard

```
minikube dashboard --url
```

# :scroll: License

MIT License (see LICENSE file)

# Keycloak MadGoat service client private JWT key

This should never be shared with anyone. It is used to sign JWT tokens for the MadGoat service client.

Key :

```
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvGJSXMLY2fKdoN/D0oTYekvandITVIUAnIn719MQ5fQFg3TuEU5F9YU5l+VCkp4c4isW4ozpiQiJdFp8xnQfIiizO8LohNJbajzxkwvhqNsy9HqR1/iDD5zoroksvsCS7TPmM9J5bkgqhNGdK1hHJX91De3RLQfcQY9ZDYE6+NX3fAzuK9jx5TJc9k2KRJofniv/1RMaOaUhleP1ljdxI1ttyvU6FZCMCJoNAFVIXaPtA3/1jSJCE37XWORoWPG6Ri2d5rDwioJxc5rllTM/Av07qdXZVt446YFjwUoT113IbxAzX6fY2Mh48doKertXlkPcVcmrcOoivoxRp4KzQwIDAQAB
```

### Explore command injection on the MadGoat service

Install pgcli

```bash
apk add --no-cache postgresql-client
```

```bash
psql -h db-keycloak-service -p 5432 -U keycloak -d keycloak -W
```

The password is `password`

SELECT \* FROM client;
SELECT client_id FROM client;

