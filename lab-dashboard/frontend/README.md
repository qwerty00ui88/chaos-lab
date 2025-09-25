# Lab Dashboard Frontend

React + Vite 기반으로 작성된 대시보드 UI입니다. Terraform 토글과 Chaos 실험 API를 호출하고, 실행된 태스크의 상태/로그를 조회할 수 있도록 구성했습니다.

## 개발 환경
- Node.js 20.x
- npm 10.x 이상 (pnpm/yarn도 사용 가능)

## 시작하기
```bash
cd lab-dashboard/frontend
npm install
npm run dev
```

기본적으로 `http://localhost:5173`에서 개발 서버가 실행되며, `/api` 경로는 `VITE_BACKEND_URL` 환경변수(기본값 `http://localhost:8080`)로 프록시됩니다.

```bash
VITE_BACKEND_URL=http://localhost:8080 \
VITE_LOG_STREAM_URL=http://localhost:8090/api/logs/stream \
VITE_LOG_STREAM_POST_URL=http://localhost:8090/api/logs \
npm run dev
```

## 빌드
```bash
npm run build
npm run preview
```

`dist/` 폴더가 생성되며, Nginx 또는 Lightsail 인스턴스에서 그대로 서비스할 수 있습니다.

## 주요 화면
- **Terraform Controls**: `/api/terraform/apply`, `/destroy`, `/helm/rollout` 엔드포인트를 호출하는 버튼.
- **Chaos Experiments**: Pod crash(라벨/네임스페이스 지정), Order latency, CPU high, OOM, DB failover 실행.
- **Recent Tasks**: `terraform-client`에서 수집한 태스크 목록과 로그 뷰어. 5초 간격으로 자동 갱신됩니다.
- **Live Logs**: SSE로 스트리밍되는 `log-streamer` 로그와 테스트용 수동 전송 폼.

## 연동 전 체크리스트
- 백엔드(`terraform-client`, `chaos-injector`)가 `http://localhost:8080`에서 실행 중인지 확인.
- 쿠버네티스 API를 호출하려면 `chaos-injector` 측에 `KUBECONFIG`/`TARGET_BASE_URL` 환경변수를 설정해 주세요.

## 다음 단계 아이디어
- SSE 기반 로그 스트리머 연결
- 실행 이력 필터링/검색
- 작업 진행 상황 Progress Indicator
