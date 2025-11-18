# 쿠버네티스 배포 가이드

이 디렉토리에는 채용공고 관리 시스템을 쿠버네티스에 배포하기 위한 매니페스트 파일들이 있습니다.

## 파일 구조

```
k8s/
├── namespace.yaml              # 네임스페이스 정의
├── mongodb-pvc.yaml           # MongoDB 데이터 영속성 볼륨
├── mongodb-deployment.yaml    # MongoDB Deployment
├── mongodb-service.yaml       # MongoDB Service
├── backend-configmap.yaml     # Backend 환경변수 (ConfigMap)
├── backend-secret.yaml        # Backend 비밀정보 (Secret)
├── backend-deployment.yaml    # Backend Deployment
├── backend-service.yaml       # Backend Service
├── frontend-configmap.yaml    # Frontend 환경변수 (ConfigMap)
├── frontend-deployment.yaml   # Frontend Deployment
├── frontend-service.yaml      # Frontend Service
├── ingress.yaml               # Ingress (선택사항)
└── README.md                  # 이 파일
```

## 배포 순서

### ⚠️ 중요: 이미지를 먼저 빌드하고 푸시해야 합니다!

### 1. Harbor 로그인 (이미 했다면 스킵)
```bash
docker login 192.168.0.240
# 사용자명과 비밀번호 입력
```

### 2. Docker 이미지 빌드 및 Harbor에 푸시

**자동 스크립트 사용 (권장):**
```bash
cd k8s
./build-and-push-images.sh
```

**수동으로 빌드/푸시:**
```bash
# Harbor 로그인
docker login 192.168.0.240

# Backend 이미지 빌드 및 푸시
cd backend
docker build -t 192.168.0.240/mywork/backend:latest .
docker push 192.168.0.240/mywork/backend:latest

# Frontend 이미지 빌드 및 푸시
cd ../frontend/app
docker build -t 192.168.0.240/mywork/frontend:latest .
docker push 192.168.0.240/mywork/frontend:latest
```

### 3. Harbor 레지스트리 Secret 생성 (프라이빗 레지스트리 인증)

쿠버네티스가 Harbor에서 이미지를 Pull할 수 있도록 Secret을 생성해야 합니다.

**자동 스크립트 사용 (권장):**
```bash
cd k8s
./create-harbor-secret.sh
# 사용자명, 비밀번호, 이메일 입력
```

**수동으로 생성:**
```bash
kubectl create secret docker-registry harbor-registry-secret \
  --docker-server=192.168.0.240 \
  --docker-username=<your-username> \
  --docker-password=<your-password> \
  --docker-email=<your-email> \
  --namespace=jobs-app
```

### 4. 네임스페이스 생성
```bash
kubectl apply -f namespace.yaml
```

### 5. Backend Secret 수정 (중요!)

`backend-secret.yaml`의 `JWT_SECRET`을 실제 비밀키로 변경:

```bash
# stringData를 직접 수정하거나
kubectl edit secret backend-secret -n jobs-app
```

### 6. MongoDB 배포
```bash
kubectl apply -f mongodb-pvc.yaml
kubectl apply -f mongodb-deployment.yaml
kubectl apply -f mongodb-service.yaml
```

### 7. Backend 배포
```bash
kubectl apply -f backend-configmap.yaml
kubectl apply -f backend-secret.yaml
kubectl apply -f backend-deployment.yaml
kubectl apply -f backend-service.yaml
```

### 8. Frontend 배포
```bash
kubectl apply -f frontend-configmap.yaml
kubectl apply -f frontend-deployment.yaml
kubectl apply -f frontend-service.yaml
```

### 9. Ingress 배포 (선택사항)
```bash
kubectl apply -f ingress.yaml
```

## 한 번에 배포하기

**⚠️ 주의: 이미지 빌드/푸시와 Harbor Secret 생성은 먼저 완료해야 합니다!**

```bash
# 1. 이미지 빌드 및 푸시 (위의 2단계 참고)
./build-and-push-images.sh

# 2. Harbor Secret 생성 (위의 3단계 참고)
./create-harbor-secret.sh

# 3. 모든 리소스 배포
./deploy.sh

# 또는 수동으로
kubectl apply -f namespace.yaml
kubectl apply -f mongodb-pvc.yaml
kubectl apply -f mongodb-deployment.yaml
kubectl apply -f mongodb-service.yaml
kubectl apply -f backend-configmap.yaml
kubectl apply -f backend-secret.yaml
kubectl apply -f backend-deployment.yaml
kubectl apply -f backend-service.yaml
kubectl apply -f frontend-configmap.yaml
kubectl apply -f frontend-deployment.yaml
kubectl apply -f frontend-service.yaml
kubectl apply -f ingress.yaml
```

