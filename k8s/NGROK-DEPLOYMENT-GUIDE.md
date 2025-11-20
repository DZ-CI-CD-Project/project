# ngrok 사이드카 배포 가이드

## 📋 개요

Frontend Pod에 ngrok 사이드카 컨테이너를 추가하여 외부 접근을 제공합니다.

## 🚀 배포 방법

### 1단계: ngrok Secret 생성 (선택사항이지만 권장)

ngrok 인증 토큰을 사용하면 더 안전하고 고정 도메인을 사용할 수 있습니다.

```bash
# 방법 1: kubectl 명령어로 직접 생성
kubectl create secret generic ngrok-secret \
  --from-literal=auth-token='YOUR_NGROK_AUTH_TOKEN' \
  --namespace=jobs-app

# 방법 2: YAML 파일 사용
# ngrok-secret.yaml.example을 복사하여 수정
cp k8s/ngrok-secret.yaml.example k8s/ngrok-secret.yaml
# 파일 수정 후
kubectl apply -f k8s/ngrok-secret.yaml
```

**ngrok 인증 토큰 발급:**
1. https://dashboard.ngrok.com 접속
2. 회원가입/로그인
3. "Your Authtoken" 메뉴에서 토큰 복사

### 2단계: Frontend Deployment 업데이트

**옵션 A: 기존 Deployment 교체 (권장)**
```bash
# 기존 Deployment 백업 (선택사항)
kubectl get deployment frontend -n jobs-app -o yaml > frontend-deployment-backup.yaml

# 새 Deployment 적용
kubectl apply -f k8s/frontend-deployment-with-ngrok.yaml
```

**옵션 B: 기존 Deployment에 ngrok 컨테이너 추가**
```bash
# 기존 Deployment 편집
kubectl edit deployment frontend -n jobs-app
# containers 섹션에 ngrok 컨테이너 추가
```

### 3단계: Secret 사용 시 Deployment 수정

ngrok Secret을 사용하려면 `frontend-deployment-with-ngrok.yaml`에서 다음 부분의 주석을 해제:

```yaml
- name: ngrok
  image: ngrok/ngrok:latest
  command: 
  - ngrok
  - http
  - "3000"
  env:  # ← 이 부분 주석 해제
  - name: NGROK_AUTH_TOKEN
    valueFrom:
      secretKeyRef:
        name: ngrok-secret
        key: auth-token
```

## ✅ 배포 확인

### 1. Pod 상태 확인
```bash
kubectl get pods -n jobs-app -l app=frontend
```

각 Pod에 2개의 컨테이너(frontend, ngrok)가 실행 중이어야 합니다.

### 2. ngrok 로그 확인
```bash
# 특정 Pod의 ngrok 로그 확인
kubectl logs -f <pod-name> -c ngrok -n jobs-app

# 모든 Frontend Pod의 ngrok 로그 확인
kubectl logs -f deployment/frontend -c ngrok -n jobs-app
```

### 3. ngrok URL 확인

ngrok 로그에서 다음과 같은 출력을 확인:
```
Forwarding   https://xxxx-xx-xx-xx-xx.ngrok-free.app -> http://localhost:3000
```

이 URL이 외부 접근 가능한 주소입니다.

### 4. ngrok Web UI 접근 (선택사항)

ngrok은 기본적으로 로컬 웹 UI를 제공합니다:
```bash
# ngrok Web UI 포트 포워딩
kubectl port-forward <pod-name> 4040:4040 -n jobs-app
# 브라우저에서 http://localhost:4040 접속
```

## 🔒 보안 고려사항

### 1. ngrok 인증 토큰 사용 (권장)
- 무료 플랜: 동적 도메인, 세션 제한
- 유료 플랜: 고정 도메인, 더 많은 기능

### 2. NetworkPolicy 확인
- `00-default-deny.yaml`: Ingress 차단 (NodePort 접근 차단)
- `06-allow-backend-external.yaml`: Egress 허용 (ngrok 서버 접근)
- Frontend Pod에도 외부 Egress가 필요하면 정책 추가 필요

### 3. Frontend Pod Egress 정책 추가 (필요시)

ngrok이 Frontend Pod에서 실행되므로, Frontend Pod에도 외부 HTTPS 접근이 필요합니다:

```yaml
# k8s/network-policies/jobs-app/09-allow-frontend-external.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-external
  namespace: jobs-app
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Egress
  egress:
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
    ports:
    - protocol: TCP
      port: 443  # HTTPS (ngrok 서버 접근)
```

## 🔍 문제 해결

### ngrok이 시작되지 않는 경우
```bash
# Pod 이벤트 확인
kubectl describe pod <pod-name> -n jobs-app

# ngrok 컨테이너 로그 확인
kubectl logs <pod-name> -c ngrok -n jobs-app
```

### ngrok URL이 보이지 않는 경우
- ngrok 로그를 확인하여 URL 확인
- ngrok Web UI (포트 4040)에서 확인

### 외부에서 접근이 안 되는 경우
1. NetworkPolicy 확인: Frontend Pod에 Egress 정책이 있는지 확인
2. ngrok 로그 확인: 연결 상태 확인
3. ngrok 인증 토큰 확인: 유효한 토큰인지 확인

## 📝 참고

- [ngrok 공식 문서](https://ngrok.com/docs)
- [ngrok Kubernetes 가이드](https://ngrok.com/docs/integrations/kubernetes)
- [NetworkPolicy 가이드](../network-policies/NGROK-NOTES.md)

