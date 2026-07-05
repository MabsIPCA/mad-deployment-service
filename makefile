
.PHONY: start-minikube-k8s
start-minikube-k8s:
	k8s/minikube_setup.sh
	k8s/install.sh

.PHONY: start-minikube-helm
start-minikube-helm:
	k8s/minikube_setup.sh
	sleep 10
	helm dependency build ./helm/madgoat-infra
	helm dependency build ./helm/madgoat
	helm install madgoat ./helm/madgoat

# ---------------------------------------------------------------------------
# Vulnerability benchmark targets
# ---------------------------------------------------------------------------

# All vulnerability flags — default=true (vulnerable benchmark mode)
VULN_FLAGS := \
  --set global.vulnerabilities.k01_runAsRoot=true \
  --set global.vulnerabilities.k01_readOnlyRootFs=true \
  --set global.vulnerabilities.k01_privileged=true \
  --set global.vulnerabilities.k01_unboundedResources=true \
  --set global.vulnerabilities.k02_clusterAdminBinding=true \
  --set global.vulnerabilities.k02_secretsListWatch=true \
  --set global.vulnerabilities.k03_plaintextConfigMapSecrets=true \
  --set global.vulnerabilities.k03_jwtKeyInEnv=true \
  --set global.vulnerabilities.k05_noDefaultDeny=true \
  --set global.vulnerabilities.k05_permissiveNetpol=true \
  --set global.vulnerabilities.k05_noEgressControls=true \
  --set global.vulnerabilities.k06_traefikDashboardExposed=true \
  --set global.vulnerabilities.k06_rabbitmqMgmtExposed=true \
  --set global.vulnerabilities.k09_anonymousKeycloakBootstrap=true \
  --set global.vulnerabilities.k09_sharedServiceAccount=true

SAFE_FLAGS := \
  --set global.vulnerabilities.k01_runAsRoot=false \
  --set global.vulnerabilities.k01_readOnlyRootFs=false \
  --set global.vulnerabilities.k01_privileged=false \
  --set global.vulnerabilities.k01_unboundedResources=false \
  --set global.vulnerabilities.k02_clusterAdminBinding=false \
  --set global.vulnerabilities.k02_secretsListWatch=false \
  --set global.vulnerabilities.k03_plaintextConfigMapSecrets=false \
  --set global.vulnerabilities.k03_jwtKeyInEnv=false \
  --set global.vulnerabilities.k05_noDefaultDeny=false \
  --set global.vulnerabilities.k05_permissiveNetpol=false \
  --set global.vulnerabilities.k05_noEgressControls=false \
  --set global.vulnerabilities.k06_traefikDashboardExposed=false \
  --set global.vulnerabilities.k06_rabbitmqMgmtExposed=false \
  --set global.vulnerabilities.k09_anonymousKeycloakBootstrap=false \
  --set global.vulnerabilities.k09_sharedServiceAccount=false

.PHONY: deploy-vulnerable
deploy-vulnerable:
	helm dependency build ./helm/madgoat-infra
	helm dependency build ./helm/madgoat
	helm upgrade --install madgoat ./helm/madgoat $(VULN_FLAGS)

.PHONY: deploy-safe
deploy-safe:
	helm dependency build ./helm/madgoat-infra
	helm dependency build ./helm/madgoat
	helm upgrade --install madgoat ./helm/madgoat $(SAFE_FLAGS)
	kubectl delete -k k8s/insecure-defaults/ --ignore-not-found

.PHONY: reset-vulnerable
reset-vulnerable:
	minikube delete --all 2>/dev/null || true
	minikube start --cpus 8 --memory 20000MB \
	  --extra-config=kubelet.anonymous-auth=true \
	  --extra-config=kubelet.authorization-mode=AlwaysAllow
	minikube addons enable ingress
	minikube addons enable ingress-dns
	sleep 10
	kubectl apply -f https://github.com/kyverno/kyverno/releases/download/v1.12.0/install.yaml
	kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=kyverno -n kyverno --timeout=120s
	MINIKUBE_IP=$$(minikube ip) && \
	  kubectl get configmap coredns -n kube-system -o json | \
	  jq --arg ip "$$MINIKUBE_IP" '.data.Corefile += "madgoat.tech:53 {\n    errors\n    cache 30\n    forward . " + $$ip + "\n}"' | \
	  kubectl apply -f -
	kubectl rollout restart deployment coredns -n kube-system
	sleep 5
	make deploy-vulnerable
	kubectl apply -k k8s/insecure-defaults/

.PHONY: reset-safe
reset-safe:
	minikube delete --all 2>/dev/null || true
	minikube start --cpus 8 --memory 20000MB
	minikube addons enable ingress
	minikube addons enable ingress-dns
	sleep 10
	MINIKUBE_IP=$$(minikube ip) && \
	  kubectl get configmap coredns -n kube-system -o json | \
	  jq --arg ip "$$MINIKUBE_IP" '.data.Corefile += "madgoat.tech:53 {\n    errors\n    cache 30\n    forward . " + $$ip + "\n}"' | \
	  kubectl apply -f -
	kubectl rollout restart deployment coredns -n kube-system
	sleep 5
	make deploy-safe

.PHONY: verify-exploit-%
verify-exploit-%:
	@bash scripts/exploits/$*.sh

.PHONY: gen-thesis-tables
gen-thesis-tables:
	bash thesis/kubernetes-vulns/scripts/gen-tables.sh

# ---------------------------------------------------------------------------

.PHONY: build-and-push-file-copy-images
build-and-push-file-copy-images:
	docker build -t ghcr.io/mad-goat-project/db-lesson:data -f k8s/db/image/dockerfile . --build-arg SRC_PATH=./compose/data/db-lesson-service --build-arg ENTRYPOINT_PATH=./k8s/db/image
	docker build -t ghcr.io/mad-goat-project/minio:data -f k8s/db/image/dockerfile . --build-arg SRC_PATH=./compose/data/minio-data --build-arg ENTRYPOINT_PATH=./k8s/db/image
	docker build -t ghcr.io/mad-goat-project/mc-minio:mc-minio -f k8s/infra/minio/image/Dockerfile .
	docker push ghcr.io/mad-goat-project/db-lesson:data
	docker push ghcr.io/mad-goat-project/minio:data
	docker push ghcr.io/mad-goat-project/mc-minio:mc-minio