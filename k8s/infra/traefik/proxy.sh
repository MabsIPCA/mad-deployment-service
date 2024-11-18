docker build -f proxy.Dockerfile -t proxy-app-mad:latest .
docker run --network minikube -d -p 80:80 -p 8080:8080 --name proxy-app-mad proxy-app-mad