# CI/CD Playbooks

This folder hosts reusable GitHub Actions workflows and documentation for the build/deploy pipelines.

- `build-and-push.yml` — builds application artifacts and pushes Docker images to ECR.
- `deploy-eks.yml` — deploys backend services to EKS via Helm.
- `deploy-frontend.yml` — deploys the React frontend to S3/CloudFront.
- `templates/` — space for additional reusable snippets or environment-specific workflow examples.
