# K10/2025 — No Apiserver Audit Policy (Documented Absence)

The default MAD Goat benchmark cluster starts Minikube without an audit policy.
This means no Kubernetes API operations are logged to an audit backend.

**To reproduce (verify absence):**
minikube ssh -- ps aux | grep kube-apiserver | grep audit

**To apply safe mode (audit-policy-safe.yaml):**
1. Copy audit-policy-safe.yaml to the Minikube node:
   minikube cp k8s/insecure-defaults/audit-policy-safe.yaml /etc/kubernetes/audit-policy.yaml
2. Restart kube-apiserver with audit flags (minikube start flags or kubeadm patch):
   --audit-policy-file=/etc/kubernetes/audit-policy.yaml
   --audit-log-path=/var/log/kubernetes/audit.log
   --audit-log-maxage=30
   --audit-log-maxbackup=3
   --audit-log-maxsize=100
