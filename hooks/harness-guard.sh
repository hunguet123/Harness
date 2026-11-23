#!/bin/sh
set -eu

# Hook bảo vệ cơ học của Harness cho Cursor (schema version 1).
# 1. Chặn ghi đè trực tiếp các file mẫu chỉ đọc trong harness/templates/*.
# 2. Chặn git commit nếu .cursor/mcp.json đang được stage kèm chuỗi kết nối/khóa bí mật.

input=$(cat || true)

deny() {
  user_msg="$1"
  agent_msg="$2"
  escaped_user=$(printf '%s' "$user_msg" | sed 's/\\/\\\\/g; s/"/\\"/g')
  escaped_agent=$(printf '%s' "$agent_msg" | sed 's/\\/\\\\/g; s/"/\\"/g')
  printf '{"permission":"deny","user_message":"%s","agent_message":"%s"}\n' "$escaped_user" "$escaped_agent"
  exit 0
}

# 1. Bảo vệ harness/templates/* tại dự án đích (không áp cho repo nguồn của chính Harness)
if [ -d "harness/templates" ] && printf '%s' "$input" | grep -qE '"(path|file_path)"[[:space:]]*:[[:space:]]*"[^"]*harness/templates/'; then
  deny \
    "Harness chặn sửa trực tiếp file mẫu trong harness/templates/." \
    "Không ghi đè file mẫu trong harness/templates/. Hãy copy mẫu sang thư mục tài liệu của task (ví dụ docs/changes/<ten-task>/) rồi điền."
fi

# 2. Kiểm tra an toàn trước khi git commit (kể cả `git -C <repo> commit`)
if printf '%s' "$input" | grep -qE '"command"[[:space:]]*:.*git[^"]*[[:space:]]commit([[:space:]]|")'; then
  repo_dir="."
  hook_cwd=$(printf '%s' "$input" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
  [ -n "$hook_cwd" ] && repo_dir="$hook_cwd"
  git_c_dir=$(printf '%s' "$input" | sed -n 's/.*git[^"]*[[:space:]]-C[[:space:]][[:space:]]*"\{0,1\}\([^"[:space:]]*\)"\{0,1\}[[:space:]].*/\1/p')
  if [ -n "$git_c_dir" ]; then
    case "$git_c_dir" in
      /*) repo_dir="$git_c_dir" ;;
      *) repo_dir="$repo_dir/$git_c_dir" ;;
    esac
  fi

  if command -v git >/dev/null 2>&1 && git -C "$repo_dir" rev-parse --git-dir >/dev/null 2>&1; then
    git_top=$(CDPATH= cd -- "$(git -C "$repo_dir" rev-parse --show-toplevel)" && pwd -P)
    repo_abs=$(CDPATH= cd -- "$repo_dir" && pwd -P)
    mcp_path=".cursor/mcp.json"
    if [ "$repo_abs" != "$git_top" ]; then
      case "$repo_abs" in
        "$git_top"/*) mcp_path="${repo_abs#"$git_top"/}/.cursor/mcp.json" ;;
      esac
    fi
    if git -C "$repo_dir" diff --cached --name-only 2>/dev/null | grep -Fqx "$mcp_path"; then
      if git -C "$repo_dir" show ":$mcp_path" 2>/dev/null | grep -qE '(postgres(ql)?://|mysql://|mongodb(\+srv)?://|redis://|Bearer[[:space:]]+[A-Za-z0-9._-]+|sk-(proj-)?[A-Za-z0-9_-]{12,}|gh[pousr]_[A-Za-z0-9_]{20,}|"(api[_-]?[Kk]ey|access[_-]?[Tt]oken|client[_-]?[Ss]ecret|password)"[[:space:]]*:[[:space:]]*"[^"]{8,}")'; then
        deny \
          "Harness chặn commit .cursor/mcp.json vì phát hiện chuỗi kết nối hoặc token bí mật." \
          "Không commit URI kết nối hoặc secret trong .cursor/mcp.json. Dùng keyring/profile chỉ đọc hoặc trả .cursor/mcp.json về {\"mcpServers\": {}}."
      fi
    fi
  fi
fi

printf '{"permission":"allow"}\n'
exit 0
