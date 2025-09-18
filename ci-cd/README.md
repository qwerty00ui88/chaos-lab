# CI/CD Playbooks

This folder hosts reusable GitHub Actions workflows and documentation for the build/deploy pipelines.

## Workflows

- `.github/workflows/build-and-push.yml` — builds application artifacts (Spring Boot services + React frontend) and publishes container images to Amazon ECR.
- `.github/workflows/deploy-eks.yml` — deploys backend services to EKS via Helm (**todo**: wire once manifests are ready).
- `.github/workflows/deploy-frontend.yml` — deploys the React frontend to S3/CloudFront (**todo**: hook in when infra is provisioned).
- `templates/` — space for additional reusable snippets or environment-specific workflow examples.

## Required GitHub secrets / variables

| Name | Type | Description |
| --- | --- | --- |
| `AWS_ROLE_TO_ASSUME` | Secret | IAM role ARN assumed via OIDC (optional if you provide static keys). |
| `AWS_ACCESS_KEY_ID` | Secret | Access key for legacy auth (optional, use only if no role). |
| `AWS_SECRET_ACCESS_KEY` | Secret | Secret key for legacy auth (optional). |
| `AWS_REGION` | Repository variable | Default AWS region (e.g. `ap-northeast-2`). |
| `ECR_REGISTRY` | Repository variable | ECR registry URI (e.g. `446447036578.dkr.ecr.ap-northeast-2.amazonaws.com`). |
| `ECR_REPOSITORY_PREFIX` | Repository variable | Prefix used when tagging images (e.g. `chaos-lab`). |

## Build & push workflow notes

- Backend matrix entries (svc-user/catalog/order) run Maven via the wrapper before building Docker images.
- The frontend entry installs dependencies with `npm ci`, runs `npm run build`, then packages the Docker image.
- Image tags default to `GITHUB_SHA`; adjust in the workflow if you prefer semantic versioning.
- The composite action in `.github/actions/aws-setup` centralises AWS credential config and ECR login.

Future tasks: add deployment workflows once Helm charts and S3 distribution scripts are finalised.
