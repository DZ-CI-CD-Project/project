# 네트워크 폴리시 배포 체크리스트

## ✅ 권장 수정사항 (완료됨)

다음 수정사항은 이미 적용되었습니다:
- ✅ jobs-app/08-allow-cicd.yaml: podSelector 제거
- ✅ ci-cd/04-allow-jobs-app.yaml: namespaceSelector와 podSelector 결합
- ✅ jobs-app/07-allow-monitoring.yaml: 불필요한 포트 제거 및 주석 추가
- ✅ monitoring/03-allow-metrics-collection.yaml: 존재하지 않는 포트 제거
- ✅ ci-cd/03-allow-external.yaml: 중복 DNS 포트 제거

## ⚠️ 경고 사항 - 배포 전 확인 필요

### 1. 네임스페이스 라벨 설정

배포 스크립트(`deploy-all.sh`)가 자동으로 설정하지만, 수동 확인이 필요합니다:

```bash
# jobs-app 네임스페이스 라벨 확인
kubectl get namespace jobs-app --show-labels

# 라벨이 없다면 추가
kubectl label namespace jobs-app name=jobs-app --overwrite

# kube-system 네임스페이스 라벨 확인
kubectl get namespace kube-system --show-labels
kubectl label namespace kube-system name=kube-system --overwrite
```

### 2. 서비스 타입 확인 (NodePort vs Ingress)

**현재 설정: NodePort 사용**

Frontend는 NodePort 30080을 사용하므로 Ingress 정책이 불필요합니다.

**NodePort 사용 시:**
- ✅ `jobs-app/05-allow-ingress.yaml`은 비활성화됨 (주석 처리)
- ⚠️ **중요**: NetworkPolicy는 NodePort를 통한 외부 접근을 제어할 수 없습니다
- 🔒 보안이 필요한 경우 방화벽 규칙 사용 권장

**Ingress를 사용하는 경우:**

1. **Ingress Controller가 있는 네임스페이스 확인:**
   ```bash
   kubectl get pods -A | grep ingress
   kubectl get namespace | grep -E 'ingress|nginx'
   ```

2. **파일 수정:**
   - 파일: `jobs-app/05-allow-ingress.yaml`
   - 주석을 해제하고 네임스페이스 이름 수정

3. **네임스페이스에 라벨 추가:**
   ```bash
   kubectl label namespace <실제-네임스페이스-이름> name=<실제-네임스페이스-이름> --overwrite
   ```

**참고:** NodePort 보안 관련 내용은 `NODEPORT-NOTES.md` 참고

### 3. 모니터링 네임스페이스 확인

**해야 할 일:**

1. **모니터링 네임스페이스 확인:**
   ```bash
   kubectl get namespace | grep -E 'monitoring|prometheus'
   ```

2. **발견된 네임스페이스 이름으로 파일 수정:**
   - 파일들:
     - `monitoring/00-default-deny.yaml`
     - `monitoring/01-allow-dns.yaml`
     - `monitoring/02-allow-registry.yaml`
     - `monitoring/03-allow-metrics-collection.yaml`
   - 수정할 부분:
     ```yaml
     namespace: monitoring  # ← 실제 네임스페이스 이름으로 변경
     ```

3. **네임스페이스에 라벨 추가:**
   ```bash
   kubectl label namespace <실제-모니터링-네임스페이스> name=<실제-모니터링-네임스페이스> --overwrite
   ```

4. **jobs-app/07-allow-monitoring.yaml도 수정:**
   ```yaml
   - namespaceSelector:
       matchLabels:
         name: monitoring  # ← 실제 모니터링 네임스페이스 이름으로 변경
   ```

**일반적인 모니터링 네임스페이스:**
- `monitoring`
- `prometheus`
- `kube-prometheus`

### 4. CI/CD 네임스페이스 확인

**해야 할 일:**

1. **CI/CD 네임스페이스 확인:**
   ```bash
   kubectl get namespace | grep -E 'ci-cd|apps-job|cicd'
   ```

2. **발견된 네임스페이스 이름으로 파일 수정:**
   - 파일들:
     - `ci-cd/00-default-deny.yaml`
     - `ci-cd/01-allow-dns.yaml`
     - `ci-cd/02-allow-registry.yaml`
     - `ci-cd/03-allow-external.yaml`
     - `ci-cd/04-allow-jobs-app.yaml`
   - 수정할 부분:
     ```yaml
     namespace: ci-cd  # ← 실제 CI/CD 네임스페이스 이름으로 변경
     ```

3. **네임스페이스에 라벨 추가:**
   ```bash
   kubectl label namespace <실제-CI/CD-네임스페이스> name=<실제-CI/CD-네임스페이스> --overwrite
   ```

4. **jobs-app/08-allow-cicd.yaml도 수정:**
   ```yaml
   - namespaceSelector:
       matchLabels:
         name: ci-cd  # ← 실제 CI/CD 네임스페이스 이름으로 변경
   ```

**일반적인 CI/CD 네임스페이스:**
- `ci-cd`
- `apps-job`
- `cicd`

## 🚀 배포 순서

### 1단계: 네임스페이스 확인 및 라벨 설정
```bash
# 자동 스크립트 실행 (라벨 자동 설정)
cd k8s/network-policies
./deploy-all.sh
```

### 2단계: 네임스페이스 이름 확인 및 파일 수정
위의 체크리스트에 따라 파일들을 수정하세요.

### 3단계: jobs-app 네트워크 폴리시 배포
```bash
# 이미 deploy-all.sh에서 배포됨
# 또는 수동으로:
kubectl apply -f k8s/network-policies/jobs-app/
```

### 4단계: 모니터링 네트워크 폴리시 배포 (선택사항)
```bash
# 네임스페이스 이름 수정 후
kubectl apply -f k8s/network-policies/monitoring/
```

### 5단계: CI/CD 네트워크 폴리시 배포 (선택사항)
```bash
# 네임스페이스 이름 수정 후
kubectl apply -f k8s/network-policies/ci-cd/
```

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

## 📝 빠른 확인 명령어

```bash
# 모든 네임스페이스 목록
kubectl get namespace

# Ingress Controller 확인
kubectl get pods -A | grep ingress

# 모니터링 네임스페이스 확인
kubectl get namespace | grep -E 'monitoring|prometheus'

# CI/CD 네임스페이스 확인
kubectl get namespace | grep -E 'ci-cd|apps-job|cicd'

# 네임스페이스 라벨 확인
kubectl get namespace --show-labels
```

