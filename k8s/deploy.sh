#!/bin/bash

# 쿠버네티스 배포 스크립트

set -e

NAMESPACE="jobs-app"
K8S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 쿠버네티스 배포 시작..."

# Harbor Secret 확인
echo "🔐 Harbor Secret 확인 중..."
if ! kubectl get secret harbor-registry-secret -n "${NAMESPACE}" &>/dev/null; then
  echo "⚠️  Harbor 레지스트리 Secret이 없습니다!"
  echo "먼저 다음 명령어로 Secret을 생성하세요:"
  echo "  ./create-harbor-secret.sh"
  exit 1
fi

# 네임스페이스 생성
echo "📦 네임스페이스 생성 중..."
kubectl apply -f "${K8S_DIR}/namespace.yaml"

# MongoDB 배포
echo "🗄️  MongoDB 배포 중..."
kubectl apply -f "${K8S_DIR}/mongodb-pvc.yaml"
kubectl apply -f "${K8S_DIR}/mongodb-deployment.yaml"
kubectl apply -f "${K8S_DIR}/mongodb-service.yaml"

# Backend 배포
echo "⚙️  Backend 배포 중..."
kubectl apply -f "${K8S_DIR}/backend-configmap.yaml"
kubectl apply -f "${K8S_DIR}/backend-secret.yaml"
kubectl apply -f "${K8S_DIR}/backend-deployment.yaml"
kubectl apply -f "${K8S_DIR}/backend-service.yaml"

# Frontend 배포
echo "🎨 Frontend 배포 중..."
kubectl apply -f "${K8S_DIR}/frontend-configmap.yaml"
kubectl apply -f "${K8S_DIR}/frontend-deployment.yaml"
kubectl apply -f "${K8S_DIR}/frontend-service.yaml"

# Ingress 배포 (선택사항)
if [ "$1" == "--with-ingress" ]; then
  echo "🌐 Ingress 배포 중..."
  kubectl apply -f "${K8S_DIR}/ingress.yaml"
fi

echo "⏳ Pod가 준비될 때까지 대기 중..."
kubectl wait --for=condition=ready pod -l app=mongodb -n "${NAMESPACE}" --timeout=120s || true
kubectl wait --for=condition=ready pod -l app=backend -n "${NAMESPACE}" --timeout=120s || true
kubectl wait --for=condition=ready pod -l app=frontend -n "${NAMESPACE}" --timeout=120s || true

echo "✅ 배포 완료!"
echo ""
echo "📊 상태 확인:"
kubectl get all -n "${NAMESPACE}"

echo ""
echo "🔗 접속 정보:"
echo "  - Frontend NodePort: $(kubectl get svc frontend -n ${NAMESPACE} -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo '확인 필요')"
echo "  - Backend Service: backend.${NAMESPACE}.svc.cluster.local:8000"

