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

minikube service traefik -n kube-system

#docker build -f proxy.Dockerfile -t proxy-app-mad:latest .
#docker run --network minikube -d -p 80:80 --name proxy-app-mad proxy-app-mad