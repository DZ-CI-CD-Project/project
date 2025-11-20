# 쿠버네티스 네트워크 폴리시 분석 및 설계

## 📊 현재 환경 분석

### 1. 네임스페이스 구조
- **jobs-app**: 메인 애플리케이션 네임스페이스
  - Frontend (NodePort 30080, ClusterIP 3000)
  - Backend (ClusterIP 8000)
  - MongoDB (ClusterIP 27017)
- **CI/CD 네임스페이스**: 별도 관리 (예: `ci-cd`, `apps-job`)
- **모니터링 네임스페이스**: 별도 관리 (예: `monitoring`, `prometheus`)
- **시스템 네임스페이스**: `kube-system`, `ingress-nginx`, `argocd`

### 2. 현재 네트워크 폴리시 상태
- ✅ `netpolwhitelist.yaml`: jobs-app에 default-deny-all 적용 (허용 규칙 없음 - 문제!)
- ⚠️ `netpolEngress.yaml`: apps-job 네임스페이스용 (실제 사용 네임스페이스와 불일치)

### 3. 애플리케이션 통신 흐름
```
외부 사용자
    ↓
[Ingress Controller] (nginx-ingress 네임스페이스)
    ↓
[Frontend] (jobs-app, 포트 3000)
    ↓
[Backend] (jobs-app, 포트 8000)
    ↓
[MongoDB] (jobs-app, 포트 27017)

[Backend] → 외부 API (work24.go.kr, HTTPS)
[모든 Pod] → DNS (kube-dns, 포트 53)
[모든 Pod] → Harbor 레지스트리 (192.168.0.240, HTTPS)
```

### 4. CI/CD 파이프라인
- **GitHub Actions**: 
  - SonarQube 스캔
  - 이미지 빌드 및 Trivy 스캔
  - Harbor 푸시 (192.168.0.240)
- **ArgoCD**: GitOps 배포 (별도 네임스페이스)

### 5. 발견된 문제점
1. ❌ `netpolwhitelist.yaml`이 default-deny-all만 있어서 모든 트래픽이 차단됨
2. ⚠️ `netpolEngress.yaml`의 네임스페이스가 `apps-job`인데 실제는 `jobs-app` 사용
3. ⚠️ Ingress Controller와의 통신 허용 규칙 없음
4. ⚠️ 모니터링 시스템과의 통신 규칙 없음
5. ⚠️ CI/CD 러너와의 통신 규칙 없음

## 🎯 네트워크 폴리시 설계 원칙

1. **최소 권한 원칙**: 필요한 통신만 허용
2. **네임스페이스 격리**: 기본적으로 네임스페이스 간 통신 차단
3. **시스템 통신 허용**: DNS, 레지스트리 등 필수 시스템 통신 허용
4. **모니터링 통신**: 메트릭 수집을 위한 통신 허용
5. **CI/CD 통신**: 테스트 및 배포를 위한 통신 허용

## 📝 네트워크 폴리시 파일 구조

```
k8s/
├── network-policies/
│   ├── jobs-app/
│   │   ├── 00-default-deny.yaml          # 기본 거부 정책
│   │   ├── 01-allow-dns.yaml              # DNS 허용
│   │   ├── 02-allow-registry.yaml         # Harbor 레지스트리 허용
│   │   ├── 03-allow-frontend-to-backend.yaml  # Frontend → Backend
│   │   ├── 04-allow-backend-to-mongodb.yaml   # Backend → MongoDB
│   │   ├── 05-allow-ingress.yaml          # Ingress → Frontend/Backend
│   │   ├── 06-allow-backend-external.yaml # Backend → 외부 API
│   │   ├── 07-allow-monitoring.yaml       # 모니터링 시스템 허용
│   │   └── 08-allow-cicd.yaml            # CI/CD 시스템 허용
│   ├── monitoring/
│   │   ├── 00-default-deny.yaml
│   │   ├── 01-allow-dns.yaml
│   │   ├── 02-allow-registry.yaml
│   │   └── 03-allow-metrics-collection.yaml
│   └── ci-cd/
│       ├── 00-default-deny.yaml
│       ├── 01-allow-dns.yaml
│       ├── 02-allow-registry.yaml
│       ├── 03-allow-external.yaml
│       └── 04-allow-jobs-app.yaml
```

## 🔒 권장 네트워크 폴리시 정책

### jobs-app 네임스페이스
1. **Default Deny All**: 모든 인그레스/이그레스 차단
2. **DNS 허용**: kube-dns 서비스 (UDP 53)
3. **Harbor 레지스트리 허용**: 192.168.0.240 (HTTPS 443)
4. **Frontend → Backend**: Frontend 파드에서 Backend 서비스로 (TCP 8000)
5. **Backend → MongoDB**: Backend 파드에서 MongoDB 서비스로 (TCP 27017)
6. **Ingress → Frontend/Backend**: Ingress Controller에서 Frontend/Backend로
7. **Backend → 외부 API**: Backend에서 외부 HTTPS API로 (work24.go.kr 등)
8. **모니터링 수집**: 모니터링 네임스페이스에서 메트릭 수집 허용
9. **CI/CD 접근**: CI/CD 네임스페이스에서 Backend 테스트 허용

### 모니터링 네임스페이스
1. **Default Deny All**
2. **DNS 허용**
3. **레지스트리 허용**
4. **메트릭 수집**: jobs-app 네임스페이스의 모든 파드에서 메트릭 수집 허용

### CI/CD 네임스페이스
1. **Default Deny All**
2. **DNS 허용**
3. **레지스트리 허용**
4. **외부 인터넷 허용**: Harbor, GitHub 등
5. **jobs-app 접근**: Backend 서비스 테스트 허용

## ⚠️ 주의사항

1. **배포 순서**: Default Deny 정책을 먼저 배포하면 모든 트래픽이 차단되므로, 허용 규칙을 함께 배포해야 함
2. **Ingress Controller**: Ingress Controller가 있는 네임스페이스(보통 `ingress-nginx`)에서 jobs-app으로의 통신을 허용해야 함
3. **Health Check**: Liveness/Readiness Probe를 위한 kubelet 통신은 기본적으로 허용됨
4. **테스트**: 네트워크 폴리시 배포 후 각 서비스 간 통신 테스트 필수

