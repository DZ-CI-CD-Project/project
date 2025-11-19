#!/bin/bash

# CORS 설정 업데이트 스크립트
# 다른 서버에서도 동일하게 실행하면 됩니다

set -e

NAMESPACE="jobs-app"
NEW_ORIGIN="${1:-http://192.168.56.200:30080}"

echo "🔧 CORS 설정 업데이트 중..."
echo "추가할 Origin: ${NEW_ORIGIN}"
echo ""

# 현재 ConfigMap 가져오기
CURRENT_ORIGINS=$(kubectl get configmap backend-config -n "${NAMESPACE}" -o jsonpath='{.data.ALLOWED_ORIGINS}')

echo "현재 ALLOWED_ORIGINS: ${CURRENT_ORIGINS}"
echo ""

# 이미 포함되어 있는지 확인
if echo "${CURRENT_ORIGINS}" | grep -q "${NEW_ORIGIN}"; then
  echo "✅ ${NEW_ORIGIN}이 이미 포함되어 있습니다."
  exit 0
fi

# 새로운 origin 추가
if [ -z "${CURRENT_ORIGINS}" ]; then
  NEW_ORIGINS="${NEW_ORIGIN}"
else
  NEW_ORIGINS="${CURRENT_ORIGINS},${NEW_ORIGIN}"
fi

echo "업데이트할 ALLOWED_ORIGINS: ${NEW_ORIGINS}"
echo ""

# ConfigMap 업데이트
kubectl patch configmap backend-config -n "${NAMESPACE}" \
  --type merge \
  -p "{\"data\":{\"ALLOWED_ORIGINS\":\"${NEW_ORIGINS}\"}}"

echo "✅ ConfigMap 업데이트 완료"
echo ""

# Backend 재시작
echo "🔄 Backend 재시작 중..."
kubectl rollout restart deployment/backend -n "${NAMESPACE}"

echo ""
echo "⏳ Pod 재시작 대기 중..."
kubectl rollout status deployment/backend -n "${NAMESPACE}" --timeout=60s

echo ""
echo "✅ 완료!"
echo ""
echo "📊 현재 상태:"
kubectl get pods -n "${NAMESPACE}" | grep backend


