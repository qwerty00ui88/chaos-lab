# Terraform Backend Bootstrap

이 디렉터리는 Terraform 상태 관리를 위한 S3 버킷과 DynamoDB 테이블을 한 번만 생성하는 스택입니다.

## 사용 방법

```bash
terraform -chdir=infra/bootstrap init
terraform -chdir=infra/bootstrap apply
```

기본값은 다음과 같습니다.
- S3 버킷: `chaos-lab-terraform-state`
- DynamoDB 테이블: `chaos-lab-terraform-locks`
- 리전: `ap-northeast-2`

필요하면 `-var` 또는 `terraform.tfvars`로 이름/리전을 조정하세요.

리소스가 이미 존재한다면 이 스택은 아무 변화 없이 종료됩니다.
