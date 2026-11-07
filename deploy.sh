#!/bin/bash

ROOT="$(cd "$(dirname "$0")" && pwd)"

PARTS=()
for SCRIPT in "${ROOT}"/*/deploy.sh; do
    [ -f "${SCRIPT}" ] && PARTS+=("$(basename "$(dirname "${SCRIPT}")")")
done

usage() {
    echo "usage: ./deploy.sh <user> <host> <part>... | all"
    echo "parts: ${PARTS[*]}"
    exit 1
}

REMOTE_USER=$1
REMOTE_HOST=$2
shift 2 2>/dev/null

if [ -z "${REMOTE_USER}" ] || [ -z "${REMOTE_HOST}" ] || [ $# -eq 0 ]; then
    usage
fi

if [ "$1" = "all" ]; then
    SELECTED=("${PARTS[@]}")
else
    SELECTED=("$@")
fi

for PART in "${SELECTED[@]}"; do
    if [[ ! " ${PARTS[*]} " =~ " ${PART} " ]]; then
        echo "unknown part: ${PART}"
        usage
    fi
done

export SERVICE_USER="${SERVICE_USER:-heating}"

echo "== ensuring service user ${SERVICE_USER}"
ssh "${REMOTE_USER}@${REMOTE_HOST}" \
    "id ${SERVICE_USER} >/dev/null 2>&1 || sudo useradd --system --no-create-home --shell /usr/sbin/nologin ${SERVICE_USER}; sudo usermod -aG gpio,systemd-journal ${SERVICE_USER}" \
    || exit 1

FAILED=()
for PART in "${SELECTED[@]}"; do
    echo "== deploying ${PART}"
    if ! (cd "${ROOT}/${PART}" && ./deploy.sh "${REMOTE_USER}" "${REMOTE_HOST}"); then
        FAILED+=("${PART}")
    fi
done

if [ ${#FAILED[@]} -gt 0 ]; then
    echo "failed: ${FAILED[*]}"
    exit 1
fi
