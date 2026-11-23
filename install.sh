#!/bin/sh
set -eu

HARNESS_REPO="${HARNESS_REPO:-hunguet123/Harness}"
HARNESS_REF="${HARNESS_REF:-main}"
HARNESS_GIT_URL="${HARNESS_GIT_URL:-}"

DOC_FILES="
HARNESS.md
README.md
sources.md
templates/change-brief.md
templates/design-note.md
templates/failure-memory.md
mcp/catalog.md
mcp/mcp.example.json
backend/GATES.md
database/GATES.md
frontend/GATES.md
mobile/GATES.md
network/GATES.md
system-design/GATES.md
"

RULE_FILES="
harness-core.mdc
harness-backend.mdc
harness-database.mdc
harness-frontend.mdc
harness-mobile.mdc
harness-network.mdc
harness-system-design.mdc
harness-mcp.mdc
"

SKILLS="
run-harness
review-harness
harness-backend
harness-database
harness-frontend
harness-mobile
harness-network
harness-system-design
harness-mcp
"

usage() {
  cat <<'EOF'
Cách dùng:
  install.sh [tùy chọn] [thư_mục_dự_án]

Mặc định cài hoặc cập nhật bộ Harness vào [thư_mục_dự_án] (mặc định: thư mục hiện tại).
Dùng được cho cả dự án mới (tự tạo thư mục nếu chưa có) và dự án đã có sẵn
(giữ nguyên README, code, .cursor/mcp.json và các rule/skill riêng của dự án).

Tùy chọn:
  --local      Ghi thêm đường dẫn harness vào .git/info/exclude để dùng cá nhân,
               không làm bẩn git status của dự án chung
  --check      Kiểm tra tính toàn vẹn của bộ Harness (tại dự án đích hoặc repo nguồn)
  --uninstall  Gỡ các file của Harness khỏi dự án đích
  -h, --help   Hiện hướng dẫn này

Biến môi trường (khi chạy qua curl):
  HARNESS_REPO     Mặc định: hunguet123/Harness
  HARNESS_REF      Nhánh/tag cần tải (mặc định: main)
  HARNESS_GIT_URL  Nếu đặt (ví dụ git@github.com:hunguet123/Harness.git), tải bằng git clone
EOF
}

is_source_repo() {
  dir="$1"
  [ -f "$dir/HARNESS.md" ] &&
    [ -f "$dir/backend/GATES.md" ] &&
    [ -f "$dir/.cursor/rules/harness-core.mdc" ] &&
    [ ! -d "$dir/harness/backend" ]
}

TMP_WORK=""
cleanup() {
  if [ -n "$TMP_WORK" ] && [ -d "$TMP_WORK" ]; then
    rm -rf "$TMP_WORK"
  fi
}
trap cleanup EXIT INT TERM

resolve_source_dir() {
  script_path="${0:-}"
  if [ -n "$script_path" ] && [ -f "$script_path" ]; then
    script_dir=$(CDPATH= cd -- "$(dirname -- "$script_path")" && pwd)
    if is_source_repo "$script_dir"; then
      printf '%s\n' "$script_dir"
      return 0
    fi
  fi

  TMP_WORK=$(mktemp -d)
  if [ -n "$HARNESS_GIT_URL" ]; then
    git clone --quiet --depth 1 --branch "$HARNESS_REF" "$HARNESS_GIT_URL" "$TMP_WORK/src"
    printf '%s\n' "$TMP_WORK/src"
    return 0
  fi

  archive_url="https://codeload.github.com/${HARNESS_REPO}/tar.gz/${HARNESS_REF}"
  curl --connect-timeout 10 --max-time 30 -fsSL "$archive_url" | tar -xz -C "$TMP_WORK"
  extracted=$(find "$TMP_WORK" -mindepth 1 -maxdepth 1 -type d | head -n 1)
  if [ -z "$extracted" ] || ! is_source_repo "$extracted"; then
    echo "Lỗi: không tải được nguồn Harness hợp lệ từ ${archive_url}." >&2
    exit 1
  fi
  printf '%s\n' "$extracted"
}

