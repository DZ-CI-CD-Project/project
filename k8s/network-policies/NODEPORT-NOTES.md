# NodePort 사용 시 네트워크 폴리시 주의사항

## 📋 현재 설정

- **Frontend**: NodePort 30080 (외부 접근 가능)
- **Backend**: ClusterIP (내부 접근만)
- **MongoDB**: ClusterIP (내부 접근만)

## ⚠️ 중요 사항

### NetworkPolicy의 한계

**NetworkPolicy는 Pod 간 통신만 제어합니다.**

- ✅ Pod → Pod 통신 제어 가능
- ✅ Pod → 외부 통신 제어 가능 (Egress)
- ❌ 외부 → Pod 통신 제어 불가 (NodePort/LoadBalancer)

NodePort를 통한 외부 접근은 **kube-proxy**가 처리하며, NetworkPolicy로 직접 제어할 수 없습니다.

## 🔒 보안 고려사항

### 현재 상태
- NodePort 30080은 **모든 외부 IP에서 접근 가능**합니다.
- NetworkPolicy로는 이 접근을 제한할 수 없습니다.

### 보안 강화 방법

#### 1. 방화벽 규칙 사용 (권장)
```bash
# iptables 예시 (노드에서 실행)
# 특정 IP 대역만 허용
iptables -A INPUT -p tcp --dport 30080 -s 192.168.0.0/24 -j ACCEPT
iptables -A INPUT -p tcp --dport 30080 -j DROP

# 또는 firewalld 사용
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.0.0/24" port protocol="tcp" port="30080" accept'
firewall-cmd --reload
```

#### 2. LoadBalancer + NetworkPolicy 조합
- LoadBalancer를 사용하고, 특정 IP 대역에서만 접근 허용
- NetworkPolicy로 추가 보안 레이어 적용

#### 3. Ingress Controller 사용
- Ingress Controller를 사용하면 NetworkPolicy로 제어 가능
- SSL/TLS 종료, 라우팅 규칙 등 추가 기능 사용 가능

## 📝 적용된 변경사항

### Ingress 정책 비활성화
- `jobs-app/05-allow-ingress.yaml`: NodePort 사용 시 불필요하므로 비활성화
- Ingress를 사용하는 경우 파일 내 주석을 해제하고 네임스페이스 이름 수정

### NodePort 안내 파일 추가
- `jobs-app/05-allow-nodeport.yaml`: NodePort 사용 시 주의사항 문서화

## 🚀 배포 시 주의사항

1. **NodePort는 기본적으로 모든 외부 IP에서 접근 가능**
   - 보안이 필요한 경우 방화벽 규칙 필수

2. **NetworkPolicy는 Pod 간 통신만 제어**
   - Frontend → Backend 통신: ✅ 제어 가능
   - 외부 → Frontend (NodePort): ❌ 제어 불가

3. **배포 스크립트 자동 감지**
   - `deploy-all.sh`가 NodePort 사용을 자동으로 감지하고 안내

## 🔍 확인 방법

```bash
# Frontend 서비스 타입 확인
kubectl get svc frontend -n jobs-app

# NodePort 확인
kubectl get svc frontend -n jobs-app -o jsonpath='{.spec.ports[0].nodePort}'

# 외부 접근 테스트
curl http://<노드-IP>:30080
```

## 📚 참고

- [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Service Types](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types)
- [NodePort Limitations](https://kubernetes.io/docs/concepts/services-networking/service/#nodeport)

