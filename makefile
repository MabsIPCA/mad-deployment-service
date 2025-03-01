.PHONY: start-minikube-wsl-proxy
start-minikube-wsl-proxy:
	cd k8s/infra/traefik && proxy.sh

.PHONY: start-minikube-k8s
start-minikube-k8s:
	k8s/infra/traefik/install.sh
	make start-minikube-wsl-proxy

.PHONY: build-and-push-file-copy-images
build-and-push-file-copy-images:
	docker build -t mabsipca/db-keycloak:data -f k8s/db/image/dockerfile . --build-arg SRC_PATH=./compose/data/db-keycloak-service --build-arg ENTRYPOINT_PATH=./k8s/db/image
	docker build -t mabsipca/db-lesson:data -f k8s/db/image/dockerfile . --build-arg SRC_PATH=./compose/data/db-lesson-service --build-arg ENTRYPOINT_PATH=./k8s/db/image
	docker push mabsipca/db-keycloak:data
	docker push mabsipca/db-lesson:data
