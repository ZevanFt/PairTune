#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env.local"

print_usage() {
  cat <<'USAGE'
Usage:
  ./backend/scripts/deploy.sh [--pm2]

Behavior:
  1) Prompt for admin account/password/display name
  2) Write backend/.env.local
  3) Start backend (node) or pm2 (if --pm2)
USAGE
}

if [[ "${1:-}" == "--help" ]]; then
  print_usage
  exit 0
fi

read_account() {
  local input
  while true; do
    read -r -p "管理员账号(4-20位字母/数字/下划线): " input
    input="$(echo "$input" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
    if [[ "$input" =~ ^[a-z0-9_]{4,20}$ ]]; then
      echo "$input"
      return 0
    fi
    echo "账号格式非法，请重试。"
  done
}

read_password() {
  local input
  while true; do
    read -r -s -p "管理员密码(至少6位): " input
    echo ""
    if [[ "${#input}" -ge 6 ]]; then
      echo "$input"
      return 0
    fi
    echo "密码太短，请重试。"
  done
}

read_display_name() {
  local input
  read -r -p "管理员昵称(默认: 管理员): " input
  input="$(echo "$input" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  if [[ -z "$input" ]]; then
    echo "管理员"
  else
    echo "$input"
  fi
}

ACCOUNT="$(read_account)"
PASSWORD="$(read_password)"
DISPLAY_NAME="$(read_display_name)"

cat > "$ENV_FILE" <<EOF
ADMIN_ACCOUNT=${ACCOUNT}
ADMIN_PASSWORD=${PASSWORD}
ADMIN_DISPLAY_NAME=${DISPLAY_NAME}
EOF

chmod 600 "$ENV_FILE"
echo "已写入 ${ENV_FILE}"

if [[ "${1:-}" == "--pm2" ]]; then
  if ! command -v pm2 >/dev/null 2>&1; then
    echo "未找到 pm2，请先安装：npm i -g pm2"
    exit 1
  fi
  pm2 start "${ROOT_DIR}/src/main.js" --name priority_first_backend --update-env
  pm2 save
  pm2 status priority_first_backend
  exit 0
fi

node "${ROOT_DIR}/src/main.js"
