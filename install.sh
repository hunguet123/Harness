#!/bin/sh
set -eu

HARNESS_REPO="${HARNESS_REPO:-hunguet123/Harness}"
HARNESS_REF="${HARNESS_REF:-main}"
HARNESS_GIT_URL="${HARNESS_GIT_URL:-}"

DOC_FILES="
HARNESS.md
README.md
sources.md
templates/project-profile.md
templates/change-brief.md
templates/design-note.md
templates/failure-memory.md
examples/order-create/change-brief.md
examples/order-create/design-note.md
examples/order-create/failure-memory.md
hooks/hooks.example.json
hooks/harness-guard.sh
mcp/catalog.md
mcp/mcp.example.json
backend/GATES.md
database/GATES.md
frontend/GATES.md
mobile/GATES.md
network/GATES.md
system-design/GATES.md
languages/README.md
languages/typescript.md
languages/go.md
languages/python.md
languages/jvm.md
languages/rust.md
languages/csharp.md
languages/mobile-swift-dart.md
languages/sql-idl.md
"

CORE_RULE_FILES="
harness-core.mdc
harness-backend.mdc
harness-database.mdc
harness-frontend.mdc
harness-mobile.mdc
harness-network.mdc
harness-system-design.mdc
harness-mcp.mdc
"

ALL_LANG_RULE_FILES="
harness-lang-ts.mdc
harness-lang-go.mdc
harness-lang-python.mdc
harness-lang-jvm.mdc
harness-lang-rust.mdc
harness-lang-csharp.mdc
harness-lang-mobile.mdc
harness-lang-sql-idl.mdc
"

SKILLS="
onboard-project
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

LEGACY_DOC_FILES="
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

LEGACY_SKILLS="
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
- Dự án đã có: tự dò ngôn ngữ & lệnh chạy sơ bộ vào harness/PROJECT.md, nạp rule ngôn ngữ,
  hook bảo vệ và AGENTS.md mà không ghi đè README, code, hay cấu hình riêng của dự án.
- Dự án mới (thư mục trống): tự tạo thư mục nếu chưa có; có thể chọn trước ngôn ngữ
  bằng --lang hoặc để mặc định nạp trọn bộ rule theo đuôi file.

Tùy chọn:
  --lang DANH_SÁCH  Chọn ngôn ngữ phân tách bằng dấu phẩy:
                    ts, go, python, jvm, rust, csharp, mobile, sql, hoặc all
                    (ví dụ: --lang ts,go,sql)
  --claude          Cài thêm shim CLAUDE.md và .claude/skills/ cho Claude Code
  --cursor-only     Chỉ cài vào .cursor/ và harness/, không tạo/cập nhật AGENTS.md
  --adopt-legacy    Xác nhận nhận ownership các artifact của bản Harness cũ
                    chưa có manifest (chỉ dùng khi installer yêu cầu)
  --local           Ghi đường dẫn harness vào .git/info/exclude để dùng cá nhân,
                    không làm bẩn git status của dự án chung
  --check           Kiểm tra tính toàn vẹn của bộ Harness (tại dự án đích hoặc repo nguồn)
  --uninstall       Gỡ các file của Harness khỏi dự án đích
  -h, --help        Hiện hướng dẫn này

Biến môi trường (khi chạy qua curl):
  HARNESS_REPO      Mặc định: hunguet123/Harness
  HARNESS_REF       Nhánh/tag cần tải (mặc định: main)
  HARNESS_GIT_URL   Nếu đặt (ví dụ git@github.com:hunguet123/Harness.git), tải bằng git clone
EOF
}

is_source_repo() {
  dir="$1"
  [ -f "$dir/HARNESS.md" ] &&
    [ -f "$dir/backend/GATES.md" ] &&
    [ -f "$dir/languages/README.md" ] &&
    [ -f "$dir/.cursor/rules/harness-core.mdc" ] &&
    [ ! -d "$dir/harness/backend" ]
}

TMP_WORK=""
ADOPTED_LEGACY_MANIFEST=""
cleanup() {
  if [ -n "$ADOPTED_LEGACY_MANIFEST" ] && [ -f "$ADOPTED_LEGACY_MANIFEST" ]; then
    rm -f "$ADOPTED_LEGACY_MANIFEST"
  fi
  if [ -n "$TMP_WORK" ] && [ -d "$TMP_WORK" ]; then
    rm -rf "$TMP_WORK"
  fi
}
trap cleanup EXIT INT TERM

