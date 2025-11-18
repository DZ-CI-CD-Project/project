#!/bin/bash

# 쿠버네티스 리소스 재시작 스크립트 (중단된 리소스 다시 시작)
# stop.sh로 중단한 후 다시 시작할 때 사용

set -e

NAMESPACE="jobs-app"
K8S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "▶️  쿠버네티스 리소스 재시작 중..."
echo ""

# 네임스페이스 확인
if ! kubectl get namespace "${NAMESPACE}" &>/dev/null; then
  echo "⚠️  네임스페이스 '${NAMESPACE}'가 없습니다."
  echo "   먼저 deploy.sh를 실행하세요."
  exit 1
fi

# Deployment 스케일 업 (원래 replicas 수로 복구)
# 먼저 deployment 파일에서 replicas 수 확인
BACKEND_REPLICAS=$(grep -A 1 "replicas:" "${K8S_DIR}/backend-deployment.yaml" | grep -E "^\s*replicas:" | awk '{print $2}' | tr -d '\r\n' || echo "3")
FRONTEND_REPLICAS=$(grep -A 1 "replicas:" "${K8S_DIR}/frontend-deployment.yaml" | grep -E "^\s*replicas:" | awk '{print $2}' | tr -d '\r\n' || echo "3")
MONGODB_REPLICAS="1"

echo "🔄 Backend 재시작 중... (replicas: ${BACKEND_REPLICAS})"
kubectl scale deployment backend --replicas="${BACKEND_REPLICAS}" -n "${NAMESPACE}" 2>/dev/null || echo "  Backend deployment 없음"

echo "🔄 Frontend 재시작 중... (replicas: ${FRONTEND_REPLICAS})"
kubectl scale deployment frontend --replicas="${FRONTEND_REPLICAS}" -n "${NAMESPACE}" 2>/dev/null || echo "  Frontend deployment 없음"

echo "🔄 MongoDB 재시작 중... (replicas: ${MONGODB_REPLICAS})"
kubectl scale deployment mongodb --replicas="${MONGODB_REPLICAS}" -n "${NAMESPACE}" 2>/dev/null || echo "  MongoDB deployment 없음"

# Pod이 준비될 때까지 대기
echo ""
echo "⏳ Pod 준비 대기 중..."
sleep 10

# 상태 확인
echo ""
echo "📊 현재 상태:"
kubectl get deployment -n "${NAMESPACE}" 2>/dev/null || echo "  리소스 없음"

echo ""
kubectl get pods -n "${NAMESPACE}" 2>/dev/null || echo "  Pod 없음"

echo ""
echo "✅ 재시작 완료!"
echo ""
echo "🔗 접속 정보:"
echo "  - Frontend NodePort: $(kubectl get svc frontend -n ${NAMESPACE} -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo '확인 필요')"

