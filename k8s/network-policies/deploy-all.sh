#!/bin/bash

# 네트워크 폴리시 전체 배포 스크립트

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "🔒 네트워크 폴리시 배포 시작..."
echo ""

# 네임스페이스 라벨 확인 및 설정
echo "📋 네임스페이스 라벨 확인 중..."

# jobs-app 네임스페이스 라벨 확인
if ! kubectl get namespace jobs-app -o jsonpath='{.metadata.labels.name}' 2>/dev/null | grep -q jobs-app; then
  echo "  → jobs-app 네임스페이스에 라벨 추가 중..."
  kubectl label namespace jobs-app name=jobs-app --overwrite
else
  echo "  ✅ jobs-app 네임스페이스 라벨 확인됨"
fi

# kube-system 네임스페이스 라벨 확인
if ! kubectl get namespace kube-system -o jsonpath='{.metadata.labels.name}' 2>/dev/null | grep -q kube-system; then
  echo "  → kube-system 네임스페이스에 라벨 추가 중..."
  kubectl label namespace kube-system name=kube-system --overwrite
else
  echo "  ✅ kube-system 네임스페이스 라벨 확인됨"
fi

# 서비스 타입 확인
echo "  → 서비스 타입 확인 중..."
FRONTEND_SVC_TYPE=$(kubectl get svc frontend -n jobs-app -o jsonpath='{.spec.type}' 2>/dev/null || echo "")
if [ "$FRONTEND_SVC_TYPE" = "ClusterIP" ]; then
  echo "    ✅ Frontend는 ClusterIP를 사용합니다."
  echo "    ℹ️  외부 접근은 ngrok 등을 통해 가능합니다."
elif [ "$FRONTEND_SVC_TYPE" = "NodePort" ]; then
  echo "    ⚠️  Frontend는 NodePort를 사용합니다."
  echo "    ℹ️  ClusterIP로 변경하면 외부 접근을 더 안전하게 제어할 수 있습니다."
fi

echo ""
echo "🚀 jobs-app 네임스페이스 필수 네트워크 폴리시 배포 중..."
# 필수 정책만 배포 (선택사항 제외)
kubectl apply -f "${SCRIPT_DIR}/jobs-app/00-default-deny.yaml"
kubectl apply -f "${SCRIPT_DIR}/jobs-app/01-allow-dns.yaml"
kubectl apply -f "${SCRIPT_DIR}/jobs-app/02-allow-registry.yaml"
kubectl apply -f "${SCRIPT_DIR}/jobs-app/03-allow-frontend-to-backend.yaml"
kubectl apply -f "${SCRIPT_DIR}/jobs-app/04-allow-backend-to-mongodb.yaml"
kubectl apply -f "${SCRIPT_DIR}/jobs-app/06-allow-backend-external.yaml"

echo ""
echo "ℹ️  선택사항 정책:"
echo "   - 모니터링 사용 시: kubectl apply -f jobs-app/optional/07-allow-monitoring.yaml"
echo "   - CI/CD 테스트 시: kubectl apply -f jobs-app/optional/08-allow-cicd.yaml"
echo ""

# 배포된 네트워크 폴리시 확인
echo "📊 배포된 네트워크 폴리시 확인:"
kubectl get networkpolicies -n jobs-app

echo ""
echo "✅ jobs-app 네임스페이스 네트워크 폴리시 배포 완료!"
echo ""
echo "🔍 다음 단계:"
echo "   1. 애플리케이션 동작 확인: kubectl get pods -n jobs-app"
echo "   2. 서비스 통신 테스트: kubectl run -it --rm test --image=busybox --restart=Never -n jobs-app -- sh"
echo "   3. 네트워크 폴리시 상세 확인: kubectl describe networkpolicy -n jobs-app"

