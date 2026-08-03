# Terraform owns shared platform services; Argo CD owns application workloads

Terraform owns OCI infrastructure and shared platform services, while Argo CD owns application workloads and their dedicated Kubernetes resources, including namespaces. We preserve this boundary because transferring stateful services such as storage and backup between lifecycle managers would add operational risk and complicate cluster bootstrap; any future transfer must be an explicit ownership handoff rather than concurrent management.
