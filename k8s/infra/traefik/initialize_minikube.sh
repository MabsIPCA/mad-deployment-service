#!/bin/bash

MINIKUBE_CONTAINER=$(docker ps -aqf name=minikube)

if [ -n "$MINIKUBE_CONTAINER" ]; then
  echo "Minikube container found. Please delete the existing Minikube setup and try again."
  exit 1
else
  echo "No Minikube setup found. Initializing MAD GOAT Minikube."
fi

minikube start
helm install traefik traefik/traefik --values k8s/infra/traefik/values.yaml

echo "Waiting for the traefik service to be available"
ELAPSED=0
INTERVAL=1
while true; do
  if kubectl get service traefik &>/dev/null; then
    echo "Traefik Service  is ready"
    break
  fi
  sleep "$INTERVAL"
  ELAPSED=$((ELAPSED + INTERVAL))
done

minikube service traefik --url