resolve_source_dir() {
  script_path="${0:-}"
  if [ -n "$script_path" ] && [ -f "$script_path" ]; then
    script_dir=$(CDPATH= cd -- "$(dirname -- "$script_path")" && pwd -P)
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
  extracted=""
  for candidate in "$TMP_WORK"/*; do
    if [ -d "$candidate" ]; then
      extracted="$candidate"
      break
    fi
  done
  if [ -z "$extracted" ] || ! is_source_repo "$extracted"; then
    echo "Lỗi: không tải được nguồn Harness hợp lệ từ ${archive_url}." >&2
    exit 1
  fi
  printf '%s\n' "$extracted"
}

add_unique_word() {
  list="$1"
  word="$2"
  case " $list " in
    *" $word "*) printf '%s' "$list" ;;
    *)
      if [ -z "$list" ]; then
        printf '%s' "$word"
      else
        printf '%s %s' "$list" "$word"
      fi
      ;;
  esac
}

parse_lang_spec() {
  spec="$1"
  selected=""
  old_ifs="$IFS"
  IFS=','
  for raw in $spec; do
    IFS="$old_ifs"
    token=$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
    [ -n "$token" ] || continue
    case "$token" in
      all)
        printf '%s\n' "$ALL_LANG_RULE_FILES"
        return 0
        ;;
      ts|typescript|js|javascript|node|react|vue|next|rn)
        selected=$(add_unique_word "$selected" "harness-lang-ts.mdc")
        ;;
      go|golang)
        selected=$(add_unique_word "$selected" "harness-lang-go.mdc")
        ;;
      py|python)
        selected=$(add_unique_word "$selected" "harness-lang-python.mdc")
        ;;
      jvm|java|kotlin|kt|android|kmp)
        selected=$(add_unique_word "$selected" "harness-lang-jvm.mdc")
        ;;
      rust|rs)
        selected=$(add_unique_word "$selected" "harness-lang-rust.mdc")
        ;;
      csharp|cs|dotnet|net)
        selected=$(add_unique_word "$selected" "harness-lang-csharp.mdc")
        ;;
      mobile|swift|ios|dart|flutter)
        selected=$(add_unique_word "$selected" "harness-lang-mobile.mdc")
        ;;
      sql|sql-idl|db|idl|postgres|mysql|sqlite|redis|grpc|openapi|graphql)
        selected=$(add_unique_word "$selected" "harness-lang-sql-idl.mdc")
        ;;
      *)
        echo "Lỗi: mã ngôn ngữ không hợp lệ '$token'. Hỗ trợ: ts, go, python, jvm, rust, csharp, mobile, sql, all." >&2
        exit 1
        ;;
    esac
  done
  IFS="$old_ifs"

  if [ -z "$selected" ]; then
    echo "Lỗi: --lang không được để trống." >&2
    exit 1
  fi
  printf '%s\n' "$selected"
}

detect_project_lang_rules() {
  dir="$1"
  detected=""

  scan_list=$(find "$dir" \
    \( -name .git -o -name .cursor -o -name .claude -o -name harness -o -name node_modules -o -name vendor -o -name target -o -name dist -o -name build -o -name .venv -o -name venv -o -name Pods -o -name .gradle -o -name .next \) -prune \
    -o -print 2>/dev/null || true)

  if printf '%s\n' "$scan_list" | grep -qE '/(package\.json|tsconfig.*\.json|deno\.jsonc?|.*\.(ts|tsx|mts|cts|js|jsx))$'; then
    detected=$(add_unique_word "$detected" "harness-lang-ts.mdc")
  fi
  if printf '%s\n' "$scan_list" | grep -qE '/(go\.mod|.*\.go)$'; then
    detected=$(add_unique_word "$detected" "harness-lang-go.mdc")
  fi
  if printf '%s\n' "$scan_list" | grep -qE '/(pyproject\.toml|requirements.*\.txt|Pipfile|manage\.py|.*\.py)$'; then
    detected=$(add_unique_word "$detected" "harness-lang-python.mdc")
  fi
  if printf '%s\n' "$scan_list" | grep -qE '/(pom\.xml|build\.gradle(\.kts)?|.*\.(java|kt))$'; then
    detected=$(add_unique_word "$detected" "harness-lang-jvm.mdc")
  fi
  if printf '%s\n' "$scan_list" | grep -qE '/(Cargo\.toml|.*\.rs)$'; then
    detected=$(add_unique_word "$detected" "harness-lang-rust.mdc")
  fi
  if printf '%s\n' "$scan_list" | grep -qE '/(.*\.(csproj|sln|cs))$'; then
    detected=$(add_unique_word "$detected" "harness-lang-csharp.mdc")
  fi
  if printf '%s\n' "$scan_list" | grep -qE '/(Package\.swift|pubspec\.yaml|.*\.xcodeproj|.*\.(swift|dart))$'; then
    detected=$(add_unique_word "$detected" "harness-lang-mobile.mdc")
  fi
  if printf '%s\n' "$scan_list" | grep -qE '/(schema\.prisma|openapi.*\.(ya?ml|json)|.*\.(sql|proto|graphql|gql))$'; then
    detected=$(add_unique_word "$detected" "harness-lang-sql-idl.mdc")
  fi

  printf '%s\n' "$detected"
}

format_lang_summary() {
  rules_list="$1"
  names=""
  for rf in $rules_list; do
    short="${rf#harness-lang-}"
    short="${short%.mdc}"
    names=$(add_unique_word "$names" "$short")
  done
  printf '%s' "$names" | tr ' ' ','
}

is_git_tracked() {
  repo_dir="$1"
  rel_path="$2"
  git -C "$repo_dir" ls-files --error-unmatch "$rel_path" >/dev/null 2>&1
}

installed_lang_rules_at() {
  target_abs="$1"
  installed=""
  for lr in $ALL_LANG_RULE_FILES; do
    if [ -f "$target_abs/.cursor/rules/$lr" ]; then
      installed=$(add_unique_word "$installed" "$lr")
    fi
  done
  printf '%s\n' "$installed"
}

validate_managed_path() {
  target_abs="$1"
  rel_path="$2"
  parent_rel=$(dirname -- "$rel_path")
  current="$target_abs"
  old_ifs="$IFS"
  IFS='/'
  for component in $parent_rel; do
    IFS="$old_ifs"
    [ "$component" = "." ] && continue
    current="$current/$component"
    if [ -L "$current" ]; then
      echo "Lỗi: từ chối đi qua thư mục symlink: ${current#"$target_abs"/}" >&2
      return 1
    fi
    if [ -e "$current" ] && [ ! -d "$current" ]; then
      echo "Lỗi: thành phần đường dẫn không phải thư mục: ${current#"$target_abs"/}" >&2
      return 1
    fi
  done
  IFS="$old_ifs"

  final="$target_abs/$rel_path"
  if [ -L "$final" ]; then
    echo "Lỗi: từ chối artifact symlink: $rel_path" >&2
    return 1
  fi
  if [ -e "$final" ] && [ ! -f "$final" ]; then
    echo "Lỗi: artifact Harness không phải file thường: $rel_path" >&2
    return 1
  fi
}

preflight_special_surfaces() {
  target_abs="$1"
  for rel in \
    ".cursor/harness-install-manifest" \
    ".cursor/hooks.json" \
    ".cursor/mcp.json" \
    "harness/PROJECT.md"; do
    validate_managed_path "$target_abs" "$rel" || exit 1
    path="$target_abs/$rel"
    if [ -e "$path" ] && [ ! -f "$path" ]; then
      echo "Lỗi: bề mặt Harness không phải file thường: $rel" >&2
      exit 1
    fi
  done
}

manifest_has() {
  target_abs="$1"
  entry="$2"
  manifest="$target_abs/.cursor/harness-install-manifest"
  [ -f "$manifest" ] && grep -Fqx "$entry" "$manifest"
}

manifest_add() {
  target_abs="$1"
  entry="$2"
  manifest="$target_abs/.cursor/harness-install-manifest"
  validate_managed_path "$target_abs" ".cursor/harness-install-manifest" || exit 1
  mkdir -p "$target_abs/.cursor"
  touch "$manifest"
  if ! grep -Fqx "$entry" "$manifest"; then
    printf '%s\n' "$entry" >>"$manifest"
  fi
}

manifest_remove() {
  target_abs="$1"
  entry="$2"
  manifest="$target_abs/.cursor/harness-install-manifest"
  [ -f "$manifest" ] || return 0
  tmp_manifest=$(mktemp)
  grep -Fvx "$entry" "$manifest" >"$tmp_manifest" || true
  cat "$tmp_manifest" >"$manifest"
  rm -f "$tmp_manifest"
}

adopt_legacy_install_if_present() {
  target_abs="$1"
  allow_adopt="$2"
  manifest="$target_abs/.cursor/harness-install-manifest"
  [ ! -e "$manifest" ] || return 0

  if [ -f "$target_abs/harness/HARNESS.md" ] &&
    [ -f "$target_abs/.cursor/rules/harness-core.mdc" ] &&
    [ -f "$target_abs/.cursor/skills/run-harness/SKILL.md" ]; then
    if [ "$allow_adopt" != "1" ]; then
      echo "Lỗi: phát hiện bản Harness cũ chưa có ownership manifest. Kiểm tra các file tùy biến rồi chạy lại với --adopt-legacy để nâng cấp." >&2
      exit 1
    fi
    echo "Phát hiện bản Harness cũ chưa có ownership manifest; đang nhận quyền sở hữu các artifact Harness dành riêng để nâng cấp an toàn."
    ADOPTED_LEGACY_MANIFEST="$manifest"
    for rel in $LEGACY_DOC_FILES; do
      [ -f "$target_abs/harness/$rel" ] && manifest_add "$target_abs" "doc:$rel"
    done
    for rule in $CORE_RULE_FILES; do
      [ -f "$target_abs/.cursor/rules/$rule" ] && manifest_add "$target_abs" "cursor-rule:$rule"
    done
    for skill in $LEGACY_SKILLS; do
      [ -f "$target_abs/.cursor/skills/$skill/SKILL.md" ] && manifest_add "$target_abs" "cursor-skill:$skill"
    done
    if [ -f "$target_abs/.cursor/mcp.json" ] &&
      [ "$(tr -d '[:space:]' <"$target_abs/.cursor/mcp.json")" = '{"mcpServers":{}}' ] &&
      ! is_git_tracked "$target_abs" ".cursor/mcp.json"; then
      manifest_add "$target_abs" "mcp-config-created"
    fi
  fi
}

install_managed_file() {
  target_abs="$1"
  source_file="$2"
  rel_path="$3"
  entry="$4"
  local_mode="$5"
  dest="$target_abs/$rel_path"

  validate_managed_path "$target_abs" "$rel_path" || exit 1
  if [ -e "$dest" ] && ! manifest_has "$target_abs" "$entry"; then
    echo "Lỗi: $rel_path đã tồn tại nhưng không thuộc Harness; giữ nguyên file và dừng để tránh ghi đè." >&2
    exit 1
  fi

  if [ "$local_mode" = "1" ] && [ -e "$dest" ] && is_git_tracked "$target_abs" "$rel_path"; then
    echo "Chế độ --local: giữ nguyên $rel_path đang được git theo dõi."
    return 0
  fi

  mkdir -p "$(dirname -- "$dest")"
  cp "$source_file" "$dest"
  manifest_add "$target_abs" "$entry"
}

install_managed_skill() {
  target_abs="$1"
  src_dir="$2"
  skill="$3"
  local_mode="$4"
  tmp_skill=$(mktemp)
  sed 's|](\.\./\.\./\.\./|](../../../harness/|g' \
    "$src_dir/.cursor/skills/$skill/SKILL.md" >"$tmp_skill"
  install_managed_file "$target_abs" "$tmp_skill" ".cursor/skills/$skill/SKILL.md" "cursor-skill:$skill" "$local_mode"
  rm -f "$tmp_skill"
}

preflight_managed_file() {
  target_abs="$1"
  source_file="$2"
  rel_path="$3"
  entry="$4"
  dest="$target_abs/$rel_path"
  validate_managed_path "$target_abs" "$rel_path" || exit 1
  if [ -e "$dest" ] && ! manifest_has "$target_abs" "$entry"; then
    echo "Lỗi: $rel_path đã tồn tại nhưng không thuộc Harness; chưa có file nào được cài." >&2
    exit 1
  fi
}

preflight_install_artifacts() {
  target_abs="$1"
  src_dir="$2"
  selected_lang_rules="$3"

  for rel in $DOC_FILES; do
    if [ "$rel" = "README.md" ]; then
      tmp_doc=$(mktemp)
      sed 's|](\.cursor/|](../.cursor/|g' "$src_dir/README.md" >"$tmp_doc"
      preflight_managed_file "$target_abs" "$tmp_doc" "harness/$rel" "doc:$rel"
      rm -f "$tmp_doc"
    else
      preflight_managed_file "$target_abs" "$src_dir/$rel" "harness/$rel" "doc:$rel"
    fi
  done

  for rule in $CORE_RULE_FILES $selected_lang_rules; do
    preflight_managed_file "$target_abs" "$src_dir/.cursor/rules/$rule" ".cursor/rules/$rule" "cursor-rule:$rule"
  done

  for skill in $SKILLS; do
    tmp_skill=$(mktemp)
    sed 's|](\.\./\.\./\.\./|](../../../harness/|g' \
      "$src_dir/.cursor/skills/$skill/SKILL.md" >"$tmp_skill"
    preflight_managed_file "$target_abs" "$tmp_skill" ".cursor/skills/$skill/SKILL.md" "cursor-skill:$skill"
    rm -f "$tmp_skill"
  done

  preflight_managed_file "$target_abs" "$src_dir/hooks/harness-guard.sh" \
    ".cursor/hooks/harness-guard.sh" "hook-script-created"
  if [ -e "$target_abs/.cursor/hooks/harness-guard.sh" ] &&
    ! manifest_has "$target_abs" "hook-script-created" &&
    [ ! -x "$target_abs/.cursor/hooks/harness-guard.sh" ]; then
    echo "Lỗi: .cursor/hooks/harness-guard.sh có nội dung trùng nhưng không executable và không thuộc Harness." >&2
    exit 1
  fi

  if [ -e "$target_abs/.cursor/hooks.json" ]; then
    require_python_for_json_merge
    python3 - "$target_abs/.cursor/hooks.json" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as fh:
    data = json.load(fh)
if not isinstance(data, dict) or not isinstance(data.get("hooks", {}), dict):
    raise SystemExit(".cursor/hooks.json phải là object có trường hooks dạng object")
for event in ("preToolUse", "beforeShellExecution"):
    if event in data["hooks"] and not isinstance(data["hooks"][event], list):
        raise SystemExit(f".cursor/hooks.json: hooks.{event} phải là array")
PY
  fi
}

require_python_for_json_merge() {
  if ! command -v python3 >/dev/null 2>&1; then
    echo "Lỗi: cần python3 để ghép an toàn vào .cursor/hooks.json hiện có; file được giữ nguyên." >&2
    exit 1
  fi
}

merge_harness_hooks() {
  target_abs="$1"
  example="$2"
  hooks_file="$target_abs/.cursor/hooks.json"

  if [ ! -e "$hooks_file" ]; then
    cp "$example" "$hooks_file"
    manifest_add "$target_abs" "hooks-config-created"
    manifest_add "$target_abs" "hooks-managed"
    manifest_add "$target_abs" "hooks-registration:preToolUse"
    manifest_add "$target_abs" "hooks-registration:beforeShellExecution"
    return 0
  fi

  if check_harness_hooks "$hooks_file"; then
    manifest_add "$target_abs" "hooks-managed"
    for event in preToolUse beforeShellExecution; do
      if ! manifest_has "$target_abs" "hooks-registration:$event"; then
        manifest_add "$target_abs" "hooks-registration-preserved:$event"
      fi
    done
    return 0
  fi

  require_python_for_json_merge
  missing_events=$(python3 - "$hooks_file" "$example" <<'PY'
import json, sys
path, example_path = sys.argv[1:3]
with open(path, encoding="utf-8") as fh:
    current = json.load(fh)
with open(example_path, encoding="utf-8") as fh:
    required = json.load(fh)
hooks = current.get("hooks", {})
for event, registrations in required["hooks"].items():
    existing = hooks.get(event, [])
    for registration in registrations:
        if not any(
            isinstance(item, dict)
            and item.get("command") == registration.get("command")
            and item.get("matcher") == registration.get("matcher")
            for item in existing
        ):
            print(event)
            break
PY
)
  python3 - "$hooks_file" "$example" <<'PY'
import json, os, sys, tempfile

path, example_path = sys.argv[1:3]
with open(path, encoding="utf-8") as fh:
    current = json.load(fh)
with open(example_path, encoding="utf-8") as fh:
    required = json.load(fh)
if not isinstance(current, dict) or not isinstance(current.get("hooks", {}), dict):
    raise SystemExit(".cursor/hooks.json phải là object có trường hooks dạng object")

current.setdefault("version", 1)
hooks = current.setdefault("hooks", {})
for event, registrations in required["hooks"].items():
    existing = hooks.setdefault(event, [])
    if not isinstance(existing, list):
        raise SystemExit(f".cursor/hooks.json: hooks.{event} phải là array")
    for registration in registrations:
        if not any(
            isinstance(item, dict)
            and item.get("command") == registration.get("command")
            and item.get("matcher") == registration.get("matcher")
            for item in existing
        ):
            existing.append(registration)

directory = os.path.dirname(path)
fd, tmp = tempfile.mkstemp(prefix=".hooks.", dir=directory, text=True)
try:
    with os.fdopen(fd, "w", encoding="utf-8") as fh:
        json.dump(current, fh, ensure_ascii=False, indent=2)
        fh.write("\n")
    os.replace(tmp, path)
finally:
    if os.path.exists(tmp):
        os.unlink(tmp)
PY
  manifest_add "$target_abs" "hooks-managed"
  for event in $missing_events; do
    manifest_add "$target_abs" "hooks-registration:$event"
  done
  for event in preToolUse beforeShellExecution; do
    case " $missing_events " in
      *" $event "*) ;;
      *)
        if ! manifest_has "$target_abs" "hooks-registration:$event"; then
          manifest_add "$target_abs" "hooks-registration-preserved:$event"
        fi
        ;;
    esac
  done
}

check_harness_hooks() {
  hooks_file="$1"
  [ -s "$hooks_file" ] || return 1
  command -v python3 >/dev/null 2>&1 || return 1
  python3 - "$hooks_file" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as fh:
    data = json.load(fh)
hooks = data.get("hooks", {}) if isinstance(data, dict) else {}
required = {
    "preToolUse": (".cursor/hooks/harness-guard.sh", "Write|StrReplace"),
    "beforeShellExecution": (".cursor/hooks/harness-guard.sh", r"git.*\scommit(?:\s|$)"),
}
for event, (command, matcher) in required.items():
    values = hooks.get(event, [])
    if not isinstance(values, list) or not any(
        isinstance(item, dict)
        and item.get("command") == command
        and item.get("matcher") == matcher
        for item in values
    ):
        raise SystemExit(1)
PY
}

remove_harness_hooks() {
  target_abs="$1"
  hooks_file="$target_abs/.cursor/hooks.json"
  [ -f "$hooks_file" ] || return 0

  own_pre=0
  own_shell=0
  manifest_has "$target_abs" "hooks-registration:preToolUse" && own_pre=1
  manifest_has "$target_abs" "hooks-registration:beforeShellExecution" && own_shell=1

  if [ "$own_pre" = "0" ] && [ "$own_shell" = "0" ]; then
    if grep -Fq '.cursor/hooks/harness-guard.sh' "$hooks_file"; then
      return 1
    fi
    return 0
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    if grep -Fq '.cursor/hooks/harness-guard.sh' "$hooks_file"; then
      echo "Lưu ý: thiếu python3 nên giữ hook config và harness-guard.sh để tránh registration mồ côi." >&2
      return 1
    fi
    return 0
  fi

  remaining=$(python3 - "$hooks_file" "$own_pre" "$own_shell" <<'PY'
import json, os, sys, tempfile
path = sys.argv[1]
owned = {
    "preToolUse": sys.argv[2] == "1",
    "beforeShellExecution": sys.argv[3] == "1",
}
required = {
    "preToolUse": (".cursor/hooks/harness-guard.sh", "Write|StrReplace"),
    "beforeShellExecution": (".cursor/hooks/harness-guard.sh", r"git.*\scommit(?:\s|$)"),
}
with open(path, encoding="utf-8") as fh:
    data = json.load(fh)
hooks = data.get("hooks", {}) if isinstance(data, dict) else {}
for event in ("preToolUse", "beforeShellExecution"):
    if not owned[event]:
        continue
    values = hooks.get(event)
    if isinstance(values, list):
        command, matcher = required[event]
        hooks[event] = [
            item for item in values
            if not (
                isinstance(item, dict)
                and item.get("command") == command
                and item.get("matcher") == matcher
            )
        ]
        if not hooks[event]:
            del hooks[event]
directory = os.path.dirname(path)
fd, tmp = tempfile.mkstemp(prefix=".hooks.", dir=directory, text=True)
try:
    with os.fdopen(fd, "w", encoding="utf-8") as fh:
        json.dump(data, fh, ensure_ascii=False, indent=2)
        fh.write("\n")
    os.replace(tmp, path)
finally:
    if os.path.exists(tmp):
        os.unlink(tmp)
print("empty" if not hooks else "remaining")
PY
)

  if grep -Fq '.cursor/hooks/harness-guard.sh' "$hooks_file"; then
    return 1
  fi

  if [ "$remaining" = "empty" ] &&
    manifest_has "$target_abs" "hooks-config-created" &&
    ! is_git_tracked "$target_abs" ".cursor/hooks.json"; then
    rm -f "$hooks_file"
  fi
  return 0
}

scaffold_project_profile() {
  target_abs="$1"
  lang_summary="$2"
  profile_path="$target_abs/harness/PROJECT.md"
  if [ -e "$profile_path" ] && ! grep -q '^<!-- harness-project-autogen -->$' "$profile_path"; then
    echo "Giữ nguyên harness/PROJECT.md hiện có của dự án."
    return 0
  fi

  proj_name=$(basename "$target_abs")
  today=$(date +%Y-%m-%d 2>/dev/null || echo "")

  hint_typecheck="(chạy skill onboard-project để điền)"
  hint_lint="(chạy skill onboard-project để điền)"
  hint_unit="(chạy skill onboard-project để điền)"
  hint_build="(chạy skill onboard-project để điền)"

  if [ -f "$target_abs/go.mod" ]; then
    hint_typecheck="go vet ./... (gợi ý tự dò)"
    hint_lint="golangci-lint run (gợi ý tự dò)"
    hint_unit="go test -race ./... (gợi ý tự dò)"
    hint_build="go build ./... (gợi ý tự dò)"
  elif [ -f "$target_abs/Cargo.toml" ]; then
    hint_typecheck="cargo check --workspace --all-targets (gợi ý tự dò)"
    hint_lint="cargo clippy --workspace --all-targets -- -D warnings (gợi ý tự dò)"
    hint_unit="cargo test --workspace (gợi ý tự dò)"
    hint_build="cargo build --workspace (gợi ý tự dò)"
  elif [ -f "$target_abs/package.json" ]; then
    pm="npm"
    [ -f "$target_abs/pnpm-lock.yaml" ] && pm="pnpm"
    [ -f "$target_abs/yarn.lock" ] && pm="yarn"
    [ -f "$target_abs/bun.lockb" ] || [ -f "$target_abs/bun.lock" ] && pm="bun"
    hint_typecheck="$pm exec tsc --noEmit (gợi ý tự dò)"
    hint_lint="$pm run lint (gợi ý tự dò)"
    hint_unit="$pm test (gợi ý tự dò)"
    hint_build="$pm run build (gợi ý tự dò)"
  elif [ -f "$target_abs/pyproject.toml" ] || [ -f "$target_abs/requirements.txt" ]; then
    hint_typecheck="pyright (gợi ý tự dò)"
    hint_lint="ruff check . (gợi ý tự dò)"
    hint_unit="pytest (gợi ý tự dò)"
    hint_build="K/A hoặc theo pyproject.toml"
  elif [ -f "$target_abs/gradlew" ] || [ -f "$target_abs/build.gradle" ] || [ -f "$target_abs/build.gradle.kts" ]; then
    hint_typecheck="./gradlew compileJava compileKotlin (gợi ý tự dò)"
    hint_lint="./gradlew check (gợi ý tự dò)"
    hint_unit="./gradlew test (gợi ý tự dò)"
    hint_build="./gradlew assemble (gợi ý tự dò)"
  elif [ -f "$target_abs/pom.xml" ]; then
    hint_typecheck="./mvnw test-compile (gợi ý tự dò)"
    hint_lint="./mvnw verify (gợi ý tự dò)"
    hint_unit="./mvnw test (gợi ý tự dò)"
    hint_build="./mvnw package -DskipTests (gợi ý tự dò)"
  elif [ -f "$target_abs/pubspec.yaml" ]; then
    hint_typecheck="dart analyze --fatal-infos (gợi ý tự dò)"
    hint_lint="dart format --output=none --set-exit-if-changed . (gợi ý tự dò)"
    hint_unit="flutter test (gợi ý tự dò)"
    hint_build="flutter build (gợi ý tự dò)"
  fi

  cat >"$profile_path" <<EOF
<!-- harness-project-autogen -->
# Hồ sơ dự án (Project Profile)

File này lưu sự thật riêng của dự án \`$proj_name\` (không bị ghi đè khi chạy lại \`install.sh\`). Hãy chạy skill \`onboard-project\` ở lần đầu để xác minh lệnh thật và ánh xạ cây thư mục, sau đó xóa dòng đánh dấu \`harness-project-autogen\` ở đầu file.

- Dự án: \`$proj_name\`
- Ngày cập nhật: $today
- Ngôn ngữ nhận diện: \`$lang_summary\`
- Cơ sở dữ liệu & hạ tầng phụ: (điền qua \`onboard-project\`)

## 1. Lệnh kiểm chứng chuẩn của dự án (G2 Sensors)

- Kiểm kiểu tĩnh (Typecheck): \`$hint_typecheck\`
- Linter & kiểm ranh giới module: \`$hint_lint\`
- Unit test: \`$hint_unit\`
- Integration / End-to-end test: (điền qua \`onboard-project\`)
- Build: \`$hint_build\`

## 2. Ánh xạ thư mục vào Bản đồ Module

- Entrypoint / Bootstrap (\`cmd\`, \`main\`, \`app-shell\`):
- Biên giao tiếp (\`transport\`, \`controllers\`, \`features-ui\`):
- Điều phối nghiệp vụ (\`application\`, \`use-cases\`, \`sync-outbox\`):
- Lõi nghiệp vụ thuần (\`domain\`, \`core-domain\` — cấm import HTTP/ORM/SDK ngoài):
- Lưu trữ & truy vấn (\`persistence\`, \`local-store\`, \`migrations\`):
- Tích hợp & việc nền (\`integrations\`, \`jobs\`, \`remote-client\`):

## 3. Ranh giới quyền hạn của Agent (Escalation)

Các thay đổi sau bắt buộc dừng hỏi và chốt \`design-note.md\` trước khi sửa code:

- Đổi schema xóa/siết cột đang có dữ liệu hoặc đổi khóa phân mảnh/tenant.
- Đổi cơ chế xác thực, phân quyền, chữ ký mật mã hoặc luồng thanh toán/tiền tệ.
- Thêm dependency hạ tầng mới (queue, cache, dịch vụ trả phí bên thứ ba) hoặc phá tương thích ngược API public.

## 4. Bẫy lịch sử cần tránh trên repo này (Known Footguns)

1.
EOF
  manifest_add "$target_abs" "project-profile-created"
}

sync_project_language_selection() {
  target_abs="$1"
  lang_summary="$2"
  profile="$target_abs/harness/PROJECT.md"
  [ -f "$profile" ] || return 0

  if grep -q '^- Ngôn ngữ nhận diện:' "$profile"; then
    tmp_profile=$(mktemp)
    awk -v value="\`$lang_summary\`" '
      /^- Ngôn ngữ nhận diện:/ { print "- Ngôn ngữ nhận diện: " value; next }
      { print }
    ' "$profile" >"$tmp_profile"
    cat "$tmp_profile" >"$profile"
    rm -f "$tmp_profile"
    return 0
  fi

  remove_marked_block "$profile" "<!-- >>> harness-language-selection >>> -->" "<!-- <<< harness-language-selection <<< -->"
  cat >>"$profile" <<EOF
<!-- >>> harness-language-selection >>> -->
- Rule ngôn ngữ đang cài: \`$lang_summary\`
<!-- <<< harness-language-selection <<< -->
EOF
}

validate_marked_block() {
  file_path="$1"
  start_marker="$2"
  end_marker="$3"
  if [ -L "$file_path" ]; then
    echo "Lỗi: từ chối sửa file symlink: $file_path" >&2
    return 1
  fi
  if [ -e "$file_path" ] && [ ! -f "$file_path" ]; then
    echo "Lỗi: bề mặt Markdown không phải file thường: $file_path" >&2
    return 1
  fi
  [ -f "$file_path" ] || return 0
  start_count=$(grep -Fxc "$start_marker" "$file_path" || true)
  end_count=$(grep -Fxc "$end_marker" "$file_path" || true)
  if [ "$start_count" = "0" ] && [ "$end_count" = "0" ]; then
    return 0
  fi
  if [ "$start_count" != "1" ] || [ "$end_count" != "1" ]; then
    echo "Lỗi: block marker không cân bằng trong $file_path" >&2
    return 1
  fi
  if ! awk -v s="$start_marker" -v e="$end_marker" '
    $0 == s { seen_start=1 }
    $0 == e && seen_start { seen_end=1 }
    END { exit !(seen_start && seen_end) }
  ' "$file_path"; then
    echo "Lỗi: block marker sai thứ tự trong $file_path" >&2
    return 1
  fi
}

remove_marked_block() {
  file_path="$1"
  start_marker="$2"
  end_marker="$3"
  [ -f "$file_path" ] || return 0
  validate_marked_block "$file_path" "$start_marker" "$end_marker" || return 1
  if ! grep -Fqx "$start_marker" "$file_path"; then
    return 0
  fi
  tmp_b=$(mktemp)
  awk -v s="$start_marker" -v e="$end_marker" '
    $0 == s { skip=1; next }
    $0 == e { skip=0; next }
    !skip { print }
  ' "$file_path" >"$tmp_b"
  cat "$tmp_b" >"$file_path"
  rm -f "$tmp_b"
}

preflight_markdown_surfaces() {
  target_abs="$1"
  cursor_only="$2"
  enable_claude="$3"
  [ "$cursor_only" = "0" ] || return 0
  validate_marked_block "$target_abs/AGENTS.md" "<!-- >>> harness-agents >>> -->" "<!-- <<< harness-agents <<< -->"
  if [ "$enable_claude" = "1" ]; then
    validate_marked_block "$target_abs/CLAUDE.md" "<!-- >>> harness-claude >>> -->" "<!-- <<< harness-claude <<< -->"
  fi
}

preflight_claude_skill_surfaces() {
  target_abs="$1"
  enable_claude="$2"
  [ "$enable_claude" = "1" ] || return 0
  validate_managed_path "$target_abs" "CLAUDE.md" || exit 1
  for skill in $SKILLS; do
    validate_managed_path "$target_abs" ".claude/skills/$skill/SKILL.md" || exit 1
  done
}

ensure_marker_line_boundary() {
  file_path="$1"
  if [ -s "$file_path" ] && [ -n "$(tail -c 1 "$file_path" 2>/dev/null)" ]; then
    printf '\n' >>"$file_path"
  fi
}

upsert_agents_md() {
  target_abs="$1"
  local_mode="$2"
  agents_file="$target_abs/AGENTS.md"

  if [ "$local_mode" = "1" ] && [ -f "$agents_file" ] && is_git_tracked "$target_abs" "AGENTS.md"; then
    echo "Chế độ --local: giữ nguyên AGENTS.md đã được git theo dõi để không làm bẩn git status."
    return 0
  fi

  touch "$agents_file"
  remove_marked_block "$agents_file" "<!-- >>> harness-agents >>> -->" "<!-- <<< harness-agents <<< -->"
  ensure_marker_line_boundary "$agents_file"

  cat >>"$agents_file" <<'EOF'
<!-- >>> harness-agents >>> -->
## Hợp đồng Harness (G0–G3)

Khi thực hiện thay đổi hành vi phần mềm trong dự án này (áp cho Cursor, Claude Code, Codex, Copilot):

1. **Đọc sự thật của dự án:** mở `harness/PROJECT.md` trước tiên để lấy lệnh kiểm chứng thật, ánh xạ module và các bẫy lịch sử (nếu chưa điền thì chạy quy trình `onboard-project`).
2. **G0 — Phạm vi:** copy `harness/templates/change-brief.md` sang bản ghi của task (ví dụ `docs/changes/<ten-task>/change-brief.md`, xem mẫu tại `harness/examples/order-create/`), không sửa trực tiếp file trong `harness/templates/`.
3. **G1 — Thiết kế & Module:** đọc `harness/HARNESS.md`, mở đúng `harness/<domain>/GATES.md` và `harness/languages/<lang>.md` liên quan. Giữ đúng chiều phụ thuộc một chiều giữa các module. Đụng API, schema, hợp đồng UI, timeout/retry, offline, hoặc thêm cạnh phụ thuộc module mới thì viết `design-note.md` trước code.
4. **G2 — Kiểm chứng:** chạy đúng các lệnh trong `harness/PROJECT.md` và ghi kết quả vào brief.
5. **G3 — Soát đối lập & Ghi nhớ:** chạy lại lệnh kiểm tra, đối chiếu diff với cổng domain/ngôn ngữ, và ghi `failure-memory.md` kèm cách phát hiện nếu gặp lỗi dễ lặp.
<!-- <<< harness-agents <<< -->
EOF
}

upsert_claude_support() {
  target_abs="$1"
  src_dir="$2"
  local_mode="$3"
  claude_file="$target_abs/CLAUDE.md"

  if [ "$local_mode" = "1" ] && [ -f "$claude_file" ] && is_git_tracked "$target_abs" "CLAUDE.md"; then
    echo "Chế độ --local: giữ nguyên CLAUDE.md và không cài Claude skills vì CLAUDE.md đang được git theo dõi."
    return 0
  fi

  manifest_add "$target_abs" "claude-enabled"
  for s in $SKILLS; do
    skill_rel=".claude/skills/$s/SKILL.md"
    skill_dest="$target_abs/$skill_rel"
    skill_entry="claude-skill:$s"
    validate_managed_path "$target_abs" "$skill_rel" || exit 1

    if [ -e "$skill_dest" ] && ! manifest_has "$target_abs" "$skill_entry"; then
      echo "Giữ nguyên $skill_rel hiện có vì Harness không sở hữu file này."
      manifest_add "$target_abs" "claude-skill-preserved:$s"
      continue
    fi
    if [ "$local_mode" = "1" ] && [ -e "$skill_dest" ] && is_git_tracked "$target_abs" "$skill_rel"; then
      echo "Chế độ --local: giữ nguyên $skill_rel đang được git theo dõi."
      continue
    fi

    mkdir -p "$(dirname -- "$skill_dest")"
    sed 's|](\.\./\.\./\.\./|](../../../harness/|g' \
      "$src_dir/.cursor/skills/$s/SKILL.md" >"$skill_dest"
    manifest_add "$target_abs" "$skill_entry"
  done

  touch "$claude_file"
  remove_marked_block "$claude_file" "<!-- >>> harness-claude >>> -->" "<!-- <<< harness-claude <<< -->"
  ensure_marker_line_boundary "$claude_file"
  cat >>"$claude_file" <<'EOF'
<!-- >>> harness-claude >>> -->
@AGENTS.md
@harness/PROJECT.md
<!-- <<< harness-claude <<< -->
EOF
}

write_exclude_block() {
  target_abs="$1"
  if ! git -C "$target_abs" rev-parse --git-dir >/dev/null 2>&1; then
    echo "Lưu ý: thư mục đích chưa có git repo nên bỏ qua bước ghi .git/info/exclude." >&2
    return 0
  fi

  git_dir=$(git -C "$target_abs" rev-parse --path-format=absolute --git-dir 2>/dev/null || (cd "$target_abs" && cd "$(git rev-parse --git-dir)" && pwd -P))
  top_dir=$(cd "$(git -C "$target_abs" rev-parse --show-toplevel)" && pwd -P)
  rel_prefix=""
  if [ "$target_abs" != "$top_dir" ]; then
    rel_prefix="${target_abs#"$top_dir"/}/"
  fi

  mkdir -p "$git_dir/info"
  exclude_file="$git_dir/info/exclude"
  touch "$exclude_file"
  remove_marked_block "$exclude_file" "# >>> harness-local >>>" "# <<< harness-local <<<"

  {
    echo "# >>> harness-local >>>"
    echo "/${rel_prefix}harness/"
    echo "/${rel_prefix}.cursor/rules/harness-*.mdc"
    echo "/${rel_prefix}.cursor/skills/onboard-project/"
    echo "/${rel_prefix}.cursor/skills/run-harness/"
    echo "/${rel_prefix}.cursor/skills/review-harness/"
    echo "/${rel_prefix}.cursor/skills/harness-*/"
    echo "/${rel_prefix}.cursor/hooks/harness-guard.sh"
    echo "/${rel_prefix}.cursor/harness-install-manifest"
    if ! is_git_tracked "$target_abs" ".cursor/hooks.json"; then
      echo "/${rel_prefix}.cursor/hooks.json"
    fi
    if ! is_git_tracked "$target_abs" ".cursor/mcp.json"; then
      echo "/${rel_prefix}.cursor/mcp.json"
    fi
    if [ -f "$target_abs/AGENTS.md" ] && ! is_git_tracked "$target_abs" "AGENTS.md"; then
      echo "/${rel_prefix}AGENTS.md"
    fi
    if [ -f "$target_abs/CLAUDE.md" ] && ! is_git_tracked "$target_abs" "CLAUDE.md"; then
      echo "/${rel_prefix}CLAUDE.md"
    fi
    if [ -d "$target_abs/.claude/skills" ]; then
      echo "/${rel_prefix}.claude/skills/onboard-project/"
      echo "/${rel_prefix}.claude/skills/run-harness/"
      echo "/${rel_prefix}.claude/skills/review-harness/"
      echo "/${rel_prefix}.claude/skills/harness-*/"
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
    md_dir=$(CDPATH= cd -- "$(dirname -- "$md_file")" && pwd -P)
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
  target_abs=$(CDPATH= cd -- "$target_dir" && pwd -P)

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
    elif [ "$mode_label" = "dự án đích" ] && ! manifest_has "$target_abs" "doc:$rel"; then
      echo "Ownership manifest thiếu tài liệu: doc:$rel" >&2
      errors=$((errors + 1))
    fi
  done

  if [ "$mode_label" = "dự án đích" ] && [ ! -s "$docs_root/PROJECT.md" ]; then
    echo "Thiếu hồ sơ dự án: harness/PROJECT.md" >&2
    errors=$((errors + 1))
  fi
  if [ "$mode_label" = "dự án đích" ] && [ ! -s "$target_abs/.cursor/harness-install-manifest" ]; then
    echo "Thiếu ownership manifest: .cursor/harness-install-manifest" >&2
    errors=$((errors + 1))
  fi

  if [ "$mode_label" = "repo nguồn" ]; then
    [ -x "$docs_root/hooks/harness-guard.sh" ] || { echo "hooks/harness-guard.sh chưa có quyền thực thi (+x)." >&2; errors=$((errors + 1)); }
  else
    [ -x "$target_abs/.cursor/hooks/harness-guard.sh" ] || { echo ".cursor/hooks/harness-guard.sh thiếu hoặc chưa có quyền thực thi (+x)." >&2; errors=$((errors + 1)); }
    if ! manifest_has "$target_abs" "hook-script-created"; then
      echo "Ownership manifest thiếu hook script: hook-script-created" >&2
      errors=$((errors + 1))
    fi
  fi

  if [ -s "$docs_root/templates/change-brief.md" ]; then
    if ! grep -q '^- Ngày:$' "$docs_root/templates/change-brief.md"; then
      echo "File mẫu templates/change-brief.md đã bị ghi đè (cần copy ra ngoài trước khi điền)." >&2
      errors=$((errors + 1))
    fi
  fi

  for r in $CORE_RULE_FILES; do
    rf="$target_abs/.cursor/rules/$r"
    if [ ! -s "$rf" ]; then
      echo "Thiếu rule: .cursor/rules/$r" >&2
      errors=$((errors + 1))
    else
      if [ "$mode_label" = "dự án đích" ] && ! manifest_has "$target_abs" "cursor-rule:$r"; then
        echo "Ownership manifest thiếu rule: cursor-rule:$r" >&2
        errors=$((errors + 1))
      fi
      grep -q '^description:' "$rf" || { echo "Rule thiếu description: $r" >&2; errors=$((errors + 1)); }
      grep -q '^alwaysApply: false' "$rf" || { echo "Rule thiếu alwaysApply: false: $r" >&2; errors=$((errors + 1)); }
    fi
  done

  installed_lang_rules=""
  for lr in $ALL_LANG_RULE_FILES; do
    lrf="$target_abs/.cursor/rules/$lr"
    if [ -f "$lrf" ]; then
      installed_lang_rules=$(add_unique_word "$installed_lang_rules" "$lr")
      if [ "$mode_label" = "dự án đích" ] && ! manifest_has "$target_abs" "cursor-rule:$lr"; then
        echo "Ownership manifest thiếu rule ngôn ngữ: cursor-rule:$lr" >&2
        errors=$((errors + 1))
      fi
      grep -q '^description:' "$lrf" || { echo "Rule ngôn ngữ thiếu description: $lr" >&2; errors=$((errors + 1)); }
      grep -q '^globs:' "$lrf" || { echo "Rule ngôn ngữ thiếu globs: $lr" >&2; errors=$((errors + 1)); }
      grep -q '^alwaysApply: false' "$lrf" || { echo "Rule ngôn ngữ thiếu alwaysApply: false: $lr" >&2; errors=$((errors + 1)); }
    elif [ "$mode_label" = "repo nguồn" ]; then
      echo "Repo nguồn thiếu rule ngôn ngữ: .cursor/rules/$lr" >&2
      errors=$((errors + 1))
    fi
  done

  if [ -z "$installed_lang_rules" ]; then
    echo "Chưa có rule ngôn ngữ nào trong .cursor/rules/harness-lang-*.mdc" >&2
    errors=$((errors + 1))
  fi

  for s in $SKILLS; do
    sf="$target_abs/.cursor/skills/$s/SKILL.md"
    if [ ! -s "$sf" ]; then
      echo "Thiếu skill: .cursor/skills/$s/SKILL.md" >&2
      errors=$((errors + 1))
    else
      if [ "$mode_label" = "dự án đích" ] && ! manifest_has "$target_abs" "cursor-skill:$s"; then
        echo "Ownership manifest thiếu skill: cursor-skill:$s" >&2
        errors=$((errors + 1))
      fi
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
mcp = json.load(open(sys.argv[1], encoding="utf-8"))
if not isinstance(mcp, dict) or "mcpServers" not in mcp:
    sys.exit(1)
if sys.argv[2] == "repo nguồn" and mcp != {"mcpServers": {}}:
    print("Repo nguồn phải để .cursor/mcp.json rỗng.", file=sys.stderr)
    sys.exit(2)
PY
    then
      echo ".cursor/mcp.json không hợp lệ." >&2
      errors=$((errors + 1))
    fi
  fi

  if [ "$mode_label" = "repo nguồn" ]; then
    hooks_file="$docs_root/hooks/hooks.example.json"
  else
    hooks_file="$target_abs/.cursor/hooks.json"
  fi
  if ! check_harness_hooks "$hooks_file"; then
    echo "Hook bảo vệ Harness chưa được đăng ký đúng trong ${hooks_file#"$target_abs"/}." >&2
    errors=$((errors + 1))
  fi
  if [ "$mode_label" = "dự án đích" ]; then
    if ! manifest_has "$target_abs" "hooks-managed"; then
      echo "Ownership manifest thiếu trạng thái hooks-managed" >&2
      errors=$((errors + 1))
    fi
    for event in preToolUse beforeShellExecution; do
      if ! manifest_has "$target_abs" "hooks-registration:$event" &&
        ! manifest_has "$target_abs" "hooks-registration-preserved:$event"; then
        echo "Ownership manifest thiếu trạng thái hook registration: $event" >&2
        errors=$((errors + 1))
      fi
    done
  fi

  if [ "$mode_label" = "dự án đích" ]; then
    if manifest_has "$target_abs" "claude-enabled"; then
      for s in $SKILLS; do
        if manifest_has "$target_abs" "claude-skill:$s"; then
          if [ ! -s "$target_abs/.claude/skills/$s/SKILL.md" ]; then
            echo "Thiếu Claude skill do Harness sở hữu: .claude/skills/$s/SKILL.md" >&2
            errors=$((errors + 1))
          fi
        elif manifest_has "$target_abs" "claude-skill-preserved:$s"; then
          if [ ! -s "$target_abs/.claude/skills/$s/SKILL.md" ]; then
            echo "Thiếu Claude skill được giữ nguyên: .claude/skills/$s/SKILL.md" >&2
            errors=$((errors + 1))
          fi
        else
          echo "Ownership manifest thiếu trạng thái Claude skill: $s" >&2
          errors=$((errors + 1))
        fi
      done
      if ! validate_marked_block "$target_abs/CLAUDE.md" "<!-- >>> harness-claude >>> -->" "<!-- <<< harness-claude <<< -->" ||
        ! grep -Fqx '<!-- >>> harness-claude >>> -->' "$target_abs/CLAUDE.md"; then
        echo "CLAUDE.md thiếu block Harness hợp lệ." >&2
        errors=$((errors + 1))
      fi
    else
      for s in $SKILLS; do
        if manifest_has "$target_abs" "claude-skill:$s" ||
          manifest_has "$target_abs" "claude-skill-preserved:$s"; then
          echo "Ownership manifest có Claude skill nhưng thiếu claude-enabled." >&2
          errors=$((errors + 1))
          break
        fi
      done
    fi
  fi

  set --
  for rel in $DOC_FILES; do
    case "$rel" in
      *.md) set -- "$@" "$docs_root/$rel" ;;
    esac
  done
  for r in $CORE_RULE_FILES $installed_lang_rules; do
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
  echo "OK: Bộ Harness tại '$target_abs' ($mode_label, ngôn ngữ: $(format_lang_summary "$installed_lang_rules")) đầy đủ và hợp lệ."
}

