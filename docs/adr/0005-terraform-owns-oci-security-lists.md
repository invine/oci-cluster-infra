# Terraform exclusively owns OCI security lists

Terraform owns each OCI security list and its complete rule set, so OKE LoadBalancer Services explicitly disable controller security-list management. We chose exclusive Terraform ownership over concurrent controller mutation because controller-created inline rules caused recurring full-plan drift and made an approved Infrastructure apply race another reconciler; LoadBalancer connectivity must instead be satisfied by reviewed Terraform-managed rules, while controller-managed load balancers remain Generated Resources.