## 상태 확인

```bash
# 네임스페이스 확인
kubectl get namespace jobs-app

# 모든 리소스 확인
kubectl get all -n jobs-app

# Pod 상태 확인
kubectl get pods -n jobs-app

# Pod 로그 확인
kubectl logs -f deployment/backend -n jobs-app
kubectl logs -f deployment/frontend -n jobs-app
kubectl logs -f deployment/mongodb -n jobs-app

# Service 확인
kubectl get svc -n jobs-app

# PVC 확인
kubectl get pvc -n jobs-app
```

## 접속 방법

### NodePort 사용 시
```bash
# NodePort 확인
kubectl get svc frontend -n jobs-app

# 접속 (노드 IP:30080)
# 예: http://192.168.0.208:30080
```

### Ingress 사용 시
```bash
# Ingress 주소 확인
kubectl get ingress -n jobs-app

# /etc/hosts에 도메인 추가 (로컬 테스트 시)
# 192.168.0.208 jobs-app.local

# 접속
# http://jobs-app.local
```

### Port Forward (개발/디버깅용)
```bash
# Frontend
kubectl port-forward svc/frontend 3000:3000 -n jobs-app

# Backend
kubectl port-forward svc/backend 8000:8000 -n jobs-app

# MongoDB
kubectl port-forward svc/mongodb 27017:27017 -n jobs-app
```

## 업데이트

### 이미지 업데이트
```bash
# 새 이미지 빌드 및 푸시
cd backend
docker build -t 192.168.0.240/mywork/backend:v1.1.0 .
docker push 192.168.0.240/mywork/backend:v1.1.0

# Deployment 이미지 업데이트
kubectl set image deployment/backend backend=192.168.0.240/mywork/backend:v1.1.0 -n jobs-app

# 롤아웃 상태 확인
kubectl rollout status deployment/backend -n jobs-app
```

### 설정 업데이트
```bash
# ConfigMap 수정
kubectl edit configmap backend-config -n jobs-app

# Secret 수정
kubectl edit secret backend-secret -n jobs-app

# Pod 재시작 (설정 적용)
kubectl rollout restart deployment/backend -n jobs-app
```

## 삭제

```bash
# 모든 리소스 삭제
kubectl delete -f .

# 또는 네임스페이스 전체 삭제 (주의: 모든 데이터 삭제됨)
kubectl delete namespace jobs-app

# PVC 삭제 (데이터 영구 삭제)
kubectl delete pvc mongodb-pvc -n jobs-app
```

## 트러블슈팅

### Pod가 시작되지 않을 때
```bash
# Pod 이벤트 확인
kubectl describe pod <pod-name> -n jobs-app

# Pod 로그 확인
kubectl logs <pod-name> -n jobs-app
```

### 이미지 Pull 실패
```bash
# 이미지 Pull 정책 확인
kubectl describe pod <pod-name> -n jobs-app | grep ImagePull

# Secret 확인 (프라이빗 레지스트리 사용 시)
kubectl get secret -n jobs-app
```

### 서비스 연결 문제
```bash
# Service 엔드포인트 확인
kubectl get endpoints -n jobs-app

# DNS 확인
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup backend.jobs-app.svc.cluster.local
```

## 환경변수 커스터마이징

실제 배포 환경에 맞게 다음 파일들을 수정하세요:

- `backend-configmap.yaml`: Backend 환경변수
- `backend-secret.yaml`: JWT_SECRET 등 비밀정보
- `frontend-configmap.yaml`: Frontend 환경변수
- `ingress.yaml`: 도메인 및 SSL 설정

## 리소스 제한

현재 설정된 리소스 제한:
- MongoDB: 512Mi-2Gi 메모리, 250m-1000m CPU
- Backend: 256Mi-512Mi 메모리, 100m-500m CPU
- Frontend: 128Mi-256Mi 메모리, 50m-200m CPU

실제 트래픽에 맞게 조정하세요.