remove_exclude_block() {
  exclude_file="$1"
  [ -f "$exclude_file" ] || return 0
  tmp_ex=$(mktemp)
  awk '
    /^# >>> harness-local >>>$/ { skip=1; next }
    /^# <<< harness-local <<<$/ { skip=0; next }
    !skip { print }
  ' "$exclude_file" >"$tmp_ex"
  cat "$tmp_ex" >"$exclude_file"
  rm -f "$tmp_ex"
}

write_exclude_block() {
  target_abs="$1"
  created_mcp="$2"
  if ! git -C "$target_abs" rev-parse --git-dir >/dev/null 2>&1; then
    echo "Lưu ý: thư mục đích chưa có git repo nên bỏ qua bước ghi .git/info/exclude." >&2
    return 0
  fi

  git_dir=$(git -C "$target_abs" rev-parse --path-format=absolute --git-dir 2>/dev/null || (cd "$target_abs" && cd "$(git rev-parse --git-dir)" && pwd))
  top_dir=$(git -C "$target_abs" rev-parse --show-toplevel)
  rel_prefix=""
  if [ "$target_abs" != "$top_dir" ]; then
    rel_prefix="${target_abs#"$top_dir"/}/"
  fi

  mkdir -p "$git_dir/info"
  exclude_file="$git_dir/info/exclude"
  touch "$exclude_file"
  remove_exclude_block "$exclude_file"

  {
    echo "# >>> harness-local >>>"
    echo "/${rel_prefix}harness/"
    echo "/${rel_prefix}.cursor/rules/harness-*.mdc"
    echo "/${rel_prefix}.cursor/skills/run-harness/"
    echo "/${rel_prefix}.cursor/skills/review-harness/"
    echo "/${rel_prefix}.cursor/skills/harness-*/"
    if [ "$created_mcp" = "1" ]; then
      echo "/${rel_prefix}.cursor/mcp.json"
    fi
    echo "# <<< harness-local <<<"
  } >>"$exclude_file"
  echo "Đã ghi danh sách loại trừ cá nhân vào $exclude_file."
}

check_markdown_links() {
  base_dir="$1"
  shift
  for md_file in "$@"; do
    [ -f "$md_file" ] || continue
    md_dir=$(CDPATH= cd -- "$(dirname -- "$md_file")" && pwd)
    targets=$(grep -oE '\[[^]]+\]\([^)]+\)' "$md_file" 2>/dev/null | sed 's/.*]( *//; s/[)# ].*//' || true)
    for t in $targets; do
      case "$t" in
        http://*|https://*|mailto:*|"") continue ;;
      esac
      if [ ! -e "$md_dir/$t" ]; then
        echo "Lỗi link gãy trong ${md_file#"$base_dir"/}: $t" >&2
        return 1
      fi
    done
  done
  return 0
}