cleanup_markdown_file_if_empty_and_untracked() {
  target_abs="$1"
  rel_name="$2"
  fpath="$target_abs/$rel_name"
  [ -f "$fpath" ] || return 0
  rem=$(tr -d '[:space:]' <"$fpath")
  if [ -z "$rem" ] && ! is_git_tracked "$target_abs" "$rel_name"; then
    rm -f "$fpath"
  fi
}

run_uninstall() {
  target_dir="$1"
  if [ ! -d "$target_dir" ]; then
    echo "Lỗi: không tìm thấy thư mục '$target_dir'." >&2
    exit 1
  fi
  target_abs=$(CDPATH= cd -- "$target_dir" && pwd -P)
  if is_source_repo "$target_abs"; then
    echo "Lỗi: '$target_abs' là repo nguồn Harness, không chạy --uninstall tại đây." >&2
    exit 1
  fi

  keep_hook_script=0
  if ! remove_harness_hooks "$target_abs"; then
    keep_hook_script=1
  fi

  if [ -f "$target_abs/harness/PROJECT.md" ]; then
    if grep -q '^<!-- harness-project-autogen -->$' "$target_abs/harness/PROJECT.md" &&
      manifest_has "$target_abs" "project-profile-created"; then
      rm -f "$target_abs/harness/PROJECT.md"
    else
      echo "Lưu ý: giữ lại '$target_abs/harness/PROJECT.md' vì đã chứa thông tin khảo sát riêng của dự án." >&2
    fi
  fi

  for rel in $DOC_FILES; do
    if manifest_has "$target_abs" "doc:$rel"; then
      rm -f "$target_abs/harness/$rel"
    fi
  done
  rmdir "$target_abs/harness/examples/order-create" 2>/dev/null || true
  for sub in templates examples hooks mcp backend database frontend mobile network system-design languages; do
    rmdir "$target_abs/harness/$sub" 2>/dev/null || true
  done
  rmdir "$target_abs/harness" 2>/dev/null || true
  if [ -d "$target_abs/harness" ]; then
    echo "Lưu ý: giữ lại '$target_abs/harness' vì có file riêng của dự án." >&2
  fi

  for r in $CORE_RULE_FILES $ALL_LANG_RULE_FILES; do
    if manifest_has "$target_abs" "cursor-rule:$r"; then
      rm -f "$target_abs/.cursor/rules/$r"
    fi
  done
  rmdir "$target_abs/.cursor/rules" 2>/dev/null || true

  for s in $SKILLS; do
    if manifest_has "$target_abs" "cursor-skill:$s"; then
      rm -f "$target_abs/.cursor/skills/$s/SKILL.md"
      rmdir "$target_abs/.cursor/skills/$s" 2>/dev/null || true
    fi
    if manifest_has "$target_abs" "claude-skill:$s"; then
      rm -f "$target_abs/.claude/skills/$s/SKILL.md"
      rmdir "$target_abs/.claude/skills/$s" 2>/dev/null || true
    fi
  done
  rmdir "$target_abs/.cursor/skills" 2>/dev/null || true
  rmdir "$target_abs/.claude/skills" 2>/dev/null || true
  rmdir "$target_abs/.claude" 2>/dev/null || true

  if [ "$keep_hook_script" = "0" ] && manifest_has "$target_abs" "hook-script-created"; then
    rm -f "$target_abs/.cursor/hooks/harness-guard.sh"
  fi
  rmdir "$target_abs/.cursor/hooks" 2>/dev/null || true

  if [ -f "$target_abs/.cursor/mcp.json" ]; then
    compact=$(tr -d '[:space:]' <"$target_abs/.cursor/mcp.json")
    if [ "$compact" = '{"mcpServers":{}}' ] &&
      manifest_has "$target_abs" "mcp-config-created" &&
      ! is_git_tracked "$target_abs" ".cursor/mcp.json"; then
      rm -f "$target_abs/.cursor/mcp.json"
    fi
  fi
  rmdir "$target_abs/.cursor" 2>/dev/null || true

  if [ -L "$target_abs/AGENTS.md" ]; then
    echo "Lưu ý: giữ nguyên AGENTS.md vì đây là symlink." >&2
  elif [ -f "$target_abs/AGENTS.md" ]; then
    if remove_marked_block "$target_abs/AGENTS.md" "<!-- >>> harness-agents >>> -->" "<!-- <<< harness-agents <<< -->"; then
      cleanup_markdown_file_if_empty_and_untracked "$target_abs" "AGENTS.md"
    else
      echo "Lưu ý: giữ nguyên AGENTS.md vì block marker không hợp lệ." >&2
    fi
  fi
  if [ -L "$target_abs/CLAUDE.md" ]; then
    echo "Lưu ý: giữ nguyên CLAUDE.md vì đây là symlink." >&2
  elif [ -f "$target_abs/CLAUDE.md" ]; then
    if remove_marked_block "$target_abs/CLAUDE.md" "<!-- >>> harness-claude >>> -->" "<!-- <<< harness-claude <<< -->"; then
      cleanup_markdown_file_if_empty_and_untracked "$target_abs" "CLAUDE.md"
    else
      echo "Lưu ý: giữ nguyên CLAUDE.md vì block marker không hợp lệ." >&2
    fi
  fi

  if [ "$keep_hook_script" = "0" ]; then
    rm -f "$target_abs/.cursor/harness-install-manifest"
  elif [ -f "$target_abs/.cursor/harness-install-manifest" ]; then
    tmp_kept_manifest=$(mktemp)
    grep -E '^(hook-script-created|hooks-managed|hooks-registration-preserved:)' \
      "$target_abs/.cursor/harness-install-manifest" >"$tmp_kept_manifest" || true
    cat "$tmp_kept_manifest" >"$target_abs/.cursor/harness-install-manifest"
    rm -f "$tmp_kept_manifest"
  fi
  rmdir "$target_abs/.cursor" 2>/dev/null || true

  if git -C "$target_abs" rev-parse --git-dir >/dev/null 2>&1; then
    git_dir=$(git -C "$target_abs" rev-parse --path-format=absolute --git-dir 2>/dev/null || (cd "$target_abs" && cd "$(git rev-parse --git-dir)" && pwd -P))
    if [ -f "$git_dir/info/exclude" ]; then
      if ! remove_marked_block "$git_dir/info/exclude" "# >>> harness-local >>>" "# <<< harness-local <<<"; then
        echo "Lưu ý: giữ nguyên git exclude vì block marker Harness không hợp lệ." >&2
      fi
    fi
  fi

  echo "Đã gỡ bộ Harness khỏi '$target_abs' (giữ nguyên mọi file riêng của dự án)."
}

