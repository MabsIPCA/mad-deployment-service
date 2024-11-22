MINIKUBE_CONTAINER=$(docker ps -aqf name=minikube)

if [ -n "$MINIKUBE_CONTAINER" ]; then
  echo "Minikube container found. Please delete the exising Minikube setup and try again."
  exit 1
else
  echo "No Minikube setup found. Initializing MAD GOAT Minikube."
fi

minikube start --ports 30340:30340
minikube mount $(pwd):/host

# Install Traefik Ingress Controller through Helm
helm install traefik traefik/traefik --values k8s/infra/traefik/values.yaml
kubectl apply -f k8s/infra/traefik/dashboard.yaml

kubectl apply -f k8s/envs
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

