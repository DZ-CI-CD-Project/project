#!/bin/bash

# Harbor 레지스트리 Secret 생성 스크립트

set -e

HARBOR_HOST="192.168.0.240"
NAMESPACE="jobs-app"
SECRET_NAME="harbor-registry-secret"

echo "🔐 Harbor 레지스트리 Secret 생성"
echo "Harbor 주소: ${HARBOR_HOST}"
echo ""

# 사용자 입력 받기
read -p "Harbor 사용자명: " HARBOR_USERNAME
read -sp "Harbor 비밀번호: " HARBOR_PASSWORD
echo ""
read -p "이메일 (선택사항): " HARBOR_EMAIL

if [ -z "$HARBOR_EMAIL" ]; then
  HARBOR_EMAIL="${HARBOR_USERNAME}@example.com"
fi

# 네임스페이스 확인
if ! kubectl get namespace ${NAMESPACE} &>/dev/null; then
  echo "📦 네임스페이스 생성 중..."
  kubectl create namespace ${NAMESPACE}
fi

# 기존 Secret 삭제 (있다면)
if kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} &>/dev/null; then
  echo "🗑️  기존 Secret 삭제 중..."
  kubectl delete secret ${SECRET_NAME} -n ${NAMESPACE}
fi

# Secret 생성
echo "🔑 Secret 생성 중..."
kubectl create secret docker-registry ${SECRET_NAME} \
  --docker-server=${HARBOR_HOST} \
  --docker-username=${HARBOR_USERNAME} \
  --docker-password=${HARBOR_PASSWORD} \
  --docker-email=${HARBOR_EMAIL} \
  --namespace=${NAMESPACE}

echo ""
echo "✅ Secret 생성 완료!"
echo ""
echo "📋 생성된 Secret 확인:"
kubectl get secret ${SECRET_NAME} -n ${NAMESPACE}

