# Lightsail Dashboard Provisioning

Lightsail 인스턴스는 Chaos Lab 대시보드를 호스팅하며 Terraform/Helm 실행 환경을 제공합니다.

## Terraform 위치
- 모듈: `infra/modules/lightsail`
- 호출: `infra/static/main.tf` (`enable_lightsail` 토글로 제어)

## 기본 설정
- Blueprint: Ubuntu 22.04 (`ubuntu_22_04`)
- Bundle: `nano_2_0`
- AZ: `ap-northeast-2a`
- Static IP 자동 할당
- 오픈 포트: 80, 443 (추가 필요 시 `lightsail_allowed_ports` 수정)
- Git Repo / Compose
  - `lightsail_dashboard_repo_url`: 대시보드 코드를 가져올 Git 저장소 URL
  - `lightsail_dashboard_repo_branch`: 체크아웃할 브랜치 (기본 `main`)
  - `lightsail_dashboard_clone_path`: Lightsail에서 레포가 위치할 경로 (기본 `/opt/chaos-dashboard/app`)
  - `lightsail_dashboard_compose_path`: docker-compose 파일의 상대 경로 (기본 `lab-dashboard/deploy/lightsail/docker-compose.yml`)

## user_data 부트스트랩
`templatefile`을 사용하여 다음 도구를 설치합니다.
- Docker
- Terraform (`lightsail_terraform_version`)
- AWS CLI v2
- kubectl (`lightsail_kubectl_version`)
- Helm 3

또한 `/opt/chaos-dashboard/.env`에 아래 값을 기록합니다.
- `AWS_REGION`
- `ECR_REGISTRY`
- `ECR_REPOSITORY_PREFIX`
- `EKS_CLUSTER_NAME`
- `DASHBOARD_REPO_ROOT`
- `TERRAFORM_CLIENT_TAG`, `CHAOS_INJECTOR_TAG`, `LOG_STREAMER_TAG`, `FRONTEND_TAG`

> 실제 도커 컴포즈 실행은 추후 CI/CD 또는 수동 스크립트로 트리거해야 합니다. (부트스트랩 스크립트는 실행 로그를 `/var/log/chaos-dashboard-bootstrap.log`에 저장합니다.)

## 적용 방법
1. `infra/static/vars/base.tfvars`에서 Lightsail 관련 변수(ECR 레지스트리, EKS 클러스터명 등)를 확인하고 필요 시 수정합니다.
2. 아래 중 하나의 명령으로 Static 스택을 실행합니다.
   ```bash
   make static-plan   # terraform plan -var-file=vars/base.tfvars
   make static-apply  # terraform apply -var-file=vars/base.tfvars
   ```
   또는 직접 Terraform CLI를 사용할 경우 `-var-file=infra/static/vars/base.tfvars` 플래그를 함께 지정하세요.
3. 출력되는 `lightsail_dashboard_ip`로 SSH 접속하여 `/opt/chaos-dashboard` 경로에 대시보드 런타임(Compose 파일 등)을 배치합니다.
4. 대시보드에서 토글 스택을 제어하려면 별도로 `make on` / `make off` (혹은 `terraform -chdir=infra/onoff ...`)을 실행해 Target 환경을 가동/중지합니다.

## 프로비저닝 이후 체크리스트
1. **이미지 빌드 자동화**: GitHub Actions `Build and Push Dashboard Images` workflow가 커밋마다 `terraform-client`, `chaos-injector`, `log-streamer`, `dashboard-frontend` 이미지를 ECR에 푸시합니다. (필요 시 `workflow_dispatch`로 수동 실행 가능)
2. **수동 빌드(옵션)**: 긴급 패치 시 로컬에서 `mvn -pl lab-dashboard/backend/<module> -am package` 혹은 `npm run build` 후 `docker build/push` 명령으로 동일한 리포지토리에 이미지를 올릴 수 있습니다.
3. **Lightsail 배포**: SSH로 접속해 `/opt/chaos-dashboard`에서 `aws ecr get-login-password --region <REGION> | docker login --username AWS --password-stdin <ECR_REGISTRY>`로 인증한 뒤 `docker compose pull && docker compose up -d`를 실행합니다. (부트스트랩이 자동 실행되므로 실패 시 `/var/log/chaos-dashboard-bootstrap.log` 확인)
4. **연동 검증**: 대시보드 UI에서 Terraform/Chaos 버튼을 눌러 토글 스택이 실행되는지, Live Logs 패널이 CloudWatch 이벤트를 수신하는지 확인합니다.
5. **정리 절차**: 실험 종료 시 `make off`로 토글 스택을 내리고, Lightsail 컨테이너도 `docker compose down`으로 정지합니다.

## 주의사항
- Lightsail은 IAM 역할을 직접 연결할 수 없으므로 Access Key 또는 SSM Parameter Store를 이용해 애플리케이션에 자격 증명을 전달해야 합니다.
- `lightsail_ecr_registry`, `lightsail_ecr_repository_prefix`, `lightsail_eks_cluster_name` 변수 값은 실제 환경에 맞게 설정하세요.
