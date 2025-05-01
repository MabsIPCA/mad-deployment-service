#!/bin/bash

helm repo add traefik https://traefik.github.io/charts
helm install traefik traefik/traefik --values k8s/infra/traefik/values.yaml

echo "Waiting for the 'default' service account in the default namespace..."
ELAPSED=0
INTERVAL=1
while true; do
  if kubectl get serviceaccount default -n default &>/dev/null; then
    echo "Service account 'default' is ready in the default namespace."
    break
  fi
  sleep "$INTERVAL"
  ELAPSED=$((ELAPSED + INTERVAL))
done

sleep 60

kubectl apply -f k8s/infra/traefik/dashboard.yaml


kubectl apply -f k8s/envs
kubectl apply -f k8s/db/db-lesson-service-claim0-persistentvolumeclaim.yaml
kubectl apply -f k8s/infra/keycloak/db-keycloak-service-claim0-persistentvolumeclaim.yaml

kubectl apply -f k8s/db

kubectl create configmap realm-config --from-file=k8s/infra/keycloak/realm-config.json
kubectl apply -f k8s/infra/keycloak
kubectl apply -f k8s/infra/minio
kubectl apply -f k8s/infra/rabbitmq

kubectl apply -f k8s/mad
kubectl apply -f k8s/services/docs
kubectl apply -f k8s/services/lesson
kubectl apply -f k8s/services/scoreboard
kubectl apply -f k8s/services/webapp
kubectl apply -f k8s/services/profile

kubectl apply -f k8s/infra/traefik/ingressRoutes.yaml