MODE="install"
LOCAL_EXCLUDE=0
CURSOR_ONLY=0
ENABLE_CLAUDE=0
ADOPT_LEGACY=0
LANG_SPEC=""
TARGET_DIR="."

while [ "$#" -gt 0 ]; do
  case "$1" in
    --lang)
      if [ "$#" -lt 2 ]; then
        echo "Lỗi: --lang cần danh sách ngôn ngữ (ví dụ: --lang ts,go,sql)." >&2
        exit 1
      fi
      LANG_SPEC="$2"
      shift 2
      ;;
    --lang=*)
      LANG_SPEC="${1#--lang=}"
      shift
      ;;
    --claude)
      ENABLE_CLAUDE=1
      shift
      ;;
    --cursor-only)
      CURSOR_ONLY=1
      shift
      ;;
    --adopt-legacy)
      ADOPT_LEGACY=1
      shift
      ;;
    --local)
      LOCAL_EXCLUDE=1
      shift
      ;;
    --check)
      if [ "$MODE" != "install" ] && [ "$MODE" != "check" ]; then
        echo "Lỗi: không thể dùng đồng thời --check và --uninstall." >&2
        exit 1
      fi
      MODE="check"
      shift
      ;;
    --uninstall)
      if [ "$MODE" != "install" ] && [ "$MODE" != "uninstall" ]; then
        echo "Lỗi: không thể dùng đồng thời --check và --uninstall." >&2
        exit 1
      fi
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

