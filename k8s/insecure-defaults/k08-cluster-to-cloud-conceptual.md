# K08/2025 — Cluster-to-Cloud Lateral Movement (Conceptual)

This category has no locally reproducible exploit in a Minikube environment.
The following describes the attack paths for a managed Kubernetes cluster (EKS/GKE/AKE).

## K08a: IMDS Credential Theft

**Weakness:** On cloud-managed Kubernetes (EKS, GKE, AKE), pods can reach the
instance metadata service (IMDS) at 169.254.169.254 unless explicitly blocked.
An attacker with code execution in a pod (e.g., via RCE in lesson-service) can
request cloud IAM credentials assigned to the underlying node.

**Exploit path (EKS example):**
1. Gain code execution inside any pod (e.g., via CVE in lesson-service Node.js deps).
2. From inside the pod:
   curl http://169.254.169.254/latest/meta-data/iam/security-credentials/
3. Retrieve the role name, then:
   curl http://169.254.169.254/latest/meta-data/iam/security-credentials/<ROLE>
4. Use returned AccessKeyId / SecretAccessKey / Token with AWS CLI to access S3,
   SSM, ECR — whatever the node role permits.

**Mitigation:**
- EKS: enable IMDSv2 with hop limit=1 (`--metadata-options HttpTokens=required,HttpPutResponseHopLimit=1`).
- All clouds: block 169.254.169.254 via NetworkPolicy egress rules (covered by K05 safe mode).
- Use IRSA (EKS) / Workload Identity (GKE/AKE) to grant per-pod cloud permissions without node-level credentials.

## K08b: Projected SA Token to Cloud IAM

**Weakness:** If a pod mounts a Kubernetes ServiceAccount token and the cluster is
configured with OIDC federation to a cloud IAM provider (AWS IRSA / GCP WI / Azure WI),
a stolen SA token can be exchanged for cloud IAM credentials.

**Exploit path:**
1. Steal a pod's SA token: kubectl exec <pod> -- cat /var/run/secrets/kubernetes.io/serviceaccount/token
2. If the SA is bound to a cloud IAM role via annotation, exchange the token:
   aws sts assume-role-with-web-identity --web-identity-token file://token --role-arn <arn>
3. Use resulting credentials.

**Mitigation:** Scope IRSA/WI role bindings to least-privilege; use `automountServiceAccountToken: false`
on pods that do not need cloud API access (covered by K09 safe mode).

**References:** See thesis references.bib entries: aws-irsa, gke-workload-identity, azure-workload-identity.
