#!/bin/bash

# 쿠버네티스 리소스 중단 스크립트 (삭제하지 않고 중단만)
# 나중에 deploy.sh를 다시 실행하면 복구됩니다

set -e

NAMESPACE="jobs-app"
K8S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "⏸️  쿠버네티스 리소스 중단 중..."
echo "📝 참고: 리소스는 삭제되지 않고 replicas만 0으로 설정됩니다."
echo "📝 PVC(데이터)와 설정은 모두 유지됩니다."
echo ""

# 네임스페이스 확인
if ! kubectl get namespace "${NAMESPACE}" &>/dev/null; then
  echo "⚠️  네임스페이스 '${NAMESPACE}'가 없습니다. 이미 중단된 상태입니다."
  exit 0
fi

# Deployment 스케일 다운 (Pod만 중지, Deployment는 유지)
echo "🛑 Backend 중단 중..."
kubectl scale deployment backend --replicas=0 -n "${NAMESPACE}" 2>/dev/null || echo "  Backend deployment 없음"

echo "🛑 Frontend 중단 중..."
kubectl scale deployment frontend --replicas=0 -n "${NAMESPACE}" 2>/dev/null || echo "  Frontend deployment 없음"

echo "🛑 MongoDB 중단 중..."
kubectl scale deployment mongodb --replicas=0 -n "${NAMESPACE}" 2>/dev/null || echo "  MongoDB deployment 없음"

# Pod이 완전히 종료될 때까지 대기
echo ""
echo "⏳ Pod 종료 대기 중..."
sleep 5

# 상태 확인
echo ""
echo "📊 현재 상태:"
kubectl get deployment -n "${NAMESPACE}" 2>/dev/null || echo "  리소스 없음"

echo ""
kubectl get pods -n "${NAMESPACE}" 2>/dev/null || echo "  Pod 없음"

echo ""
echo "✅ 중단 완료!"
echo ""
echo "📝 유지된 리소스:"
echo "  - Deployment 정의 (replicas=0)"
echo "  - PVC (데이터 유지)"
echo "  - ConfigMap, Secret"
echo "  - Service"
echo ""
echo "🔄 다시 시작하려면:"
echo "  cd ${K8S_DIR} && ./deploy.sh"
echo ""
echo "⚠️  완전히 삭제하려면:"
echo "  cd ${K8S_DIR} && ./undeploy.sh"

