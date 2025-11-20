# 네트워크 폴리시 배포 가이드

## 📁 파일 구조

```
network-policies/
├── jobs-app/              # 메인 애플리케이션 네임스페이스 (3-tier 구조)
│   ├── 00-default-deny.yaml          ✅ 필수
│   ├── 01-allow-dns.yaml             ✅ 필수
│   ├── 02-allow-registry.yaml        ✅ 필수
│   ├── 03-allow-frontend-to-backend.yaml  ✅ 필수
│   ├── 04-allow-backend-to-mongodb.yaml   ✅ 필수
│   ├── 06-allow-backend-external.yaml     ✅ 필수
│   ├── optional/                     📁 선택사항
│   │   ├── 07-allow-monitoring.yaml
│   │   ├── 08-allow-cicd.yaml
│   │   └── README.md
│   ├── REQUIRED-POLICIES.md          📄 정책 설명
│   └── README.md                     📄 배포 가이드
├── monitoring/            # 모니터링 네임스페이스 (선택사항)
│   ├── 00-default-deny.yaml
│   ├── 01-allow-dns.yaml
│   ├── 02-allow-registry.yaml
│   └── 03-allow-metrics-collection.yaml
├── ci-cd/                 # CI/CD 네임스페이스 (선택사항)
│   ├── 00-default-deny.yaml
│   ├── 01-allow-dns.yaml
│   ├── 02-allow-registry.yaml
│   ├── 03-allow-external.yaml
│   └── 04-allow-jobs-app.yaml
├── deploy-all.sh          # 자동 배포 스크립트
├── README.md              # 이 파일
├── DEPLOYMENT-CHECKLIST.md # 배포 체크리스트
├── SUMMARY.md             # 요약 문서
├── NGROK-NOTES.md         # ngrok 사용 가이드
└── NODEPORT-NOTES.md      # NodePort 사용 가이드
```

## 🚀 배포 방법

### 1. 네임스페이스 라벨 확인 및 설정

배포 전에 각 네임스페이스에 적절한 라벨이 설정되어 있어야 합니다:

```bash
# jobs-app 네임스페이스 라벨 확인
kubectl get namespace jobs-app --show-labels

# 라벨이 없다면 추가
kubectl label namespace jobs-app name=jobs-app

# Ingress Controller 네임스페이스 라벨 확인 (일반적으로 ingress-nginx 또는 kube-system)
kubectl get namespace ingress-nginx --show-labels
kubectl label namespace ingress-nginx name=ingress-nginx

# 모니터링 네임스페이스 라벨 (실제 네임스페이스 이름으로 변경)
kubectl label namespace monitoring name=monitoring

# CI/CD 네임스페이스 라벨 (실제 네임스페이스 이름으로 변경)
kubectl label namespace ci-cd name=ci-cd
# 또는
kubectl label namespace apps-job name=apps-job
```

### 2. jobs-app 네임스페이스 배포

**⚠️ 중요: 모든 파일을 한 번에 배포해야 합니다. Default Deny만 배포하면 모든 트래픽이 차단됩니다!**

**자동 배포 (권장):**
```bash
cd k8s/network-policies
./deploy-all.sh
```

**수동 배포:**
```bash
# 필수 정책만 배포 (3-tier 구조)
kubectl apply -f network-policies/jobs-app/

# 선택사항 정책 (필요 시)
kubectl apply -f network-policies/jobs-app/optional/07-allow-monitoring.yaml
kubectl apply -f network-policies/jobs-app/optional/08-allow-cicd.yaml
```

**필수 정책 (6개):**
- 00-default-deny.yaml
- 01-allow-dns.yaml
- 02-allow-registry.yaml
- 03-allow-frontend-to-backend.yaml
- 04-allow-backend-to-mongodb.yaml
- 06-allow-backend-external.yaml

### 3. 모니터링 네임스페이스 배포

```bash
# 모니터링 네임스페이스 이름 확인 후 파일 수정 필요
# monitoring 네임스페이스가 있다면:
kubectl apply -f network-policies/monitoring/
```

### 4. CI/CD 네임스페이스 배포

```bash
# CI/CD 네임스페이스 이름 확인 후 파일 수정 필요
# ci-cd 또는 apps-job 네임스페이스가 있다면:
kubectl apply -f network-policies/ci-cd/
```

## ✅ 배포 후 검증

### 1. 네트워크 폴리시 확인

```bash
# jobs-app 네임스페이스의 모든 네트워크 폴리시 확인
kubectl get networkpolicies -n jobs-app

# 상세 정보 확인
kubectl describe networkpolicy -n jobs-app
```

### 2. 통신 테스트

```bash
# Frontend → Backend 통신 테스트
kubectl run -it --rm test-frontend --image=busybox --restart=Never -n jobs-app -- sh
# 컨테이너 내부에서:
# wget -O- http://backend:8000/api/health

# Backend → MongoDB 통신 테스트
kubectl run -it --rm test-backend --image=mongo:7.0 --restart=Never -n jobs-app -- mongosh mongodb://mongodb:27017/jobsdb

# DNS 테스트
kubectl run -it --rm test-dns --image=busybox --restart=Never -n jobs-app -- nslookup kubernetes.default
```

### 3. 애플리케이션 동작 확인

```bash
# Pod 상태 확인
kubectl get pods -n jobs-app

# 서비스 엔드포인트 확인
kubectl get endpoints -n jobs-app

# 로그 확인
kubectl logs -f deployment/frontend -n jobs-app
kubectl logs -f deployment/backend -n jobs-app
```

## 🔧 문제 해결

### 문제: Pod가 시작되지 않음

```bash
# Pod 이벤트 확인
kubectl describe pod <pod-name> -n jobs-app

# 네트워크 폴리시 확인
kubectl get networkpolicies -n jobs-app -o yaml
```

### 문제: 서비스 간 통신 실패

1. 네트워크 폴리시 규칙 확인
2. 네임스페이스 라벨 확인
3. Pod 라벨 확인 (`kubectl get pods --show-labels -n jobs-app`)

### 문제: 외부 API 호출 실패

```bash
# Backend Pod에서 외부 API 테스트
kubectl exec -it deployment/backend -n jobs-app -- curl -v https://www.work24.go.kr
```

## 📝 커스터마이징

### 특정 IP로 제한

`06-allow-backend-external.yaml`에서 외부 IP를 특정 IP 대역으로 제한:

```yaml
- to:
  - ipBlock:
      cidr: 203.0.113.0/24  # 특정 IP 대역
```

### Ingress Controller 네임스페이스 변경

`05-allow-ingress.yaml`에서 Ingress Controller가 있는 네임스페이스로 수정:

```yaml
- namespaceSelector:
    matchLabels:
      name: ingress-nginx  # 실제 네임스페이스 이름으로 변경
```

### 모니터링 포트 추가

`07-allow-monitoring.yaml`에서 필요한 메트릭 포트 추가:

```yaml
ports:
- protocol: TCP
  port: 9100  # node-exporter
```

## ⚠️ 주의사항

1. **배포 순서**: Default Deny 정책을 먼저 배포하면 모든 트래픽이 차단되므로, 허용 규칙을 함께 배포해야 합니다.
2. **네임스페이스 라벨**: 모든 관련 네임스페이스에 적절한 라벨이 설정되어 있어야 합니다.
3. **Ingress Controller**: Ingress Controller가 있는 네임스페이스 이름을 확인하고 정책을 수정해야 합니다.
4. **테스트**: 네트워크 폴리시 배포 후 반드시 각 서비스 간 통신을 테스트해야 합니다.

