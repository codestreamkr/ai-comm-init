#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/fightmin/chatgpt-codex-init.git"
TARGET_DIR="${HOME}/.codex"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
AGENTS_PATH="${TARGET_DIR}/AGENTS.md"
TMP_CLONE_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t codex-init)"
SOURCE_AGENTS_PATH="${TMP_CLONE_DIR}/AGENTS.md"
SOURCE_SKILLS_PATH="${TMP_CLONE_DIR}/skills"

if ! command -v git >/dev/null 2>&1; then
  echo "git 명령을 찾을 수 없습니다. Git 설치 후 다시 실행하세요." >&2
  exit 1
fi

backup_and_remove_if_exists() {
  local path="$1"
  if [[ -e "${path}" ]]; then
    local backup_path="${path}_backup_${TIMESTAMP}"
    cp -a "${path}" "${backup_path}"
    rm -rf "${path}"
    echo "Backup created: ${backup_path}"
  fi
}

cleanup() {
  if [[ -d "${TMP_CLONE_DIR}" ]]; then
    rm -rf "${TMP_CLONE_DIR}"
  fi
}
trap cleanup EXIT

git clone "${REPO_URL}" "${TMP_CLONE_DIR}"

if [[ ! -d "${TARGET_DIR}" ]]; then
  mkdir -p "${TARGET_DIR}"
fi

if [[ -d "${TARGET_DIR}" ]]; then
  backup_and_remove_if_exists "${AGENTS_PATH}"

  if [[ -d "${TARGET_DIR}/.git" ]]; then
    git_backup_path="${TARGET_DIR}/.git_backup_${TIMESTAMP}"
    mv "${TARGET_DIR}/.git" "${git_backup_path}"
    echo "Backup created: ${git_backup_path}"
  fi

  cp "${SOURCE_AGENTS_PATH}" "${AGENTS_PATH}"

  rm -rf "${TARGET_DIR}/skills"
  cp -R "${SOURCE_SKILLS_PATH}" "${TARGET_DIR}/skills"

  echo "Applied templates to: ${TARGET_DIR}"
fi

echo "Done. Run 'codex' and login again (auth.json is user-specific)."