if [ "$CURSOR_ONLY" = "1" ] && [ "$ENABLE_CLAUDE" = "1" ]; then
  echo "Lỗi: không thể dùng đồng thời --cursor-only và --claude." >&2
  exit 1
fi

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

SELECTED_LANG_RULES=""
LANG_SOURCE_NOTE=""
if [ -n "$LANG_SPEC" ]; then
  SELECTED_LANG_RULES=$(parse_lang_spec "$LANG_SPEC")
  LANG_SOURCE_NOTE="theo --lang"
fi

SRC_DIR=$(resolve_source_dir)
mkdir -p "$TARGET_DIR"
TARGET_ABS=$(CDPATH= cd -- "$TARGET_DIR" && pwd -P)

if [ "$SRC_DIR" = "$TARGET_ABS" ] || is_source_repo "$TARGET_ABS"; then
  echo "Lỗi: thư mục đích '$TARGET_ABS' chính là repo nguồn Harness." >&2
  echo "Hãy truyền đường dẫn dự án mới hoặc dự án đã có: ./install.sh /duong/dan/project" >&2
  exit 1
fi

preflight_special_surfaces "$TARGET_ABS"

if [ "$LOCAL_EXCLUDE" = "1" ] && git -C "$TARGET_ABS" rev-parse --git-dir >/dev/null 2>&1; then
  if is_git_tracked "$TARGET_ABS" ".cursor/harness-install-manifest"; then
    if [ -n "$LANG_SPEC" ] || [ "$ENABLE_CLAUDE" = "1" ]; then
      echo "Lỗi: --local không đổi --lang/--claude trên bộ Harness đang được team theo dõi; hãy cập nhật ở chế độ team." >&2
      exit 1
    fi
    run_check "$TARGET_ABS"
    write_exclude_block "$TARGET_ABS"
    echo "Chế độ --local: dùng nguyên bộ Harness đang được team theo dõi; git status không đổi."
    exit 0
  fi
  tracked_harness=$(git -C "$TARGET_ABS" ls-files \
    'harness/**' \
    '.cursor/rules/harness-*' \
    '.cursor/skills/onboard-project/**' \
    '.cursor/skills/run-harness/**' \
    '.cursor/skills/review-harness/**' \
    '.cursor/skills/harness-*/**' 2>/dev/null || true)
  if [ -n "$tracked_harness" ]; then
    echo "Lỗi: repo có artifact Harness tracked nhưng thiếu ownership manifest; --local dừng để tránh sửa file team." >&2
    exit 1
  fi
