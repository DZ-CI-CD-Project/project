#!/bin/bash

# Harbor에 이미지 빌드 및 푸시 스크립트

set -e

HARBOR_HOST="192.168.0.240"
PROJECT_NAME="mywork"  # Harbor 프로젝트 이름

BACKEND_IMAGE="${HARBOR_HOST}/${PROJECT_NAME}/backend:latest"
FRONTEND_IMAGE="${HARBOR_HOST}/${PROJECT_NAME}/frontend:latest"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "🐳 Harbor 이미지 빌드 및 푸시 시작..."
echo "Harbor 주소: ${HARBOR_HOST}"
echo ""

# Harbor 로그인 확인
echo "🔐 Harbor 로그인 확인 중..."
if ! docker info | grep -q "Username"; then
  echo "⚠️  Harbor에 로그인되지 않았습니다."
  echo "다음 명령어로 로그인하세요:"
  echo "  docker login ${HARBOR_HOST}"
  read -p "지금 로그인하시겠습니까? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker login ${HARBOR_HOST}
  else
    echo "❌ 로그인이 필요합니다. 종료합니다."
    exit 1
  fi
fi

# Backend 이미지 빌드
echo ""
echo "🔨 Backend 이미지 빌드 중..."
cd "${PROJECT_ROOT}/backend"
# --network=host: 호스트 네트워크를 사용하여 DNS 문제 해결
docker build --network=host -t ${BACKEND_IMAGE} .

# Frontend 이미지 빌드
echo ""
echo "🔨 Frontend 이미지 빌드 중..."
cd "${PROJECT_ROOT}/frontend/app"
# --network=host: 호스트 네트워크를 사용하여 DNS 문제 해결
docker build --network=host -t ${FRONTEND_IMAGE} .

# 이미지 푸시
echo ""
echo "📤 Harbor에 이미지 푸시 중..."
docker push ${BACKEND_IMAGE}
docker push ${FRONTEND_IMAGE}

echo ""
echo "✅ 이미지 빌드 및 푸시 완료!"
echo ""
echo "📦 푸시된 이미지:"
echo "  - ${BACKEND_IMAGE}"
echo "  - ${FRONTEND_IMAGE}"
echo ""
echo "🚀 다음 단계:"
echo "  1. Harbor 레지스트리 Secret 생성:"
echo "     kubectl create secret docker-registry harbor-registry-secret \\"
echo "       --docker-server=${HARBOR_HOST} \\"
echo "       --docker-username=<your-username> \\"
echo "       --docker-password=<your-password> \\"
echo "       --docker-email=<your-email> \\"
echo "       --namespace=jobs-app"
echo ""
echo "  2. 쿠버네티스 배포:"
echo "     cd k8s && ./deploy.sh"

