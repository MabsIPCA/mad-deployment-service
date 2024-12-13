.PHONY: start-minikube-wsl-proxy
start-minikube-wsl-proxy:
	cd k8s/infra/traefik && proxy.sh

.PHONY: start-minikube-k8s
start-minikube-k8s:
	k8s/infra/traefik/install.sh
	make start-minikube-wsl-proxy

