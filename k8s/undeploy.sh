#!/bin/bash

# 쿠버네티스 리소스 삭제 스크립트

set -e

NAMESPACE="jobs-app"
K8S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🗑️  쿠버네티스 리소스 삭제 중..."

# 모든 리소스 삭제
kubectl delete -f "${K8S_DIR}/" --ignore-not-found=true

# 또는 네임스페이스 전체 삭제 (더 빠름, 하지만 모든 데이터 삭제됨)
if [ "$1" == "--all" ]; then
  echo "⚠️  네임스페이스 전체 삭제 (모든 데이터 포함)..."
  kubectl delete namespace "${NAMESPACE}" --ignore-not-found=true
else
  echo "✅ 리소스 삭제 완료 (PVC는 유지됨)"
  echo "💡 PVC까지 삭제하려면: kubectl delete pvc mongodb-pvc -n ${NAMESPACE}"
fi

