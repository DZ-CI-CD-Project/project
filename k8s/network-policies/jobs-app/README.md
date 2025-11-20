# jobs-app 네임스페이스 네트워크 폴리시

## 📋 필수 정책 (6개)

3-tier 구조에 필요한 필수 네트워크 폴리시입니다.

### 1. 00-default-deny.yaml
- **목적**: 기본 거부 정책 (모든 트래픽 차단)
- **적용**: 모든 Pod

### 2. 01-allow-dns.yaml
- **목적**: DNS 조회 허용 (kube-dns)
- **적용**: 모든 Pod
- **포트**: UDP/TCP 53

### 3. 02-allow-registry.yaml
- **목적**: Harbor 레지스트리 접근 허용 (이미지 Pull)
- **적용**: 모든 Pod
- **포트**: HTTPS 443, HTTP 80
- **IP**: 192.168.0.240

### 4. 03-allow-frontend-to-backend.yaml
- **목적**: 프론트엔드 → 백엔드 통신 허용
- **적용**: Frontend Pod
- **포트**: TCP 8000

### 5. 04-allow-backend-to-mongodb.yaml
- **목적**: 백엔드 → MongoDB 통신 허용
- **적용**: Backend Pod
- **포트**: TCP 27017

### 6. 06-allow-backend-external.yaml
- **목적**: 백엔드 → 외부 API 통신 허용 (work24.go.kr 등)
- **적용**: Backend Pod
- **포트**: HTTPS 443

## 🚀 배포 방법

### 자동 배포 (권장)
```bash
cd k8s/network-policies
./deploy-all.sh
```

### 수동 배포
```bash
# 모든 필수 정책 배포
kubectl apply -f k8s/network-policies/jobs-app/

# 또는 개별 배포
kubectl apply -f k8s/network-policies/jobs-app/00-default-deny.yaml
kubectl apply -f k8s/network-policies/jobs-app/01-allow-dns.yaml
kubectl apply -f k8s/network-policies/jobs-app/02-allow-registry.yaml
kubectl apply -f k8s/network-policies/jobs-app/03-allow-frontend-to-backend.yaml
kubectl apply -f k8s/network-policies/jobs-app/04-allow-backend-to-mongodb.yaml
kubectl apply -f k8s/network-policies/jobs-app/06-allow-backend-external.yaml
```

## 📁 디렉토리 구조

```
jobs-app/
├── 00-default-deny.yaml          ✅ 필수
├── 01-allow-dns.yaml             ✅ 필수
├── 02-allow-registry.yaml        ✅ 필수
├── 03-allow-frontend-to-backend.yaml  ✅ 필수
├── 04-allow-backend-to-mongodb.yaml   ✅ 필수
├── 06-allow-backend-external.yaml     ✅ 필수
├── optional/                     📁 선택사항
│   ├── 07-allow-monitoring.yaml
│   ├── 08-allow-cicd.yaml
│   └── README.md
└── README.md                     📄 이 파일
```

## ✅ 배포 후 확인

```bash
# 네트워크 폴리시 확인
kubectl get networkpolicies -n jobs-app

# Pod 상태 확인
kubectl get pods -n jobs-app

# 통신 테스트
kubectl run -it --rm test --image=busybox --restart=Never -n jobs-app -- sh
```

## 📚 참고

- [전체 네트워크 폴리시 가이드](../README.md)
- [선택사항 정책](../jobs-app/optional/README.md)

