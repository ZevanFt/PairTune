#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-}"
DB_PATH="${DB_PATH:-/home/talent/projects/priority_first/backend/data/priority_first.db}"

if [[ -z "$TARGET" ]]; then
  echo "usage: rollback.sh <bundle_dir_or_latest_link>" >&2
  exit 1
fi

if [[ ! -d "$TARGET" ]]; then
  echo "bundle dir not found: $TARGET" >&2
  exit 1
fi

if [[ ! -f "$TARGET/snapshot.sql" ]]; then
  echo "snapshot.sql not found in bundle: $TARGET" >&2
  exit 1
fi

if [[ -f "$TARGET/MANIFEST.json" ]]; then
  if command -v sha256sum >/dev/null 2>&1; then
    while IFS= read -r -d '' file; do
      rel="${file#$TARGET/}"
      (cd "$TARGET" && sha256sum -c "$rel") || {
        echo "checksum verify failed: $rel" >&2
        exit 1
      }
    done < <(find "$TARGET" -name "*.sha256" -print0)
  else
    echo "sha256sum not found; skip checksum verification" >&2
  fi
fi

if [[ -f "$DB_PATH" ]]; then
  cp "$DB_PATH" "${DB_PATH}.rollback.bak"
fi

sqlite3 "$DB_PATH" < "$TARGET/snapshot.sql"
echo "rollback done: $DB_PATH"

if [[ -f "$TARGET/MANIFEST.json" ]]; then
  sqlite3 "$DB_PATH" "CREATE TABLE IF NOT EXISTS schema_migrations (id TEXT PRIMARY KEY, checksum TEXT NOT NULL, applied_at TEXT NOT NULL);"
fi

EVENTS_PATH="$TARGET/events.jsonl"

log_event() {
  echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"type\":\"$1\",\"detail\":\"$2\"}" >> "$EVENTS_PATH"
}

log_event "rollback_start" "$TARGET"

if [[ "${ROLLBACK_RUN_MIGRATE:-0}" == "1" ]]; then
  npm -C "$(dirname "$0")/.." run migrate
  log_event "rollback_migrate_done" "$TARGET"
fi

if [[ "${ROLLBACK_RUN_REPORT:-0}" == "1" ]]; then
  npm -C "$(dirname "$0")/.." run report -- --dir "$TARGET"
  log_event "rollback_report_done" "$TARGET"
fi

if [[ "${ROLLBACK_UPLOAD_REPORT:-0}" == "1" ]]; then
  DEST="${ROLLBACK_UPLOAD_TARGET:-}"
  if [[ -n "$DEST" ]]; then
    npm -C "$(dirname "$0")/.." run upload -- --src "$TARGET/REPORT.json" --dest "$DEST/REPORT.json"
    npm -C "$(dirname "$0")/.." run upload -- --src "$TARGET/SUMMARY.txt" --dest "$DEST/SUMMARY.txt"
    log_event "rollback_upload_done" "$DEST"
  fi
fi

if [[ "${ROLLBACK_NOTIFY:-0}" == "1" ]]; then
  npm -C "$(dirname "$0")/.." run notify -- --message=rollback_done --dir "$TARGET"
  log_event "rollback_notify_done" "$TARGET"
fi
