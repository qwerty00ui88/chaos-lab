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

> 실제 도커 컴포즈 실행은 추후 CI/CD 또는 수동 스크립트로 트리거해야 합니다. (부트스트랩 스크립트는 실행 로그를 `/var/log/chaos-dashboard-bootstrap.log`에 저장합니다.)

## 적용 방법
```bash
terraform -chdir=infra/static plan
terraform -chdir=infra/static apply
```

## 주의사항
- Lightsail은 IAM 역할을 직접 연결할 수 없으므로 Access Key 또는 SSM Parameter Store를 이용해 애플리케이션에 자격 증명을 전달해야 합니다.
- `lightsail_ecr_registry`, `lightsail_ecr_repository_prefix`, `lightsail_eks_cluster_name` 변수 값은 실제 환경에 맞게 설정하세요.
