# Install Traefik Ingress Controller through Helm
helm install traefik traefik/traefik --values values.yaml
kubectl apply -f dashboard.yaml   
kubectl port-forward $(kubectl get pods --selector "app.kubernetes.io/name=traefik" --output=name) 9000:9000