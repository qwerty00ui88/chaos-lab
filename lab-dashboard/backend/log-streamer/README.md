# Log Streamer Service

Spring Boot(WebFlux) 기반 SSE(Server-Sent Events) 엔드포인트를 제공하여 대시보드에서 로그를 실시간으로 받을 수 있도록 합니다. 현재는 실 검증 전이므로 2초 간격으로 더미 로그를 생성하며, 추후 CloudWatch Logs 또는 Terraform/Chaos 작업 로그와 연동할 예정입니다.

## API
- `GET /api/logs/stream` — `text/event-stream` 으로 로그 이벤트(`LogEvent`)를 지속적으로 전송합니다.
- `POST /api/logs` — 외부에서 수집된 로그를 주입할 수 있는 엔드포인트 (향후 백엔드 연동용).

## 실행
```bash
cd lab-dashboard/backend/log-streamer
mvn spring-boot:run
```

기본 포트는 8090입니다. 대시보드 프런트엔드에서 SSE를 연결할 때 `http://localhost:8090/api/logs/stream` 을 구독하면 됩니다.

## CloudWatch Logs 연동
`application.yml` 또는 환경변수에서 아래 값을 설정하면 CloudWatch 로그 그룹을 주기적으로 폴링해 SSE로 전달합니다.

```yaml
logstream:
  cloudwatch:
    enabled: true
    region: ap-northeast-2
    log-group-name: /aws/eks/chaos-lab/cluster
    log-stream-prefix: svc-order
    poll-interval-seconds: 5
    max-events: 100
```

* IAM 권한: `logs:FilterLogEvents` 권한을 포함해야 합니다.
* Demo 로그가 필요 없다면 `logstream.demo.enabled=false`로 끌 수 있습니다.

## TODO
- Terraform/Chaos 태스크 로그 파이프라인 통합
- 로그 레벨/서비스 필터 지원, 히스토리 보관 옵션 추가
