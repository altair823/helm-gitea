#!/bin/bash
# Gitea Prod 환경 백업 스크립트
# 사용법: ./backup-prod.sh [백업_디렉토리]

set -euo pipefail

# 설정
BACKUP_DIR="${1:-/tmp/gitea-backup-prod-$(date +%Y%m%d-%H%M%S)}"
NAMESPACE="gitea"
PG_NAMESPACE="postgres-gitea"
PG_CLUSTER="postgres-gitea"
PG_USER="gitea"
PG_DB="gitea"

# 색상
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Gitea Prod 백업 시작 ===${NC}"
echo "백업 디렉토리: ${BACKUP_DIR}"

# 컨텍스트 전환
kubectx prod

# 백업 디렉토리 생성
mkdir -p "${BACKUP_DIR}"

# 1. PostgreSQL 백업
echo -e "${YELLOW}[1/2] PostgreSQL 백업 중...${NC}"
PG_POD=$(kubectl get pods -n ${PG_NAMESPACE} -l postgres-operator.crunchydata.com/cluster=${PG_CLUSTER},postgres-operator.crunchydata.com/role=master -o jsonpath='{.items[0].metadata.name}')
PG_PASSWORD=$(kubectl get secret -n ${PG_NAMESPACE} ${PG_CLUSTER}-pguser-${PG_USER} -o jsonpath='{.data.password}' | base64 -d)

kubectl exec -n ${PG_NAMESPACE} ${PG_POD} -- bash -c "PGPASSWORD='${PG_PASSWORD}' pg_dump -h localhost -U ${PG_USER} -d ${PG_DB} --no-owner --no-acl" > "${BACKUP_DIR}/gitea-db.sql"
echo "  -> ${BACKUP_DIR}/gitea-db.sql ($(du -h "${BACKUP_DIR}/gitea-db.sql" | cut -f1))"

# 2. PVC 데이터 백업
echo -e "${YELLOW}[2/2] PVC 데이터 백업 중...${NC}"
GITEA_POD=$(kubectl get pods -n ${NAMESPACE} -l app=gitea -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -n "${GITEA_POD}" ]; then
    # Gitea pod가 실행 중이면 직접 복사 (lost+found 제외)
    mkdir -p "${BACKUP_DIR}/pvc-data"
    kubectl exec -n ${NAMESPACE} ${GITEA_POD} -- tar cf - --exclude='lost+found' -C /data . 2>/dev/null | tar xf - -C "${BACKUP_DIR}/pvc-data" --warning=no-unknown-keyword 2>/dev/null || true
else
    # Gitea pod가 없으면 임시 pod 생성
    echo "  -> Gitea pod가 없어서 임시 pod 생성..."
    PVC_NAME=$(kubectl get pvc -n ${NAMESPACE} -l app=gitea -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "gitea-shared-storage-rev2")

    kubectl run backup-temp -n ${NAMESPACE} --rm -i --restart=Never \
        --image=docker.gitea.com/gitea:1.25.2-rootless \
        --overrides="{\"spec\":{\"containers\":[{\"name\":\"backup-temp\",\"image\":\"docker.gitea.com/gitea:1.25.2-rootless\",\"command\":[\"tar\",\"cf\",\"-\",\"/data\"],\"volumeMounts\":[{\"name\":\"data\",\"mountPath\":\"/data\"}]}],\"volumes\":[{\"name\":\"data\",\"persistentVolumeClaim\":{\"claimName\":\"${PVC_NAME}\"}}]}}" \
        > "${BACKUP_DIR}/pvc-data.tar"

    mkdir -p "${BACKUP_DIR}/pvc-data"
    tar xf "${BACKUP_DIR}/pvc-data.tar" -C "${BACKUP_DIR}/pvc-data" --strip-components=1
    rm "${BACKUP_DIR}/pvc-data.tar"
fi

echo "  -> ${BACKUP_DIR}/pvc-data/ ($(du -sh "${BACKUP_DIR}/pvc-data" | cut -f1))"

# 완료
echo -e "${GREEN}=== 백업 완료 ===${NC}"
echo "백업 위치: ${BACKUP_DIR}"
ls -lh "${BACKUP_DIR}"