run_check() {
  target_dir="$1"
  if [ ! -d "$target_dir" ]; then
    echo "Lỗi: không tìm thấy thư mục '$target_dir'." >&2
    exit 1
  fi
  target_abs=$(CDPATH= cd -- "$target_dir" && pwd)

  if is_source_repo "$target_abs"; then
    docs_root="$target_abs"
    mode_label="repo nguồn"
  else
    docs_root="$target_abs/harness"
    mode_label="dự án đích"
  fi

  errors=0
  for rel in $DOC_FILES; do
    if [ ! -s "$docs_root/$rel" ]; then
      echo "Thiếu hoặc rỗng: ${docs_root#"$target_abs"/}/$rel" >&2
      errors=$((errors + 1))
    fi
  done

  for r in $RULE_FILES; do
    rf="$target_abs/.cursor/rules/$r"
    if [ ! -s "$rf" ]; then
      echo "Thiếu rule: .cursor/rules/$r" >&2
      errors=$((errors + 1))
    else
      grep -q '^description:' "$rf" || { echo "Rule thiếu description: $r" >&2; errors=$((errors + 1)); }
      grep -q '^alwaysApply: false' "$rf" || { echo "Rule thiếu alwaysApply: false: $r" >&2; errors=$((errors + 1)); }
    fi
  done

  for s in $SKILLS; do
    sf="$target_abs/.cursor/skills/$s/SKILL.md"
    if [ ! -s "$sf" ]; then
      echo "Thiếu skill: .cursor/skills/$s/SKILL.md" >&2
      errors=$((errors + 1))
    else
      grep -q "^name: $s$" "$sf" || { echo "Skill sai name frontmatter: $s" >&2; errors=$((errors + 1)); }
      grep -q '^description:' "$sf" || { echo "Skill thiếu description: $s" >&2; errors=$((errors + 1)); }
    fi
  done

  mcp_file="$target_abs/.cursor/mcp.json"
  if [ ! -s "$mcp_file" ]; then
    echo "Thiếu .cursor/mcp.json" >&2
    errors=$((errors + 1))
  elif command -v python3 >/dev/null 2>&1; then
    if ! python3 - "$mcp_file" "$mode_label" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
if not isinstance(data, dict) or "mcpServers" not in data:
    sys.exit(1)
if sys.argv[2] == "repo nguồn" and data != {"mcpServers": {}}:
    print("Repo nguồn phải để .cursor/mcp.json rỗng.", file=sys.stderr)
    sys.exit(2)
PY
    then
      echo ".cursor/mcp.json không hợp lệ." >&2
      errors=$((errors + 1))
    fi
  fi

  set --
  for rel in $DOC_FILES; do
    case "$rel" in
      *.md) set -- "$@" "$docs_root/$rel" ;;
    esac
  done
  for r in $RULE_FILES; do
    set -- "$@" "$target_abs/.cursor/rules/$r"
  done
  for s in $SKILLS; do
    set -- "$@" "$target_abs/.cursor/skills/$s/SKILL.md"
  done
  if ! check_markdown_links "$target_abs" "$@"; then
    errors=$((errors + 1))
  fi

  if [ "$errors" -gt 0 ]; then
    echo "Kiểm tra thất bại ($errors lỗi)." >&2
    exit 1
  fi
  echo "OK: Bộ Harness tại '$target_abs' ($mode_label) đầy đủ và hợp lệ."
}

run_uninstall() {
  target_dir="$1"
  if [ ! -d "$target_dir" ]; then
    echo "Lỗi: không tìm thấy thư mục '$target_dir'." >&2
    exit 1
  fi
  target_abs=$(CDPATH= cd -- "$target_dir" && pwd)
  if is_source_repo "$target_abs"; then
    echo "Lỗi: '$target_abs' là repo nguồn Harness, không chạy --uninstall tại đây." >&2
    exit 1
  fi

  for rel in $DOC_FILES; do
    rm -f "$target_abs/harness/$rel"
  done
  for sub in templates mcp backend database frontend mobile network system-design; do
    rmdir "$target_abs/harness/$sub" 2>/dev/null || true
  done
  rmdir "$target_abs/harness" 2>/dev/null || true
  if [ -d "$target_abs/harness" ]; then
    echo "Lưu ý: giữ lại '$target_abs/harness' vì có file riêng do người dùng tạo." >&2
  fi

  for r in $RULE_FILES; do
    rm -f "$target_abs/.cursor/rules/$r"
  done
  rmdir "$target_abs/.cursor/rules" 2>/dev/null || true

  for s in $SKILLS; do
    rm -f "$target_abs/.cursor/skills/$s/SKILL.md"
    rmdir "$target_abs/.cursor/skills/$s" 2>/dev/null || true
  done
  rmdir "$target_abs/.cursor/skills" 2>/dev/null || true

  if [ -f "$target_abs/.cursor/mcp.json" ]; then
    compact=$(tr -d ' \t\r\n' <"$target_abs/.cursor/mcp.json")
    tracked=0
    if git -C "$target_abs" ls-files --error-unmatch ".cursor/mcp.json" >/dev/null 2>&1; then
      tracked=1
    fi
    if [ "$compact" = '{"mcpServers":{}}' ] && [ "$tracked" = "0" ]; then
      rm -f "$target_abs/.cursor/mcp.json"
    fi
  fi
  rmdir "$target_abs/.cursor" 2>/dev/null || true

  if git -C "$target_abs" rev-parse --git-dir >/dev/null 2>&1; then
    git_dir=$(git -C "$target_abs" rev-parse --path-format=absolute --git-dir 2>/dev/null || (cd "$target_abs" && cd "$(git rev-parse --git-dir)" && pwd))
    if [ -f "$git_dir/info/exclude" ]; then
      remove_exclude_block "$git_dir/info/exclude"
    fi
  fi

  echo "Đã gỡ bộ Harness khỏi '$target_abs' (giữ nguyên mọi file riêng của dự án)."
}