fi

adopt_legacy_install_if_present "$TARGET_ABS" "$ADOPT_LEGACY"

if [ "$LOCAL_EXCLUDE" = "1" ] &&
  [ -f "$TARGET_ABS/.cursor/hooks.json" ] &&
  is_git_tracked "$TARGET_ABS" ".cursor/hooks.json" &&
  ! check_harness_hooks "$TARGET_ABS/.cursor/hooks.json"; then
  echo "Lỗi: --local giữ nguyên .cursor/hooks.json tracked, nhưng file chưa đăng ký Harness guard. Hãy thêm registration từ hooks/hooks.example.json ở chế độ team." >&2
  exit 1
fi

if [ -z "$SELECTED_LANG_RULES" ]; then
  existing_rules=$(installed_lang_rules_at "$TARGET_ABS")
  if [ -n "$existing_rules" ] &&
    [ -f "$TARGET_ABS/harness/PROJECT.md" ] &&
    ! grep -q '^<!-- harness-project-autogen -->$' "$TARGET_ABS/harness/PROJECT.md"; then
    SELECTED_LANG_RULES="$existing_rules"
    LANG_SOURCE_NOTE="giữ theo hồ sơ PROJECT.md đã xác minh; dùng --lang để đổi"
  else
    detected_rules=$(detect_project_lang_rules "$TARGET_ABS")
    if [ -n "$detected_rules" ]; then
      SELECTED_LANG_RULES="$detected_rules"
      LANG_SOURCE_NOTE="tự động phát hiện từ dự án"
    else
      SELECTED_LANG_RULES="$ALL_LANG_RULE_FILES"
      LANG_SOURCE_NOTE="dự án mới chưa có mã nguồn — nạp trọn bộ theo đuôi file"
    fi
  fi
