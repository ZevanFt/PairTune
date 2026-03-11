#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "[prod] running migrations (with backup)..."
npm -C "$ROOT_DIR" run migrate

echo "[prod] building admin..."
npm -C "$ROOT_DIR" run build:admin

echo "[prod] starting backend..."
npm -C "$ROOT_DIR" run start:backend
