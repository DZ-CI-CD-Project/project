# 네트워크 폴리시 작성 완료 요약

## 📋 현재 쿠버네티스 환경 분석 결과

### 1. 네임스페이스 구조
- **jobs-app**: 메인 애플리케이션 네임스페이스
  - Frontend (NodePort 30080, ClusterIP 3000)
  - Backend (ClusterIP 8000) 
  - MongoDB (ClusterIP 27017)
- **CI/CD**: 별도 네임스페이스 사용 가능 (예: `ci-cd`, `apps-job`)
- **모니터링**: 별도 네임스페이스 사용 가능 (예: `monitoring`, `prometheus`)
- **시스템**: `kube-system`, `ingress-nginx` 등

### 2. 발견된 문제점
1. ❌ 기존 `netpolwhitelist.yaml`이 default-deny-all만 있어서 모든 트래픽 차단
2. ⚠️ 기존 `netpolEngress.yaml`의 네임스페이스가 `apps-job`인데 실제는 `jobs-app` 사용
3. ⚠️ Ingress Controller와의 통신 허용 규칙 없음
4. ⚠️ 모니터링 시스템과의 통신 규칙 없음
5. ⚠️ CI/CD 러너와의 통신 규칙 없음

### 3. 애플리케이션 통신 흐름
```
외부 사용자
    ↓
[Ingress Controller] (nginx-ingress)
    ↓
[Frontend] → [Backend] → [MongoDB]
    ↓
[Backend] → 외부 API (work24.go.kr)
```

### 4. CI/CD 파이프라인
- **GitHub Actions**: SonarQube → 이미지 빌드 → Trivy → Harbor 푸시
- **ArgoCD**: GitOps 배포 (별도 네임스페이스)

## ✅ 작성된 네트워크 폴리시

### jobs-app 네임스페이스 (8개 정책)
1. **00-default-deny.yaml**: 기본 거부 정책 (모든 트래픽 차단)
2. **01-allow-dns.yaml**: DNS 조회 허용 (kube-dns)
3. **02-allow-registry.yaml**: Harbor 레지스트리 접근 허용 (192.168.0.240)
4. **03-allow-frontend-to-backend.yaml**: Frontend → Backend 통신 허용
5. **04-allow-backend-to-mongodb.yaml**: Backend → MongoDB 통신 허용
6. **05-allow-ingress.yaml**: Ingress Controller → Frontend/Backend 통신 허용
7. **06-allow-backend-external.yaml**: Backend → 외부 HTTPS API 허용
8. **07-allow-monitoring.yaml**: 모니터링 시스템 메트릭 수집 허용
9. **08-allow-cicd.yaml**: CI/CD 시스템에서 Backend 테스트 허용

### monitoring 네임스페이스 (4개 정책)
1. **00-default-deny.yaml**: 기본 거부 정책
2. **01-allow-dns.yaml**: DNS 조회 허용
3. **02-allow-registry.yaml**: Harbor 레지스트리 접근 허용
4. **03-allow-metrics-collection.yaml**: jobs-app 네임스페이스 메트릭 수집 허용

### ci-cd 네임스페이스 (5개 정책)
1. **00-default-deny.yaml**: 기본 거부 정책
2. **01-allow-dns.yaml**: DNS 조회 허용
3. **02-allow-registry.yaml**: Harbor 레지스트리 접근 허용
4. **03-allow-external.yaml**: 외부 인터넷 접근 허용 (Harbor, GitHub 등)
5. **04-allow-jobs-app.yaml**: jobs-app 네임스페이스 Backend 테스트 허용

## 🚀 배포 방법

### 빠른 배포 (권장)
```bash
cd k8s/network-policies
./deploy-all.sh
```

### 수동 배포
```bash
# 1. 네임스페이스 라벨 설정
kubectl label namespace jobs-app name=jobs-app --overwrite
kubectl label namespace kube-system name=kube-system --overwrite

# 2. jobs-app 네트워크 폴리시 배포 (모든 파일을 한 번에!)
kubectl apply -f network-policies/jobs-app/

# 3. 배포 확인
kubectl get networkpolicies -n jobs-app
```

## ⚠️ 중요 사항

1. **배포 순서**: Default Deny 정책만 배포하면 모든 트래픽이 차단되므로, **모든 허용 규칙을 함께 배포**해야 합니다.

2. **네임스페이스 라벨**: 다음 네임스페이스에 라벨이 필요합니다:
   - `jobs-app`: `name=jobs-app`
   - `kube-system`: `name=kube-system`
   - Ingress Controller 네임스페이스: `name=ingress-nginx` (또는 실제 네임스페이스 이름)

3. **모니터링/CI/CD 네임스페이스**: 
   - 실제 네임스페이스 이름을 확인한 후 파일 내 네임스페이스 이름을 수정해야 합니다.
   - 네임스페이스에 적절한 라벨을 설정해야 합니다.

4. **Ingress Controller**: 
   - `05-allow-ingress.yaml`에서 Ingress Controller가 있는 네임스페이스 이름을 확인하고 수정해야 합니다.
   - 일반적으로 `ingress-nginx` 또는 `kube-system`에 있습니다.

## 🔍 배포 후 검증

```bash
# 1. 네트워크 폴리시 확인
kubectl get networkpolicies -n jobs-app

# 2. Pod 상태 확인
kubectl get pods -n jobs-app

# 3. 통신 테스트
kubectl run -it --rm test --image=busybox --restart=Never -n jobs-app -- sh
# 컨테이너 내부에서:
# wget -O- http://backend:8000/api/health
# nslookup kubernetes.default

# 4. 로그 확인
kubectl logs -f deployment/backend -n jobs-app
```

## 📝 커스터마이징 가이드

### 외부 IP 제한
`06-allow-backend-external.yaml`에서 특정 IP 대역으로 제한:
```yaml
- to:
  - ipBlock:
      cidr: 203.0.113.0/24  # 특정 IP 대역
```

### Ingress Controller 네임스페이스 변경
`05-allow-ingress.yaml`에서 실제 네임스페이스로 수정:
```yaml
- namespaceSelector:
    matchLabels:
      name: ingress-nginx  # 실제 네임스페이스 이름
```

### 모니터링 포트 추가
`07-allow-monitoring.yaml`에서 필요한 포트 추가:
```yaml
ports:
- protocol: TCP
  port: 9100  # node-exporter
```

## 📚 참고 문서

- [네트워크 폴리시 분석 문서](./network-policy-analysis.md)
- [배포 가이드](./README.md)
- [Kubernetes Network Policies 공식 문서](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

