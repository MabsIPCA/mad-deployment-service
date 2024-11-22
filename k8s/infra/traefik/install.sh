MINIKUBE_CONTAINER=$(docker ps -aqf name=minikube)

if [ -n "$MINIKUBE_CONTAINER" ]; then
  echo "Minikube container found. Please delete the exising Minikube setup and try again."
  exit 1
else
  echo "No Minikube setup found. Initializing MAD GOAT Minikube."
fi

minikube start --ports 30340:30340

echo "Waiting for the 'default' service account in the default namespace..."
# Track elapsed time
ELAPSED=0
INTERVAL=1
while true; do
  # Check if the default service account exists
  if kubectl get serviceaccount default -n default &>/dev/null; then
    echo "Service account 'default' is ready in the default namespace."
    break
  fi
  # Increment elapsed time and wait
  sleep "$INTERVAL"
  ELAPSED=$((ELAPSED + INTERVAL))

done

kubectl apply -f k8s/infra/files.yaml

# Install Traefik Ingress Controller through Helm
helm install traefik traefik/traefik --values k8s/infra/traefik/values.yaml
kubectl apply -f k8s/infra/traefik/dashboard.yaml

kubectl apply -f k8s/envs
kubectl apply -f k8s/db/db-lesson-service-claim0-persistentvolumeclaim.yaml
kubectl apply -f k8s/infra/keycloak/db-keycloak-service-claim0-persistentvolumeclaim.yaml

echo "Waiting for pod 'file-copy-pod' to be assigned to a node in the default namespace..."
# Track elapsed time
ELAPSED=0
INTERVAL=1
while true; do
  # Get the pod status
  STATUS=$(kubectl get pod file-copy-pod -n default -o jsonpath='{.status.phase}' 2>/dev/null)
  if [[ "$STATUS" == "Running" || "$STATUS" == "Succeeded" || "$STATUS" == "Failed" ]]; then
    echo "Pod 'file-copy-pod' is assigned and its current status is: $STATUS."
    break
  fi
  # Increment elapsed time and wait
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
