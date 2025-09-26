# Terraform Backend Migration (Local → S3)

대시보드에서 Terraform을 실행하려면 모든 환경이 동일한 상태 저장소를 공유해야 합니다. 기존에 로컬 파일(`infra/states/*.tfstate`)로 관리하던 스테이트를 S3/DynamoDB로 옮기는 절차는 다음과 같습니다.

## 1. 백엔드 리소스 생성

```bash
terraform -chdir=infra/bootstrap init
terraform -chdir=infra/bootstrap apply
```

필요한 리소스:
- S3 버킷: `chaos-lab-terraform-state`
- DynamoDB 테이블: `chaos-lab-terraform-locks`

이미 존재한다면 `apply`는 아무 변화 없이 종료됩니다.

## 2. 기존 스테이트 마이그레이션

각 스택에서 한 번씩 실행합니다.

```bash
terraform -chdir=infra/static init -migrate-state
terraform -chdir=infra/onoff init -migrate-state
```

> ⚠️ `-migrate-state`는 현재 디렉터리의 `terraform.tfstate`를 새 백엔드로 이동합니다. 실행 전 백업을 권장합니다.

## 3. 검증

```bash
terraform -chdir=infra/static plan
terraform -chdir=infra/onoff plan
```

두 명령 모두 `No changes`가 나오는지 확인하세요. 이후에는 다른 환경(예: 대시보드 EC2)에서도 같은 백엔드를 사용하게 됩니다.

## 4. 로컬 상태 파일 정리 (선택)

마이그레이션 후 `infra/states/` 폴더에 남아 있는 `.tfstate` / `.backup` 파일은 백업해 두고 삭제할 수 있습니다. (Git history에 남아 있으므로 조심해서 처리하세요.)
