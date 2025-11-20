# 네트워크 폴리시 수정 완료 보고서

## ✅ 완료된 수정사항

### 1. jobs-app/08-allow-cicd.yaml
**문제:** `podSelector`만 있으면 같은 네임스페이스(jobs-app)의 파드를 의미함  
**수정:** `podSelector` 제거, `namespaceSelector`만 사용하여 CI/CD 네임스페이스의 모든 파드 허용

### 2. ci-cd/04-allow-jobs-app.yaml
**문제:** `namespaceSelector`와 `podSelector`가 OR 조건으로 해석됨  
**수정:** 하나의 `to` 항목에 `namespaceSelector`와 `podSelector`를 함께 사용하여 AND 조건으로 변경

### 3. jobs-app/07-allow-monitoring.yaml
**문제:** 존재하지 않는 포트(9090, 8080) 포함  
**수정:** 불필요한 포트 제거, 주석 추가로 설명

### 4. monitoring/03-allow-metrics-collection.yaml
**문제:** jobs-app에 존재하지 않는 포트(9090, 8080) 포함  
**수정:** 존재하지 않는 포트 제거, 실제 애플리케이션 포트만 유지

### 5. ci-cd/03-allow-external.yaml
**문제:** DNS 포트가 중복 (이미 01-allow-dns.yaml에서 허용)  
**수정:** DNS 포트 제거, 주석으로 설명 추가

## ⚠️ 사용자가 해야 할 작업

### 작업 1: NodePort 사용 확인 (완료됨)

**현재 설정:** Frontend는 NodePort 30080 사용

**적용된 변경:**
- ✅ `jobs-app/05-allow-ingress.yaml`: Ingress 정책 비활성화 (주석 처리)
- ✅ `jobs-app/05-allow-nodeport.yaml`: NodePort 안내 문서 추가
- ✅ `deploy-all.sh`: NodePort 사용 자동 감지 및 안내

**중요 사항:**
- NetworkPolicy는 NodePort를 통한 외부 접근을 제어할 수 없습니다
- 보안이 필요한 경우 방화벽 규칙 사용 권장
- 자세한 내용은 `NODEPORT-NOTES.md` 참고

**Ingress를 사용하는 경우:**
- `jobs-app/05-allow-ingress.yaml` 파일의 주석을 해제하고 네임스페이스 이름 수정

### 작업 2: 모니터링 네임스페이스 확인 및 수정 (모니터링 사용 시)

**1단계: 모니터링 네임스페이스 확인**
```bash
kubectl get namespace | grep -E 'monitoring|prometheus'
```

**2단계: 파일 수정**
- 파일들:
  - `k8s/network-policies/monitoring/00-default-deny.yaml`
  - `k8s/network-policies/monitoring/01-allow-dns.yaml`
  - `k8s/network-policies/monitoring/02-allow-registry.yaml`
  - `k8s/network-policies/monitoring/03-allow-metrics-collection.yaml`
- 수정할 부분:
  ```yaml
  namespace: monitoring  # ← 실제 모니터링 네임스페이스 이름으로 변경
  ```

- 추가로 수정할 파일:
  - `k8s/network-policies/jobs-app/07-allow-monitoring.yaml`
  - 수정할 부분:
    ```yaml
    - namespaceSelector:
        matchLabels:
          name: monitoring  # ← 실제 모니터링 네임스페이스 이름으로 변경
    ```

**3단계: 네임스페이스 라벨 확인**
```bash
kubectl label namespace <실제-모니터링-네임스페이스> name=<실제-모니터링-네임스페이스> --overwrite
```

### 작업 3: CI/CD 네임스페이스 확인 및 수정 (CI/CD 사용 시)

**1단계: CI/CD 네임스페이스 확인**
```bash
kubectl get namespace | grep -E 'ci-cd|apps-job|cicd'
```

**2단계: 파일 수정**
- 파일들:
  - `k8s/network-policies/ci-cd/00-default-deny.yaml`
  - `k8s/network-policies/ci-cd/01-allow-dns.yaml`
  - `k8s/network-policies/ci-cd/02-allow-registry.yaml`
  - `k8s/network-policies/ci-cd/03-allow-external.yaml`
  - `k8s/network-policies/ci-cd/04-allow-jobs-app.yaml`
- 수정할 부분:
  ```yaml
  namespace: ci-cd  # ← 실제 CI/CD 네임스페이스 이름으로 변경
  ```

- 추가로 수정할 파일:
  - `k8s/network-policies/jobs-app/08-allow-cicd.yaml`
  - 수정할 부분:
    ```yaml
    - namespaceSelector:
        matchLabels:
          name: ci-cd  # ← 실제 CI/CD 네임스페이스 이름으로 변경
    ```

**3단계: 네임스페이스 라벨 확인**
```bash
kubectl label namespace <실제-CI/CD-네임스페이스> name=<실제-CI/CD-네임스페이스> --overwrite
```

## 🚀 배포 방법

### 자동 배포 (권장)
```bash
cd k8s/network-policies
./deploy-all.sh
```

스크립트가 자동으로:
- 네임스페이스 라벨 설정
- Ingress Controller 네임스페이스 확인 및 안내
- 모니터링/CI/CD 네임스페이스 확인 및 안내
- jobs-app 네트워크 폴리시 배포

### 수동 배포
```bash
# 1. 네임스페이스 라벨 설정
kubectl label namespace jobs-app name=jobs-app --overwrite
kubectl label namespace kube-system name=kube-system --overwrite

# 2. jobs-app 네트워크 폴리시 배포
kubectl apply -f k8s/network-policies/jobs-app/

# 3. 모니터링 네트워크 폴리시 배포 (선택사항)
kubectl apply -f k8s/network-policies/monitoring/

# 4. CI/CD 네트워크 폴리시 배포 (선택사항)
kubectl apply -f k8s/network-policies/ci-cd/
```

## 📋 체크리스트

배포 전 확인:
- [ ] Ingress Controller 네임스페이스 확인 및 파일 수정
- [ ] 모니터링 네임스페이스 확인 및 파일 수정 (사용 시)
- [ ] CI/CD 네임스페이스 확인 및 파일 수정 (사용 시)
- [ ] 네임스페이스 라벨 설정 확인

배포 후 확인:
- [ ] `kubectl get networkpolicies -n jobs-app` - 정책 확인
- [ ] `kubectl get pods -n jobs-app` - Pod 상태 확인
- [ ] 애플리케이션 통신 테스트
- [ ] 로그 확인

## 📚 참고 문서

- [배포 체크리스트](./DEPLOYMENT-CHECKLIST.md) - 상세한 배포 가이드
- [README](./README.md) - 네트워크 폴리시 사용법
- [요약 문서](./SUMMARY.md) - 전체 요약

