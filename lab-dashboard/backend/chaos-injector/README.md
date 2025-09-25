# Chaos Injector Service

Spring Boot 애플리케이션으로, 실습 환경의 장애 시나리오를 API 형태로 제공하여 Lab Dashboard에서 호출할 수 있도록 합니다.

## 지원 시나리오
- `POST /api/chaos/pod-crash` — Kubernetes API를 통해 라벨 셀렉터와 일치하는 Pod를 삭제하여 Crash 복구를 관찰합니다.
- `POST /api/chaos/order-latency` — 타깃 앱의 `/order/slow` 엔드포인트를 호출해 응답 지연을 유발합니다.
- `POST /api/chaos/cpu-high` — `/faults/cpu?sec={n}` 엔드포인트를 호출해 CPU 부하를 트리거합니다.
- `POST /api/chaos/oom` — `/faults/oom` 엔드포인트를 호출해 OOMKilled 이벤트를 유도합니다.
- `POST /api/chaos/db-failover` — 데이터베이스 장애 시나리오용 엔드포인트(`/faults/db/failover`)를 호출합니다.

응답은 `ChaosActionResponse` 형태이며, 실행 상태(`SUCCESS`/`FAILURE`)와 세부 정보를 포함합니다.

## Kubernetes 설정
`application.yml` (또는 환경 변수)에서 다음 값을 조절할 수 있습니다.

```yaml
chaoslab:
  kubernetes:
    namespace: target-app         # 기본 네임스페이스
    config-path: ${KUBECONFIG:}   # kubeconfig 경로 (미지정 시 In-Cluster 또는 기본 로딩)
    context: ${KUBECONTEXT:}      # kubeconfig 컨텍스트
  target:
    base-url: http://target.chaos-lab.org
```

Pod 삭제는 `config-path`/`context`로 지정된 자격 증명을 사용합니다. 삭제 대상은 `labelSelector`로 전달한 라벨과 일치하는 Pod 중 최대 `maxPods`개입니다.

## 로컬 QA 팁
- Kubernetes API를 직접 호출하므로, 로컬에서 테스트할 때는 `minikube` 등 접근 가능한 클러스터와 kubeconfig가 필요합니다. `KUBECONFIG` 환경 변수를 지정하세요.
- 타깃 애플리케이션이 없을 경우, `TARGET_BASE_URL`을 임시 Mock 서버 주소로 바꾸거나 `WebClient` 호출 실패 메시지가 응답으로 반환됩니다.
- Helm/Pod 삭제 등 실제 리소스 변화가 부담될 경우, 대시보드나 테스트 코드에서 `DRY_RUN`형 래퍼를 추가해 두면 안전합니다.