fi

preflight_install_artifacts "$TARGET_ABS" "$SRC_DIR" "$SELECTED_LANG_RULES"
preflight_markdown_surfaces "$TARGET_ABS" "$CURSOR_ONLY" "$ENABLE_CLAUDE"
preflight_claude_skill_surfaces "$TARGET_ABS" "$ENABLE_CLAUDE"
ADOPTED_LEGACY_MANIFEST=""
if [ "$LOCAL_EXCLUDE" = "1" ] &&
  is_git_tracked "$TARGET_ABS" "harness/hooks/harness-guard.sh" &&
  [ ! -x "$TARGET_ABS/harness/hooks/harness-guard.sh" ]; then
  echo "Lỗi: --local không thể đặt quyền executable cho harness/hooks/harness-guard.sh đang được git theo dõi." >&2
  exit 1
fi

for rel in $DOC_FILES; do
  if [ "$rel" = "README.md" ]; then
    tmp_doc=$(mktemp)
    sed 's|](\.cursor/|](../.cursor/|g' "$SRC_DIR/README.md" >"$tmp_doc"
    install_managed_file "$TARGET_ABS" "$tmp_doc" "harness/$rel" "doc:$rel" "$LOCAL_EXCLUDE"
    rm -f "$tmp_doc"
  else
    install_managed_file "$TARGET_ABS" "$SRC_DIR/$rel" "harness/$rel" "doc:$rel" "$LOCAL_EXCLUDE"
  fi
