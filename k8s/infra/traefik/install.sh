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

# Step 1: Start the Traefik service in the background and retrieve its URL
nohup minikube service traefik --url > traefik-url.log 2>&1 &

# Step 3: Extract the URL from the log file
TRAFFIC_URL=$(grep -Eo 'http[s]?://[^ ]+' traefik-url.log | head -n 1)

# Step 3: Replace the placeholder with the Traefik URL in all files
find k8s/envs -type f -exec sed -i "s|{{ip-placeholder}}|$TRAFFIC_URL|g" {} +

echo "Waiting for the 'default' service account in the default namespace..."
# Track elapsed time
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

kubectl apply -f k8s/infra/files.yaml

kubectl apply -f k8s/infra/traefik/dashboard.yaml

kubectl apply -f k8s/envs
kubectl apply -f k8s/db/db-lesson-service-claim0-persistentvolumeclaim.yaml
kubectl apply -f k8s/infra/keycloak/db-keycloak-service-claim0-persistentvolumeclaim.yaml

echo "Waiting for pod 'file-copy-pod' to be assigned to a node in the default namespace..."

# Track elapsed time
ELAPSED=0
INTERVAL=1
while true; do
  STATUS=$(kubectl get pod file-copy-pod -n default -o jsonpath='{.status.phase}' 2>/dev/null)
  if [ "$STATUS" = "Running" ] || [ "$STATUS" = "Succeeded" ] || [ "$STATUS" = "Failed" ]; then
    echo "Pod 'file-copy-pod' is assigned and its current status is: $STATUS."
    break
  fi
  sleep "$INTERVAL"
  ELAPSED=$((ELAPSED + INTERVAL))
done

kubectl cp compose/data/db-keycloak-service/. file-copy-pod:/keycloak
kubectl cp compose/data/db-lesson-service/. file-copy-pod:/lesson

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
