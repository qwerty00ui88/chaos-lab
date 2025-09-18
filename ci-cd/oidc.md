# GitHub OIDC → AWS Role 연동 가이드

## 1. IAM Role 생성
1. AWS 콘솔 → IAM → 역할(Role) 생성
2. 신뢰하는 주체 선택: **웹 ID(Web identity)**
3. 공급자: `token.actions.githubusercontent.com`
4. Audience: `sts.amazonaws.com`
5. 조건(Condition): 리포지토리 제한을 위해 아래 정책 추가:
   ```json
   {
     "StringEquals": {
       "token.actions.githubusercontent.com:sub": "repo:YOUR-ORG/YOUR-REPO:ref:refs/heads/main"
     }
   }
   ```
   필요 시 `dev` 등 추가 브랜치는 OR 조건으로 허용.
6. 권한 정책: `AmazonEC2ContainerRegistryPowerUser`, `AmazonEKSClusterPolicy` 등 필요한 정책을 선택하거나, 최소 권한 커스텀 정책 생성.
7. 역할 이름 예시: `GitHubActionsChaosLabRole`

## 2. GitHub 리포지토리 설정
1. Settings → Secrets and variables → Actions → **Repository secrets**
2. `AWS_ROLE_TO_ASSUME` 이름으로 방금 만든 역할 ARN 입력 (예: `arn:aws:iam::123456789012:role/GitHubActionsChaosLabRole`).
3. `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`는 비워둠.
4. **Repository variables**에 `AWS_REGION`, `ECR_REGISTRY`, `ECR_REPOSITORY_PREFIX` 값 입력.

## 3. 워크플로에서 사용
- `.github/workflows/build-and-push.yml`에서는 내부 composite action(`.github/actions/aws-setup`)이 `role-to-assume`만으로 AWS 인증을 처리.
- GitHub가 OIDC 토큰을 주면 IAM Role이 임시 자격증명을 발급하고, 워크플로는 해당 세션으로 ECR push 등을 수행.
- Access Key를 저장하지 않으므로 보안 위험이 크게 줄어듬.

## 주의 사항
- IAM Role의 신뢰 정책에 허용하지 않은 브랜치/리포에서 실행하면 인증이 실패함.
- 브랜치가 여러 개인 경우 Condition에서 `StringLike` 등을 활용해 범위를 넓히면 편함.
- `aws-actions/configure-aws-credentials@v4`는 자동으로 OIDC를 사용하므로 추가 설정 불필요.