done
chmod +x "$TARGET_ABS/harness/hooks/harness-guard.sh"

LANG_SUMMARY=$(format_lang_summary "$SELECTED_LANG_RULES")
scaffold_project_profile "$TARGET_ABS" "$LANG_SUMMARY"
if [ -n "$LANG_SPEC" ]; then
  sync_project_language_selection "$TARGET_ABS" "$LANG_SUMMARY"
fi

mkdir -p "$TARGET_ABS/.cursor/rules"
for r in $CORE_RULE_FILES; do
  install_managed_file "$TARGET_ABS" "$SRC_DIR/.cursor/rules/$r" ".cursor/rules/$r" "cursor-rule:$r" "$LOCAL_EXCLUDE"
done

for lr in $ALL_LANG_RULE_FILES; do
  case " $SELECTED_LANG_RULES " in
    *" $lr "*) ;;
    *)
      if manifest_has "$TARGET_ABS" "cursor-rule:$lr"; then
        rm -f "$TARGET_ABS/.cursor/rules/$lr"
        manifest_remove "$TARGET_ABS" "cursor-rule:$lr"
      fi
      ;;
  esac
done
for lr in $SELECTED_LANG_RULES; do
  install_managed_file "$TARGET_ABS" "$SRC_DIR/.cursor/rules/$lr" ".cursor/rules/$lr" "cursor-rule:$lr" "$LOCAL_EXCLUDE"
done

for s in $SKILLS; do
  install_managed_skill "$TARGET_ABS" "$SRC_DIR" "$s" "$LOCAL_EXCLUDE"
done

mkdir -p "$TARGET_ABS/.cursor/hooks"
hook_dest="$TARGET_ABS/.cursor/hooks/harness-guard.sh"
if [ -e "$hook_dest" ] && ! manifest_has "$TARGET_ABS" "hook-script-created"; then
  if ! cmp -s "$SRC_DIR/hooks/harness-guard.sh" "$hook_dest"; then
    echo "Lỗi: $hook_dest đã tồn tại nhưng không thuộc Harness; giữ nguyên file và dừng để tránh ghi đè." >&2
    exit 1
  fi
  if [ ! -x "$hook_dest" ]; then
    echo "Lỗi: $hook_dest tồn tại ngoài ownership của Harness nhưng chưa executable; giữ nguyên file và dừng." >&2
    exit 1
  fi
else
  cp "$SRC_DIR/hooks/harness-guard.sh" "$hook_dest"
  chmod +x "$hook_dest"
  manifest_add "$TARGET_ABS" "hook-script-created"
fi
if [ "$LOCAL_EXCLUDE" = "1" ] &&
  [ -f "$TARGET_ABS/.cursor/hooks.json" ] &&
  is_git_tracked "$TARGET_ABS" ".cursor/hooks.json"; then
  if ! check_harness_hooks "$TARGET_ABS/.cursor/hooks.json"; then
    echo "Lỗi: --local giữ nguyên .cursor/hooks.json tracked, nhưng file chưa đăng ký Harness guard. Hãy thêm registration từ harness/hooks/hooks.example.json ở chế độ team." >&2
    exit 1
  fi
else
  merge_harness_hooks "$TARGET_ABS" "$SRC_DIR/hooks/hooks.example.json"
fi

if [ ! -e "$TARGET_ABS/.cursor/mcp.json" ]; then
  cat >"$TARGET_ABS/.cursor/mcp.json" <<'EOF'
{
  "mcpServers": {}
}
EOF
  manifest_add "$TARGET_ABS" "mcp-config-created"
else
  echo "Giữ nguyên .cursor/mcp.json hiện có của dự án."
fi

if [ "$CURSOR_ONLY" = "0" ]; then
  upsert_agents_md "$TARGET_ABS" "$LOCAL_EXCLUDE"
  if [ "$ENABLE_CLAUDE" = "1" ]; then
    upsert_claude_support "$TARGET_ABS" "$SRC_DIR" "$LOCAL_EXCLUDE"
  fi
fi

if [ "$LOCAL_EXCLUDE" = "1" ]; then
  write_exclude_block "$TARGET_ABS"
fi

echo "Đã cài đặt Harness vào '$TARGET_ABS':"
echo "  - Hồ sơ dự án đích:         $TARGET_ABS/harness/PROJECT.md"
echo "  - Tài liệu, module & cổng:  $TARGET_ABS/harness/ (kèm mẫu tại harness/examples/order-create/)"
echo "  - Cursor rules & skills:    8 domain rules + lang [$LANG_SUMMARY] ($LANG_SOURCE_NOTE) + 10 skills"
echo "  - Hook bảo vệ cơ học:       $TARGET_ABS/.cursor/hooks/harness-guard.sh"
if [ "$CURSOR_ONLY" = "0" ]; then
  echo "  - Đa công cụ AI:            $TARGET_ABS/AGENTS.md"
fi
echo "Bước tiếp: chạy skill 'onboard-project' (lần đầu) hoặc copy harness/templates/change-brief.md cho task mới."
