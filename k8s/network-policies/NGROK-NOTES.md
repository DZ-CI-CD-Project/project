# ngrok 사용 시 네트워크 폴리시 고려사항

## 📋 ngrok 동작 방식

ngrok은 두 가지 방식으로 사용할 수 있습니다:

### 1. Pod 내부에서 ngrok 클라이언트 실행
- ngrok 클라이언트가 Pod 내부에서 실행
- ngrok 서버(ngrok.io)에 터널 연결
- 외부에서 ngrok URL로 접근 → ngrok 서버 → Pod 내부 서비스

### 2. 외부에서 ngrok 클라이언트 실행
- ngrok 클라이언트가 클러스터 외부에서 실행
- NodePort나 Port Forward를 통해 로컬 서비스에 연결
- NetworkPolicy 영향 없음

## ⚠️ NetworkPolicy 고려사항

### 현재 정책 상태

**✅ 이미 충분한 경우:**
- `06-allow-backend-external.yaml`이 모든 외부 HTTPS(443) 접근을 허용
- ngrok 클라이언트가 Pod 내부에서 실행되면 이 정책으로 ngrok 서버 접근 가능

**⚠️ 추가 고려가 필요한 경우:**
- ngrok 서버 IP를 명시적으로 허용하고 싶은 경우
- 보안 강화를 위해 특정 IP만 허용하고 싶은 경우

## 🔒 보안 권장사항

### 1. ngrok 인증 사용
```bash
# ngrok 인증 토큰 설정
ngrok config add-authtoken <YOUR_AUTH_TOKEN>

# 고정 도메인 사용 (유료 플랜)
ngrok http 3000 --domain=your-domain.ngrok.io
```

### 2. ngrok IP 화이트리스트
- ngrok 대시보드에서 IP 화이트리스트 설정
- 특정 IP에서만 접근 허용

### 3. ngrok 접근 로그 모니터링
- ngrok 대시보드에서 접근 로그 확인
- 비정상적인 접근 시도 감지

## 📝 NetworkPolicy 추가 옵션

### 옵션 1: ngrok 서버 IP 명시적 허용 (선택사항)

ngrok 서버 IP를 명시적으로 허용하려면:

```yaml
# jobs-app/09-allow-ngrok.yaml (선택사항)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ngrok
  namespace: jobs-app
spec:
  podSelector:
    matchLabels:
      app: backend  # 또는 ngrok을 실행하는 Pod의 라벨
  policyTypes:
  - Egress
  egress:
  # ngrok 서버 접근 허용
  - to:
    - ipBlock:
        # ngrok 서버 IP 대역 (ngrok 문서 참고)
        # 주의: ngrok IP는 변경될 수 있음
        cidr: 0.0.0.0/0  # 또는 특정 IP 대역
    ports:
    - protocol: TCP
      port: 443  # HTTPS
```

**⚠️ 주의:** ngrok 서버 IP는 변경될 수 있으므로, 일반적으로 `0.0.0.0/0`을 사용하거나 기존 `06-allow-backend-external.yaml`을 사용하는 것이 더 실용적입니다.

### 옵션 2: 현재 정책 유지 (권장)

**현재 정책으로 충분합니다:**
- `06-allow-backend-external.yaml`이 이미 모든 외부 HTTPS 접근을 허용
- ngrok 클라이언트가 Pod 내부에서 실행되면 자동으로 작동
- 추가 정책 불필요

## 🚀 ngrok 사용 시나리오

### 시나리오 1: Pod 내부에서 ngrok 실행

```yaml
# Deployment에 ngrok 사이드카 추가
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  template:
    spec:
      containers:
      - name: frontend
        image: frontend:latest
        ports:
        - containerPort: 3000
      - name: ngrok
        image: ngrok/ngrok:latest
        command: ["ngrok", "http", "3000", "--authtoken", "$(NGROK_AUTH_TOKEN)"]
        env:
        - name: NGROK_AUTH_TOKEN
          valueFrom:
            secretKeyRef:
              name: ngrok-secret
              key: auth-token
```

**NetworkPolicy:**
- ✅ `06-allow-backend-external.yaml`로 충분 (ngrok 서버 접근 허용)
- ✅ 추가 정책 불필요

### 시나리오 2: 외부에서 ngrok 실행

```bash
# 로컬에서 실행
kubectl port-forward svc/frontend 3000:3000 -n jobs-app
ngrok http 3000
```

**NetworkPolicy:**
- ✅ NetworkPolicy 영향 없음 (외부에서 실행)
- ✅ 추가 정책 불필요

## ✅ 결론

### 현재 정책으로 충분한가?

**네, 충분합니다!**

1. **Pod 내부에서 ngrok 실행 시:**
   - `06-allow-backend-external.yaml`이 ngrok 서버 접근 허용
   - 추가 정책 불필요

2. **외부에서 ngrok 실행 시:**
   - NetworkPolicy 영향 없음
   - 추가 정책 불필요

### 추가 작업이 필요한 경우

**보안 강화가 필요한 경우에만:**
- ngrok 서버 IP를 명시적으로 허용하는 정책 추가 (선택사항)
- 하지만 ngrok IP는 변경될 수 있으므로 실용적이지 않을 수 있음

**권장사항:**
- 현재 정책 유지
- ngrok 인증 토큰 사용
- ngrok IP 화이트리스트 사용 (ngrok 대시보드)
- 접근 로그 모니터링

## 📚 참고

- [ngrok 공식 문서](https://ngrok.com/docs)
- [ngrok Kubernetes 가이드](https://ngrok.com/docs/integrations/kubernetes)
- [ngrok 보안 모범 사례](https://ngrok.com/docs/guides/secure-tunnels)

