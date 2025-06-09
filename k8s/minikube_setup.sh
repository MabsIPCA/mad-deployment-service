#!/bin/bash

MINIKUBE_CONTAINER=$(docker ps -aqf name=minikube)

if [ -n "$MINIKUBE_CONTAINER" ]; then
  echo "Minikube container found. Please delete the existing Minikube setup and try again."
  exit 1
else
  echo "No Minikube setup found. Initializing MAD GOAT Minikube."
fi

minikube start --cpus 8 --memory 20000MB
minikube addons enable ingress
minikube addons enable ingress-dns

sleep 5 # to allow cluster services to start

MINIKUBE_IP=$(minikube ip)
kubectl get configmap coredns -n kube-system -o yaml > coredns-backup.yaml

# Extract and modify Corefile, then update the ConfigMap
kubectl get configmap coredns -n kube-system -o json | jq --arg minikube_ip "$MINIKUBE_IP" '
    .data.Corefile += "madgoat.tech:53 {\n    errors\n    cache 30\n    forward . " + $minikube_ip + "\n}"
' | kubectl apply -f -

# Restart CoreDNS to apply changes
kubectl rollout restart deployment coredns -n kube-system