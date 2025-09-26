# Terraform Client Service

Spring Boot 서비스로, 대시보드에서 Terraform/Helm 스크립트를 실행할 수 있도록 REST API를 제공합니다.

## 기본 동작
- 실행할 스크립트는 `application.yml`의 `chaoslab.scripts.*` 경로로 설정합니다. 기본값은 로컬 실행 시 `../../../scripts`(저장소 루트의 `scripts` 폴더)이며, 운영 환경에서는 `CHAOSLAB_SCRIPTS_BASE` 환경변수로 덮어씁니다.
- 모든 스크립트 실행은 비동기 태스크로 저장되며, 표준 출력/에러가 로그 버퍼에 적재됩니다.

## 주요 API
| 메서드 | 경로 | 기능 |
| --- | --- | --- |
| `POST` | `/api/terraform/apply` | Terraform on/off 스택 `apply.sh` 실행 |
| `POST` | `/api/terraform/destroy` | Terraform on/off 스택 `destroy.sh` 실행 |
| `POST` | `/api/helm/rollout` | `helm-rollout.sh` 실행 |
| `GET` | `/api/tasks` | 최근 태스크 요약 목록 조회 |
| `GET` | `/api/tasks/{id}` | 특정 태스크의 상태와 로그 조회 |

### 요청 예시
```http
POST /api/terraform/apply
Content-Type: application/json

{
  "environment": {
    "AWS_PROFILE": "chaos-lab",
    "TF_LOG": "INFO"
  },
  "args": ["-var", "environment=dev"]
}
```

### 응답 예시
```json
{ "taskId": "a2c7b3f5-..." }
```

태스크 상태는 `/api/tasks/{taskId}`로 확인합니다.

## 주의사항
- 스크립트는 실행 권한이 있어야 하며, 실패 시 표준 에러와 종료 코드가 태스크에 기록됩니다.
- 장기적으로는 로그 스트리밍/SSE 구현을 위해 `TaskRecord` 로그 버퍼를 재사용할 수 있습니다.
