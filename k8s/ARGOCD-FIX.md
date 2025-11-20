# ArgoCD Frontend Service 수정 가이드

## 문제
ArgoCD가 GitHub 저장소에서 `frontend-service.yaml`을 자동으로 동기화하면서 Service를 NodePort로 되돌리고 있습니다.

## 해결 방법

### 1. GitHub 저장소 확인
ArgoCD Application 설정에 따르면:
- **저장소**: `https://github.com/DZ-CI-CD-Project/project.git`
- **경로**: `k8s`
- **브랜치**: `main`

### 2. 로컬 파일 확인
현재 로컬의 `k8s/frontend-service.yaml`은 이미 ClusterIP로 설정되어 있습니다:
```yaml
spec:
  type: ClusterIP  # 외부 접근 차단, ngrok을 통해서만 접근 가능
```

### 3. GitHub 저장소에 푸시
다음 명령어로 GitHub 저장소에 변경사항을 푸시하세요:

```bash
cd /home/kevin/LABs/proj
git add k8s/frontend-service.yaml
git commit -m "Change frontend service to ClusterIP for ngrok access"
git push origin main
```

### 4. ArgoCD 자동 동기화 확인
ArgoCD는 `automated.syncPolicy`가 활성화되어 있어 자동으로 동기화됩니다:
- `selfHeal: true` - 수동 변경사항을 자동으로 되돌림
- `prune: true` - 삭제된 리소스를 자동으로 정리

### 5. 수동 동기화 (선택사항)
ArgoCD UI에서 또는 다음 명령어로 수동 동기화:
```bash
kubectl patch application dz-ci-cd-app -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
```

## 참고
- ArgoCD Application 이름: `dz-ci-cd-app`
- 네임스페이스: `argocd`
- 현재 상태 확인: `kubectl get application dz-ci-cd-app -n argocd`

