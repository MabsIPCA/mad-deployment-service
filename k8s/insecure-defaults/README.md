# k8s/insecure-defaults

Cluster-level misconfiguration artifacts for OWASP K8s Top 10 (K04, K07, K10).
These are **not** Helm charts — apply them with kustomize after cluster bootstrap.

## Apply (vulnerable mode)
kubectl apply -k k8s/insecure-defaults/

## Remove (safe mode)
kubectl delete -k k8s/insecure-defaults/ --ignore-not-found

## Note
K07 (kubelet flags) and K10 (audit policy) require Minikube restart with
specific --extra-config flags. See makefile targets reset-vulnerable / reset-safe.
