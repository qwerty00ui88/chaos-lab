# Dashboard EC2 Provisioning

대시보드 EC2 인스턴스는 Chaos Lab 컨트롤 플레인( Terraform/Helm 실행기, Chaos API, Log Streamer, UI )을 호스팅합니다.

## Terraform 위치
- 모듈: `infra/modules/ec2_dashboard`
- 호출: `infra/static/main.tf` (`enable_dashboard_instance` 토글로 제어)

## 기본 설정
- 기본 AMI: Ubuntu 22.04 (data source로 최신 버전 선택)
- 기본 인스턴스 타입: `t3.small` (`dashboard_instance_type` 변수로 변경 가능)
- SSH 키: `dashboard_key_pair_name`에 등록한 기존 EC2 KeyPair 사용
- 보안그룹: 22/80/443 포트를 `dashboard_allowed_cidrs`(기본 `0.0.0.0/0`)에 허용
- Git/Compose 자산
  - `dashboard_repo_url`: 대시보드 구성을 담은 Git 저장소 URL
  - `dashboard_repo_branch`: 체크아웃할 브랜치 (기본 `main`)
  - `dashboard_clone_path`: EC2에서 레포가 위치할 경로 (기본 `/opt/chaos-dashboard/app`)
- `dashboard_compose_path`: docker-compose 파일 상대 경로 (기본 `lab-dashboard/deploy/dashboard/docker-compose.yml`)

## user_data 부트스트랩
`templatefile("../modules/ec2_dashboard/templates/user_data.sh.tpl", …)`을 통해 아래 절차를 수행합니다.
- Docker, Terraform (`dashboard_terraform_version`), AWS CLI, kubectl (`dashboard_kubectl_version`), Helm 설치
- `/opt/chaos-dashboard/.env`에 ECR/클러스터 정보 기록
- Git 저장소 clone → `/opt/chaos-dashboard`에 docker-compose/nginx/config 동기화
- `aws ecr get-login-password`로 ECR 로그인 후 `docker compose pull && docker compose up -d`
- 실행 로그는 `/var/log/chaos-dashboard-bootstrap.log`에 저장됩니다.

## 적용 방법
1. `infra/static/vars/base.tfvars`에서 EC2 관련 변수(키페어, ECR 레지스트리 등)를 확인/수정합니다.
2. Static 스택 실행
   ```bash
   make static-plan   # terraform plan -var-file=vars/base.tfvars
   make static-apply  # terraform apply -var-file=vars/base.tfvars
   ```
   직접 Terraform CLI를 사용할 경우 `-var-file=infra/static/vars/base.tfvars` 플래그를 함께 지정합니다.
3. 출력 값 `dashboard_public_ip`로 SSH 접속하여 `/opt/chaos-dashboard`에서 컨테이너 상태(`docker compose ps`)를 확인합니다.
4. 대시보드에서 토글 스택을 제어하려면 `make on` / `make off` (혹은 `terraform -chdir=infra/onoff ...`)을 실행해 Target 환경을 가동/중지합니다.

## 프로비저닝 이후 체크리스트
1. **이미지 빌드 자동화**: GitHub Actions `Build and Push Dashboard Images` 워크플로가 커밋마다 `terraform-client`, `chaos-injector`, `log-streamer`, `dashboard-frontend` 이미지를 ECR에 푸시합니다. 필요 시 `workflow_dispatch`로 수동 실행하세요.
2. **수동 빌드(옵션)**: 긴급 패치 시 로컬에서 `mvn -pl lab-dashboard/backend/<module> -am package` 혹은 `npm run build` 후 `docker build/push` 명령으로 동일한 리포지토리에 이미지를 올릴 수 있습니다.
3. **대시보드 배포**: user_data가 부팅 시 `docker compose pull && docker compose up -d`를 실행합니다. 이후 새 이미지를 적용하려면 EC2에 SSH 접속해 `scripts/static/update-dashboard-instance.sh`를 실행하거나 CI/CD에서 호출하세요.
4. **연동 검증**: 대시보드 UI에서 Terraform/Chaos 버튼이 토글 스택과 연동되는지, Live Logs 패널이 CloudWatch 이벤트를 수신하는지 확인합니다.
5. **정리 절차**: 실험 종료 시 `make off`로 토글 스택을 내리고, 필요하면 `docker compose down`으로 컨테이너를 중지합니다. 장시간 사용 계획이 없다면 `make static-destroy`로 EC2 및 공유 인프라도 제거해 비용을 절감하세요.

## 주의사항
- EC2에는 IAM Role이 자동으로 연결되지 않으므로, ECR Pull을 위해 user_data/갱신 스크립트에서 `aws ecr get-login-password`를 사용합니다.
- Git 저장소가 private인 경우 PAT/Deploy Key를 이용해 `dashboard_repo_url`에 인증 정보를 포함시키거나 user_data를 수정해야 합니다.
- 보안 그룹 CIDR은 운영 환경에 맞게 제한하세요.