MODE="install"
LOCAL_EXCLUDE=0
TARGET_DIR="."

while [ "$#" -gt 0 ]; do
  case "$1" in
    --local)
      LOCAL_EXCLUDE=1
      shift
      ;;
    --check)
      MODE="check"
      shift
      ;;
    --uninstall)
      MODE="uninstall"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Tùy chọn không hợp lệ: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      TARGET_DIR="$1"
      shift
      ;;
  esac
done

case "$MODE" in
  check)
    run_check "$TARGET_DIR"
    exit 0
    ;;
  uninstall)
    run_uninstall "$TARGET_DIR"
    exit 0
    ;;
esac

SRC_DIR=$(resolve_source_dir)
mkdir -p "$TARGET_DIR"
TARGET_ABS=$(CDPATH= cd -- "$TARGET_DIR" && pwd)

if [ "$SRC_DIR" = "$TARGET_ABS" ] || is_source_repo "$TARGET_ABS"; then
  echo "Lỗi: thư mục đích '$TARGET_ABS' chính là repo nguồn Harness." >&2
  echo "Hãy truyền đường dẫn dự án mới hoặc dự án đã có: ./install.sh /duong/dan/project" >&2
  exit 1
fi

for rel in $DOC_FILES; do
  dest="$TARGET_ABS/harness/$rel"
  mkdir -p "$(dirname -- "$dest")"
  if [ "$rel" = "README.md" ]; then
    sed 's|](\.cursor/|](../.cursor/|g' "$SRC_DIR/README.md" >"$dest"
  else
    cp "$SRC_DIR/$rel" "$dest"
  fi
done

mkdir -p "$TARGET_ABS/.cursor/rules"
for r in $RULE_FILES; do
  cp "$SRC_DIR/.cursor/rules/$r" "$TARGET_ABS/.cursor/rules/$r"
done

for s in $SKILLS; do
  mkdir -p "$TARGET_ABS/.cursor/skills/$s"
  sed 's|](\.\./\.\./\.\./|](../../../harness/|g' \
    "$SRC_DIR/.cursor/skills/$s/SKILL.md" >"$TARGET_ABS/.cursor/skills/$s/SKILL.md"
done

CREATED_MCP=0
if [ ! -e "$TARGET_ABS/.cursor/mcp.json" ]; then
  cat >"$TARGET_ABS/.cursor/mcp.json" <<'EOF'
{
  "mcpServers": {}
}
EOF
  CREATED_MCP=1
else
  echo "Giữ nguyên .cursor/mcp.json hiện có của dự án."
fi

if [ "$LOCAL_EXCLUDE" = "1" ]; then
  write_exclude_block "$TARGET_ABS" "$CREATED_MCP"
fi

echo "Đã cài đặt Harness vào '$TARGET_ABS':"
echo "  - Tài liệu & cổng G0–G3: $TARGET_ABS/harness/"
echo "  - Cursor rules (8):      $TARGET_ABS/.cursor/rules/harness-*.mdc"
echo "  - Cursor skills (9):     $TARGET_ABS/.cursor/skills/"
echo "Bắt đầu task mới bằng cách copy harness/templates/change-brief.md sang thư mục tài liệu của dự án."
