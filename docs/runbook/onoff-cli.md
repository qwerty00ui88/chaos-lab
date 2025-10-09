# ON/OFF Automation Scripts

대시보드 백엔드에서 Terraform/Helm을 호출하기 전에 로컬에서 스크립트를 통해 검증할 수 있습니다.

## 1. Terraform 토글 스택 적용/제거

```bash
scripts/onoff/apply.sh    # vars/base.tfvars + vars/toggles.tfvars 를 사용하여 apply
scripts/onoff/destroy.sh  # 동일한 변수 파일을 사용하여 destroy
```

- 추가 변수 파일이 필요한 경우 `TF_CLI_ARGS_apply` 등 Terraform 환경변수를 사용하세요.
- `vars/toggles.tfvars` 안의 `enable_*` 값을 변경해 ON/OFF 조합을 조절합니다.
- apply 스크립트는 ALB Ingress가 퍼블릭 호스트네임을 받을 때까지 기다렸다가 `target_app_api_origin_domain_override` 값을 이용해 한 번 더 `terraform apply`를 실행합니다. (필요 시 `DISABLE_CLOUDFRONT_REAPPLY=1`로 비활성화 가능)

## 2. Helm 롤아웃

ECR 레지스트리와 리포지토리 프리픽스를 환경변수로 지정한 뒤 실행합니다.

```bash
export ECR_REGISTRY=446447036578.dkr.ecr.ap-northeast-2.amazonaws.com
export ECR_REPOSITORY_PREFIX=chaos-lab
scripts/onoff/helm-rollout.sh        # svc-user, svc-catalog, svc-order 순서로 upgrade/install
scripts/helm/undeploy-service.sh svc-user    # 개별 서비스 제거
```

기본 이미지 태그는 현재 Git 커밋 SHA입니다. 다른 태그를 사용하려면 `IMAGE_TAG=... scripts/onoff/helm-rollout.sh` 형태로 호출하세요.

## 3. 대시보드 EC2 연동 시 고려사항

- 대시보드 EC2 인스턴스에 Terraform, AWS CLI v2, kubectl, Helm을 설치합니다 (user_data로 자동 설치되도록 구성되어 있음).
- `AWS_REGION`, `ECR_REGISTRY`, `ECR_REPOSITORY_PREFIX`, `KUBE_NAMESPACE` 등의 환경변수를 서비스 시작 시에 주입합니다.
- IAM Role 또는 Access Key는 Terraform on/off 리소스와 EKS/Helm 배포에 필요한 최소 권한을 포함해야 합니다.
