# mad-deployment-service

MAD Goat Deployment Service

# Build and Run

## Run

```

docker run --name mykeycloak -p 8443:8443 \
 -e KEYCLOAK_ADMIN=admin -e KEYCLOAK_ADMIN_PASSWORD=change_me \
 madkeycloak \
 start --optimized

```

## Run development mode

```

docker run --name madkeycloak -p 8080:8080 \
 -e KEYCLOAK_ADMIN=admin -e KEYCLOAK_ADMIN_PASSWORD=change_me \
 quay.io/keycloak/keycloak:latest \
 start-dev

```

Run only lessons service

```
docker compose up lesson-service db-lesson-service
```

Run only Keycloak

```
docker compose up db-keycloak-service keycloak-service
```

### Simplified Docker Compose

```
cd compose
docker compose -f configurations.yaml -f infrastructure.yaml -f services.yaml up
```

```

docker compose -f configurations.yaml -f infrastructure.yaml -f services.yaml down

```
