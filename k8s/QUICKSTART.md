# 쿠버네티스 빠른 시작 가이드

## 🚀 배포 전 체크리스트

- [ ] Harbor에 로그인 (`docker login 192.168.0.240`)
- [ ] 이미지 빌드 및 푸시 완료
- [ ] Harbor Secret 생성 완료
- [ ] Backend JWT_SECRET 설정 완료

## 📋 단계별 배포

### 1단계: Harbor 로그인
```bash
docker login 192.168.0.240
# 사용자명과 비밀번호 입력
```

### 2단계: 이미지 빌드 및 푸시
```bash
cd k8s
./build-and-push-images.sh
```

이 스크립트는:
- Backend 이미지를 빌드하고 `192.168.0.240/mywork/backend:latest`로 푸시
- Frontend 이미지를 빌드하고 `192.168.0.240/mywork/frontend:latest`로 푸시

### 3단계: Harbor Secret 생성
```bash
cd k8s
./create-harbor-secret.sh
# 사용자명, 비밀번호, 이메일 입력
```

또는 수동으로:
```bash
kubectl create secret docker-registry harbor-registry-secret \
  --docker-server=192.168.0.240 \
  --docker-username=<your-username> \
  --docker-password=<your-password> \
  --docker-email=<your-email> \
  --namespace=jobs-app
```

### 4단계: Backend Secret 설정 (JWT_SECRET)
```bash
kubectl create namespace jobs-app  # 아직 없다면
kubectl apply -f backend-secret.yaml
# 또는 직접 수정
kubectl edit secret backend-secret -n jobs-app
```

### 5단계: 배포 실행
```bash
cd k8s
./deploy.sh
```

## ✅ 배포 확인

```bash
# Pod 상태 확인
kubectl get pods -n jobs-app

# 모든 리소스 확인
kubectl get all -n jobs-app

# 로그 확인
kubectl logs -f deployment/backend -n jobs-app
kubectl logs -f deployment/frontend -n jobs-app
```

## 🔗 접속 방법

### NodePort 사용
```bash
# NodePort 확인
kubectl get svc frontend -n jobs-app

# 접속: http://<노드-IP>:30080
```

### Port Forward (개발용)
```bash
kubectl port-forward svc/frontend 3000:3000 -n jobs-app
# 접속: http://localhost:3000
```

## ❓ 문제 해결

### 이미지 Pull 실패
```bash
# Secret 확인
kubectl get secret harbor-registry-secret -n jobs-app

# Pod 이벤트 확인
kubectl describe pod <pod-name> -n jobs-app
```

### Harbor 프로젝트 이름이 다른 경우
1. `build-and-push-images.sh`에서 `PROJECT_NAME` 수정
2. `backend-deployment.yaml`, `frontend-deployment.yaml`의 이미지 경로 수정
3. 이미지 다시 빌드/푸시

### 이미지 경로 형식
- 현재 설정: `192.168.0.240/mywork/backend:latest`
- 현재 설정: `192.168.0.240/mywork/frontend:latest`

Deployment 파일과 빌드 스크립트의 경로가 일치합니다!

