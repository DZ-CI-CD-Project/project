# 3-tier 구조에 필요한 네트워크 폴리시

## ✅ 필수 정책 (6개)

### 1. 00-default-deny.yaml
- **목적**: 기본 거부 정책 (모든 트래픽 차단)
- **필수**: ✅

### 2. 01-allow-dns.yaml
- **목적**: DNS 조회 허용 (kube-dns)
- **필수**: ✅ (모든 Pod가 필요)

### 3. 02-allow-registry.yaml
- **목적**: Harbor 레지스트리 접근 허용 (이미지 Pull)
- **필수**: ✅ (Pod 시작 시 이미지 Pull 필요)

### 4. 03-allow-frontend-to-backend.yaml
- **목적**: 프론트 → 백 통신 허용
- **필수**: ✅ (3-tier 구조)

### 5. 04-allow-backend-to-mongodb.yaml
- **목적**: 백 → DB 통신 허용
- **필수**: ✅ (3-tier 구조)

### 6. 06-allow-backend-external.yaml
- **목적**: 백 → 외부 API 통신 허용 (work24.go.kr 등)
- **필수**: ✅ (외부 API 데이터 수신)

## ❌ 불필요한 정책 (현재 구성 기준)

### 05-allow-ingress.yaml
- **이유**: ClusterIP 사용 시 Ingress 불필요
- **상태**: 이미 주석 처리됨
- **조치**: 삭제 가능 또는 유지 (주석 상태)

### 05-allow-nodeport.yaml
- **이유**: 안내 문서일 뿐, 실제 NetworkPolicy 아님
- **상태**: YAML이 아닌 주석 파일
- **조치**: 삭제 가능

### 07-allow-monitoring.yaml
- **이유**: 모니터링 시스템 사용 시에만 필요
- **상태**: 선택사항
- **조치**: 모니터링 사용하지 않으면 삭제 가능

### 08-allow-cicd.yaml
- **이유**: CI/CD 네임스페이스에서 테스트 시에만 필요
- **상태**: 선택사항
- **조치**: CI/CD 네임스페이스에서 테스트하지 않으면 삭제 가능

### 09-allow-frontend-external.yaml
- **이유**: ngrok 사이드카 사용 시 필요했지만, VM에서 ngrok 실행하므로 불필요
- **상태**: 불필요
- **조치**: 삭제 가능

## 📋 최소 구성 (3-tier 구조만)

```
jobs-app/
├── 00-default-deny.yaml          ✅ 필수
├── 01-allow-dns.yaml             ✅ 필수
├── 02-allow-registry.yaml        ✅ 필수
├── 03-allow-frontend-to-backend.yaml  ✅ 필수
├── 04-allow-backend-to-mongodb.yaml   ✅ 필수
└── 06-allow-backend-external.yaml     ✅ 필수
```

## 🗑️ 삭제 가능한 파일

```
jobs-app/
├── 05-allow-ingress.yaml         ❌ 삭제 가능 (주석 처리됨)
├── 05-allow-nodeport.yaml        ❌ 삭제 가능 (문서일 뿐)
├── 07-allow-monitoring.yaml      ❌ 삭제 가능 (선택사항)
├── 08-allow-cicd.yaml            ❌ 삭제 가능 (선택사항)
└── 09-allow-frontend-external.yaml ❌ 삭제 가능 (불필요)
```

## 🎯 정리된 구조

**필수 정책만 사용:**
- 기본 거부 + DNS + 레지스트리
- 프론트 → 백
- 백 → DB
- 백 → 외부 API

**총 6개 파일만 필요**

