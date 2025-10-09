# Toggle Stack Scripts

Utilities for enabling or disabling optional infrastructure components (NodeGroup, RDS, ALB, ECR VPCE).

- `apply.sh` now refreshes kubeconfig, runs Terraform, applies `target-app/k8s/ingress.yaml`, **waits for the ingress hostname**, and re-runs Terraform with `target_app_api_origin_domain_override` so CloudFront stays in sync. Set `DISABLE_CLOUDFRONT_REAPPLY=1` to skip the second apply.
- `destroy.sh` removes the ingress via `kubectl`, refreshes Terraform state, destroys resources, and waits for ENI/VPCE cleanup.
- `delete_ingress.sh` orchestrates a safe ingress deletion loop (with finalizer removal fallback).
- Both apply/destroy scripts load the RDS password from either `TF_VAR_rds_password` or (preferred) an SSM parameter specified via `RDS_PASSWORD_SSM_PARAMETER`.
