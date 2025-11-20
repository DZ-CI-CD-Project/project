# 선택사항 네트워크 폴리시

이 폴더에는 3-tier 구조에 필수적이지 않은 선택사항 정책들이 있습니다.

## 📁 파일 목록

### 07-allow-monitoring.yaml
- **목적**: 모니터링 시스템에서 메트릭 수집 허용
- **사용 시나리오**: Prometheus, Grafana 등 모니터링 시스템 사용 시
- **배포 방법**: 
  ```bash
  kubectl apply -f optional/07-allow-monitoring.yaml
  ```

### 08-allow-cicd.yaml
- **목적**: CI/CD 네임스페이스에서 Backend 테스트 허용
- **사용 시나리오**: CI/CD 파이프라인에서 Backend 서비스 테스트 시
- **배포 방법**:
  ```bash
  kubectl apply -f optional/08-allow-cicd.yaml
  ```

## ⚠️ 주의사항

- 이 정책들은 기본 3-tier 구조에 필수적이지 않습니다
- 필요한 경우에만 배포하세요
- 배포 전에 네임스페이스 라벨이 설정되어 있어야 합니다

