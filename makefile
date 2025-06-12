
.PHONY: start-minikube-k8s
start-minikube-k8s:
	k8s/minikube_setup.sh
	k8s/install.sh

.PHONY: build-and-push-file-copy-images
build-and-push-file-copy-images:
	docker build -t ghcr.io/mad-goat-project/db-lesson:data -f k8s/db/image/dockerfile . --build-arg SRC_PATH=./compose/data/db-lesson-service --build-arg ENTRYPOINT_PATH=./k8s/db/image
	docker build -t ghcr.io/mad-goat-project/minio:data -f k8s/db/image/dockerfile . --build-arg SRC_PATH=./compose/data/minio-data --build-arg ENTRYPOINT_PATH=./k8s/db/image
	docker build -t ghcr.io/mad-goat-project/mc-minio:mc-minio -f k8s/infra/minio/image/Dockerfile .
	docker push ghcr.io/mad-goat-project/db-lesson:data
	docker push ghcr.io/mad-goat-project/minio:data
	docker push ghcr.io/mad-goat-project/mc-minio:mc-minio