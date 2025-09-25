# chaos-lab

> Chaos engineering sandbox on AWS: fully scriptable ON/OFF infrastructure with live dashboard and target workloads.

## Repository Layout (WIP)
- `infra/`: Terraform modules split into always-on and toggleable stacks.
- `target-app/`: Target frontend and microservices deployed onto EKS.
- `lab-dashboard/`: Lightsail-hosted control plane (Terraform runner, chaos injector, log streamer, UI).
- `lab-dashboard/deploy/lightsail`: docker-compose + Nginx assets for the Lightsail host.
- `.github/workflows/`: GitHub Actions for CI/CD (build, deploy backend, deploy frontend).
- `ci-cd/`: Shared pipeline templates and documentation.
- `docs/`: Architecture, runbooks, costs, presentation artifacts.
- `infra/modules/lightsail`: Terraform module for the Lightsail dashboard host (Docker + Terraform/Helm runtime).

## Roadmap Sprint (Sep 18 - Sep 30)
| Date | Theme |
| --- | --- |
| 9/18 | Repo bootstrap, Terraform scaffolding |
| 9/19 | Shared Terraform config, VPC module skeleton |
| 9/20 | Network resources implementation |
| 9/22 | EKS control plane provisioning |
| 9/23 | Static infra (ECR, Route53/ACM, Budgets) |
| 9/24 | CI pipeline foundation |
| 9/25 | ON/OFF Terraform modules |
| 9/26-27 | Lab dashboard backend & frontend |
| 9/29 | Target app services, ON/OFF rehearsal |
| 9/30 | E2E validation, documentation, release |

## Getting Started
1. Install toolchain: Terraform, AWS CLI v2, kubectl, Helm, Docker, Node.js, Java 17.
2. Configure AWS CLI profile with access to the chaos-lab account.
3. Provision Terraform backend once: `terraform -chdir=infra/bootstrap apply`.
4. Migrate existing state to S3: `terraform -chdir=infra/static init -migrate-state` and `terraform -chdir=infra/onoff init -migrate-state`.

## Status
- [ ] Infrastructure scaffolding
- [ ] Lab dashboard services
- [ ] Target application services
- [ ] CI/CD pipelines
- [ ] Documentation set

## Quick Commands
- `make static-plan` / `make static-apply`: Lightsail을 포함한 Static 스택을 검토/적용 (`infra/static/vars/base.tfvars` 사용).
- `make onoff-plan` / `make on`: 토글 스택(EKS, Fluent Bit 등)을 검토/기동.
- `make off`: 토글 스택 자원 제거.
- 스크립트 기반 워크플로는 `docs/runbook` 디렉터리를 참고하세요.
