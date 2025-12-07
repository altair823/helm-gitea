# Gitea Kustomize 구성

이 디렉토리는 Gitea Helm Chart를 Kustomize로 래핑하여 dev와 prod 환경에서 사용할 수 있도록 구성합니다.

## 구조

```
kustomize/
├── base/                    # 기본 설정
│   ├── kustomization.yaml   # 기본 Kustomize 설정
│   └── values-base.yaml     # 공통 values 파일
└── overlays/
    ├── dev/                 # 개발 환경
    │   ├── kustomization.yaml
    │   └── values-dev.yaml
    └── prod/                # 프로덕션 환경
        ├── kustomization.yaml
        └── values-prod.yaml
```

## 사용 방법

### 1. Helm 템플릿 렌더링

로컬 Helm Chart를 사용하기 위해 먼저 Helm 템플릿을 렌더링해야 합니다:

```bash
# 모든 환경 렌더링
cd kustomize
make render-all

# 또는 개별 환경만 렌더링
make render-dev
make render-prod
```

### 2. 개발 환경 배포

```bash
# Helm 템플릿 렌더링 (처음 한 번만)
cd kustomize && make render-dev

# 배포
kubectl apply -k kustomize/overlays/dev
```

또는 미리보기:

```bash
kubectl kustomize kustomize/overlays/dev
```

### 3. 프로덕션 환경 배포

```bash
# Helm 템플릿 렌더링 (처음 한 번만)
cd kustomize && make render-prod

# 배포
kubectl apply -k kustomize/overlays/prod
```

또는 미리보기:

```bash
kubectl kustomize kustomize/overlays/prod
```

### 4. 렌더링된 파일 정리

```bash
cd kustomize
make clean
```

## 환경별 차이점

### 개발 환경 (dev)
- 단일 replica
- 작은 리소스 할당 (500m CPU, 512Mi 메모리)
- 작은 스토리지 (5Gi)
- 개발용 도메인 (git-dev.example.com)
- Let's Encrypt staging 인증서

### 프로덕션 환경 (prod)
- 다중 replica (2개) - HA 구성
- 큰 리소스 할당 (2000m CPU, 2Gi 메모리)
- 큰 스토리지 (50Gi)
- ReadWriteMany 스토리지 (HA용)
- 프로덕션 도메인 (git.example.com)
- Let's Encrypt 프로덕션 인증서
- 메트릭 활성화
- Pod Disruption Budget 설정
- Priority Class 설정
- Node Selector 및 Tolerations

## 주의사항

### 프로덕션 환경 설정

프로덕션 환경에서는 보안을 위해 다음을 설정해야 합니다:

1. **관리자 비밀번호**: `gitea.admin.existingSecret`을 사용하여 Secret에서 비밀번호를 가져오도록 설정
2. **데이터베이스 비밀번호**: PostgreSQL 비밀번호를 Secret으로 관리
3. **메트릭 토큰**: `gitea.metrics.token`을 Secret으로 설정

### Secret 생성 예시

```bash
# 관리자 Secret 생성
kubectl create secret generic gitea-admin-secret \
  --from-literal=username=gitea_admin \
  --from-literal=password=secure-password \
  --namespace=gitea-prod

# 데이터베이스 Secret 생성
kubectl create secret generic gitea-postgres-secret \
  --from-literal=password=secure-db-password \
  --namespace=gitea-prod
```

## 커스터마이징

각 환경의 `values-*.yaml` 파일을 수정하여 환경별 설정을 변경할 수 있습니다.

## 요구사항

- Kubernetes 1.19+
- kubectl 1.19+
- Kustomize 4.5.0+ (helmCharts 리소스 지원)

## 참고

- **로컬 Helm Chart 사용**: 이 Kustomize 구성은 루트 디렉토리의 로컬 Helm Chart를 사용합니다.
- Helm 템플릿을 렌더링하려면 `make render-dev` 또는 `make render-prod`를 실행하세요.
- `rendered-manifests.yaml` 파일은 Git에 커밋하지 않는 것을 권장합니다 (자동 생성 파일).
- values 파일을 수정한 후에는 다시 렌더링해야 합니다.

