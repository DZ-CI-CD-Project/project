# 네트워크 폴리시 디렉토리 정리 완료

## ✅ 정리 작업 완료

### 삭제된 파일
- ❌ `jobs-app/05-allow-ingress.yaml` - ClusterIP 사용 시 불필요
- ❌ `jobs-app/05-allow-nodeport.yaml` - 안내 문서일 뿐
- ❌ `jobs-app/09-allow-frontend-external.yaml` - ngrok 사이드카용 (VM에서 실행하므로 불필요)
- ❌ `frontend-egress.yaml` - 불필요한 파일

### 이동된 파일 (선택사항)
- 📁 `jobs-app/optional/07-allow-monitoring.yaml` - 모니터링 사용 시에만 필요
- 📁 `jobs-app/optional/08-allow-cicd.yaml` - CI/CD 테스트 시에만 필요

### 유지된 필수 파일 (6개)
- ✅ `00-default-deny.yaml` - 기본 거부
- ✅ `01-allow-dns.yaml` - DNS 허용
- ✅ `02-allow-registry.yaml` - Harbor 레지스트리
- ✅ `03-allow-frontend-to-backend.yaml` - 프론트 → 백
- ✅ `04-allow-backend-to-mongodb.yaml` - 백 → DB
- ✅ `06-allow-backend-external.yaml` - 백 → 외부 API

## 📁 최종 구조

```
network-policies/
├── jobs-app/
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
│   ├── README.md                     📄 배포 가이드
│   └── REQUIRED-POLICIES.md          📄 정책 설명
├── monitoring/                        📁 선택사항
├── ci-cd/                            📁 선택사항
├── deploy-all.sh                     🔧 자동 배포 스크립트
└── README.md                         📄 메인 가이드
```

## 🎯 정리 결과

- **필수 정책**: 6개만 유지 (3-tier 구조)
- **선택사항**: optional 폴더로 분리
- **불필요한 파일**: 삭제 완료
- **문서**: 업데이트 완료

## 🚀 배포 방법

```bash
# 자동 배포 (필수 정책만)
cd k8s/network-policies
./deploy-all.sh

# 선택사항 정책 (필요 시)
kubectl apply -f k8s/network-policies/jobs-app/optional/07-allow-monitoring.yaml
kubectl apply -f k8s/network-policies/jobs-app/optional/08-allow-cicd.yaml
```

