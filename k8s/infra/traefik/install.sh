#!/bin/bash

MINIKUBE_CONTAINER=$(docker ps -aqf name=minikube)

if [ -n "$MINIKUBE_CONTAINER" ]; then
  echo "Minikube container found. Please delete the existing Minikube setup and try again."
  exit 1
else
  echo "No Minikube setup found. Initializing MAD GOAT Minikube."
fi

minikube start --cpus 8 --memory 20000MB
minikube addons enable ingress
minikube addons enable ingress-dns

sleep 5 # to allow cluster services to start

MINIKUBE_IP=$(minikube ip)
kubectl get configmap coredns -n kube-system -o yaml > coredns-backup.yaml

# Extract and modify Corefile, then update the ConfigMap
kubectl get configmap coredns -n kube-system -o json | jq --arg minikube_ip "$MINIKUBE_IP" '
    .data.Corefile += "mad.io:53 {\n    errors\n    cache 30\n    forward . " + $minikube_ip + "\n}"
' | kubectl apply -f -

# Restart CoreDNS to apply changes
kubectl rollout restart deployment coredns -n kube-system

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
