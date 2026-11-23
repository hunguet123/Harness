#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
INSTALL="$ROOT/install.sh"
TMP_ROOT=$(mktemp -d)
trap 'rm -rf "$TMP_ROOT"' EXIT INT TERM

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_file() {
  [ -f "$1" ] || fail "missing file: $1"
}

assert_not_file() {
  [ ! -f "$1" ] || fail "unexpected file: $1"
}

assert_contains() {
  grep -Fq "$2" "$1" || fail "$1 does not contain: $2"
}

assert_not_contains() {
  if grep -Fq "$2" "$1"; then
    fail "$1 unexpectedly contains: $2"
  fi
}

assert_json_permission() {
  payload="$1"
  expected="$2"
  python3 - "$payload" "$expected" <<'PY' || fail "invalid hook JSON or permission"
import json, sys
data = json.loads(sys.argv[1])
assert data.get("permission") == sys.argv[2], data
PY
}

init_git() {
  git -C "$1" init -q -b main
  git -C "$1" config user.email "harness-test@example.com"
  git -C "$1" config user.name "Harness Test"
}

make_legacy_install() {
  target="$1"
  mkdir -p "$target/harness" "$target/.cursor/rules" "$target/.cursor/skills/run-harness" "$target/.cursor"
  cp "$ROOT/HARNESS.md" "$target/harness/HARNESS.md"
  cp "$ROOT/.cursor/rules/harness-core.mdc" "$target/.cursor/rules/harness-core.mdc"
  sed 's|](\.\./\.\./\.\./|](../../../harness/|g' \
    "$ROOT/.cursor/skills/run-harness/SKILL.md" >"$target/.cursor/skills/run-harness/SKILL.md"
  printf '%s\n' '{"mcpServers":{}}' >"$target/.cursor/mcp.json"
}

echo "1/7 source integrity and new install"
"$INSTALL" --check "$ROOT" >/dev/null
NEW="$TMP_ROOT/new"
"$INSTALL" --lang go "$NEW" >/dev/null
"$INSTALL" --check "$NEW" >/dev/null
assert_file "$NEW/.cursor/hooks/harness-guard.sh"
assert_contains "$NEW/.cursor/hooks.json" ".cursor/hooks/harness-guard.sh"
assert_file "$NEW/.cursor/rules/harness-lang-go.mdc"
assert_not_file "$NEW/.cursor/rules/harness-lang-sql-idl.mdc"
NO_PYTHON_BIN="$TMP_ROOT/no-python-bin"
mkdir -p "$NO_PYTHON_BIN"
for command_name in grep sed awk tr dirname; do
  ln -s "$(command -v "$command_name")" "$NO_PYTHON_BIN/$command_name"
done
if PATH="$NO_PYTHON_BIN" "$INSTALL" --check "$NEW" >/dev/null 2>&1; then
  fail "--check accepted hooks without an available JSON parser"
fi

echo "2/7 existing hooks merge, check, and uninstall"
HOOKS="$TMP_ROOT/hooks"
mkdir -p "$HOOKS/.cursor"
cat >"$HOOKS/.cursor/hooks.json" <<'EOF'
{
  "version": 1,
  "hooks": {
    "stop": [
      {"command": "./team-hook.sh", "timeout": 3}
    ]
  }
}
EOF
"$INSTALL" "$HOOKS" >/dev/null
assert_contains "$HOOKS/.cursor/hooks.json" "./team-hook.sh"
assert_contains "$HOOKS/.cursor/hooks.json" ".cursor/hooks/harness-guard.sh"
"$INSTALL" --check "$HOOKS" >/dev/null
python3 - "$HOOKS/.cursor/hooks.json" <<'PY'
import json, sys
path = sys.argv[1]
data = json.load(open(path, encoding="utf-8"))
data["hooks"]["preToolUse"][0]["matcher"] = "WrongMatcher"
json.dump(data, open(path, "w", encoding="utf-8"), indent=2)
PY
if "$INSTALL" --check "$HOOKS" >/dev/null 2>&1; then
  fail "--check accepted wrong Harness registration"
fi
python3 - "$HOOKS/.cursor/hooks.json" <<'PY'
import json, sys
path = sys.argv[1]
data = json.load(open(path, encoding="utf-8"))
data["hooks"]["preToolUse"] = []
json.dump(data, open(path, "w", encoding="utf-8"), indent=2)
PY
"$INSTALL" "$HOOKS" >/dev/null
"$INSTALL" --uninstall "$HOOKS" >/dev/null
assert_contains "$HOOKS/.cursor/hooks.json" "./team-hook.sh"
assert_not_contains "$HOOKS/.cursor/hooks.json" ".cursor/hooks/harness-guard.sh"
assert_not_file "$HOOKS/.cursor/hooks/harness-guard.sh"

SYNCED_EXAMPLE="$TMP_ROOT/synced-example"
"$INSTALL" "$SYNCED_EXAMPLE" >/dev/null
python3 - "$SYNCED_EXAMPLE/.cursor/hooks.json" <<'PY'
import json, sys
path = sys.argv[1]
data = json.load(open(path, encoding="utf-8"))
data["hooks"]["stop"] = [{"command": "./team-hook.sh", "timeout": 3}]
json.dump(data, open(path, "w", encoding="utf-8"), indent=2)
json.dump(data, open(path.replace(".cursor/hooks.json", "harness/hooks/hooks.example.json"), "w", encoding="utf-8"), indent=2)
PY
"$INSTALL" --uninstall "$SYNCED_EXAMPLE" >/dev/null
assert_file "$SYNCED_EXAMPLE/.cursor/hooks.json"
assert_contains "$SYNCED_EXAMPLE/.cursor/hooks.json" "./team-hook.sh"

PRE_REGISTERED="$TMP_ROOT/pre-registered"
mkdir -p "$PRE_REGISTERED/.cursor"
cat >"$PRE_REGISTERED/.cursor/hooks.json" <<'EOF'
{
  "version": 1,
  "hooks": {
    "preToolUse": [
      {
        "command": ".cursor/hooks/harness-guard.sh",
        "matcher": "Write|StrReplace",
        "timeout": 99
      }
    ],
    "stop": [
      {"command": "./team-hook.sh", "timeout": 3}
    ]
  }
}
EOF
"$INSTALL" "$PRE_REGISTERED" >/dev/null
"$INSTALL" --uninstall "$PRE_REGISTERED" >/dev/null
assert_contains "$PRE_REGISTERED/.cursor/hooks.json" ".cursor/hooks/harness-guard.sh"
assert_contains "$PRE_REGISTERED/.cursor/hooks.json" '"timeout": 99'
assert_not_contains "$PRE_REGISTERED/.cursor/hooks.json" 'git.*\\scommit'
assert_file "$PRE_REGISTERED/.cursor/hooks/harness-guard.sh"
mkdir -p "$PRE_REGISTERED/harness"
printf 'USER DATA AFTER UNINSTALL\n' >"$PRE_REGISTERED/harness/HARNESS.md"
if "$INSTALL" "$PRE_REGISTERED" >/dev/null 2>&1; then
  fail "reinstall trusted stale document ownership after partial hook preservation"
fi
assert_contains "$PRE_REGISTERED/harness/HARNESS.md" "USER DATA AFTER UNINSTALL"

PRE_MCP="$TMP_ROOT/pre-mcp"
mkdir -p "$PRE_MCP/.cursor"
printf '%s\n' '{"mcpServers":{}}' >"$PRE_MCP/.cursor/mcp.json"
"$INSTALL" "$PRE_MCP" >/dev/null
"$INSTALL" --uninstall "$PRE_MCP" >/dev/null
assert_file "$PRE_MCP/.cursor/mcp.json"

echo "3/7 Claude opt-in and ownership"
CLAUDE="$TMP_ROOT/claude"
mkdir -p "$CLAUDE/.claude/skills/harness-backend"
printf 'USER OWNED\n' >"$CLAUDE/.claude/skills/harness-backend/SKILL.md"
"$INSTALL" "$CLAUDE" >/dev/null
assert_contains "$CLAUDE/.claude/skills/harness-backend/SKILL.md" "USER OWNED"
assert_not_file "$CLAUDE/CLAUDE.md"
"$INSTALL" --claude "$CLAUDE" >/dev/null
assert_contains "$CLAUDE/.claude/skills/harness-backend/SKILL.md" "USER OWNED"
assert_file "$CLAUDE/.claude/skills/run-harness/SKILL.md"
"$INSTALL" --uninstall "$CLAUDE" >/dev/null
assert_contains "$CLAUDE/.claude/skills/harness-backend/SKILL.md" "USER OWNED"
assert_not_file "$CLAUDE/.claude/skills/run-harness/SKILL.md"

NO_NEWLINE="$TMP_ROOT/no-newline"
mkdir -p "$NO_NEWLINE"
printf 'USER AGENTS' >"$NO_NEWLINE/AGENTS.md"
printf 'USER CLAUDE' >"$NO_NEWLINE/CLAUDE.md"
"$INSTALL" --claude "$NO_NEWLINE" >/dev/null
"$INSTALL" --uninstall "$NO_NEWLINE" >/dev/null
assert_not_contains "$NO_NEWLINE/AGENTS.md" "harness-agents"
assert_not_contains "$NO_NEWLINE/CLAUDE.md" "harness-claude"
[ "$(cat "$NO_NEWLINE/AGENTS.md")" = "USER AGENTS" ] || fail "AGENTS.md content changed"
[ "$(cat "$NO_NEWLINE/CLAUDE.md")" = "USER CLAUDE" ] || fail "CLAUDE.md content changed"

CURSOR_ONLY="$TMP_ROOT/cursor-only"
mkdir -p "$CURSOR_ONLY/.claude/skills/harness-backend"
printf 'USER OWNED\n' >"$CURSOR_ONLY/.claude/skills/harness-backend/SKILL.md"
"$INSTALL" --cursor-only "$CURSOR_ONLY" >/dev/null
"$INSTALL" --uninstall "$CURSOR_ONLY" >/dev/null
assert_contains "$CURSOR_ONLY/.claude/skills/harness-backend/SKILL.md" "USER OWNED"

echo "4/7 --local preserves tracked Claude files"
LOCAL="$TMP_ROOT/local"
mkdir -p "$LOCAL/.claude/skills/harness-backend"
printf '# Team Claude\n' >"$LOCAL/CLAUDE.md"
printf 'TRACKED USER SKILL\n' >"$LOCAL/.claude/skills/harness-backend/SKILL.md"
init_git "$LOCAL"
git -C "$LOCAL" add -A
git -C "$LOCAL" commit -q -m init
"$INSTALL" --local --claude "$LOCAL" >/dev/null
[ -z "$(git -C "$LOCAL" status --porcelain)" ] || fail "--local dirtied tracked files"
assert_contains "$LOCAL/.claude/skills/harness-backend/SKILL.md" "TRACKED USER SKILL"
"$INSTALL" --uninstall "$LOCAL" >/dev/null
[ -z "$(git -C "$LOCAL" status --porcelain)" ] || fail "--local uninstall dirtied tracked files"

LOCAL_HOOKS="$TMP_ROOT/local-hooks"
mkdir -p "$LOCAL_HOOKS/.cursor"
printf '%s\n' '{"version":1,"hooks":{}}' >"$LOCAL_HOOKS/.cursor/hooks.json"
init_git "$LOCAL_HOOKS"
git -C "$LOCAL_HOOKS" add -A
git -C "$LOCAL_HOOKS" commit -q -m init
if "$INSTALL" --local "$LOCAL_HOOKS" >/dev/null 2>&1; then
  fail "--local accepted tracked hooks config without Harness registration"
fi
[ -z "$(git -C "$LOCAL_HOOKS" status --porcelain)" ] || fail "--local modified tracked hooks config"

TEAM_HARNESS="$TMP_ROOT/team-harness"
"$INSTALL" "$TEAM_HARNESS" >/dev/null
init_git "$TEAM_HARNESS"
git -C "$TEAM_HARNESS" add -A
git -C "$TEAM_HARNESS" commit -q -m init
if "$INSTALL" --local --lang go "$TEAM_HARNESS" >/dev/null 2>&1; then
  fail "--local --lang modified or accepted a tracked team Harness"
fi
[ -z "$(git -C "$TEAM_HARNESS" status --porcelain)" ] || fail "--local --lang dirtied team Harness"
"$INSTALL" --local "$TEAM_HARNESS" >/dev/null
[ -z "$(git -C "$TEAM_HARNESS" status --porcelain)" ] || fail "--local dirtied tracked team Harness"

TEAM_SKILL="$TMP_ROOT/team-skill"
mkdir -p "$TEAM_SKILL/.cursor/skills/team-skill"
printf 'TEAM SKILL\n' >"$TEAM_SKILL/.cursor/skills/team-skill/SKILL.md"
init_git "$TEAM_SKILL"
git -C "$TEAM_SKILL" add -A
git -C "$TEAM_SKILL" commit -q -m init
"$INSTALL" --local "$TEAM_SKILL" >/dev/null
[ -z "$(git -C "$TEAM_SKILL" status --porcelain)" ] || fail "--local dirtied repo with unrelated team skill"

echo "5/7 language detection and profile consistency"
DEEP="$TMP_ROOT/deep"
mkdir -p "$DEEP/services/orders/src"
printf 'module example/orders\n' >"$DEEP/services/orders/src/go.mod"
"$INSTALL" "$DEEP" >/dev/null
assert_file "$DEEP/.cursor/rules/harness-lang-go.mdc"
assert_not_file "$DEEP/.cursor/rules/harness-lang-ts.mdc"
assert_contains "$DEEP/harness/PROJECT.md" 'Ngôn ngữ nhận diện: `go`'
rm -f "$DEEP/services/orders/src/go.mod"
printf '{"name":"orders"}\n' >"$DEEP/services/orders/src/package.json"
"$INSTALL" "$DEEP" >/dev/null
assert_file "$DEEP/.cursor/rules/harness-lang-ts.mdc"
assert_not_file "$DEEP/.cursor/rules/harness-lang-go.mdc"
assert_contains "$DEEP/harness/PROJECT.md" 'Ngôn ngữ nhận diện: `ts`'
sed -i.bak '/harness-project-autogen/d' "$DEEP/harness/PROJECT.md"
rm -f "$DEEP/harness/PROJECT.md.bak"
rm -f "$DEEP/services/orders/src/package.json"
printf 'module example/orders\n' >"$DEEP/services/orders/src/go.mod"
"$INSTALL" "$DEEP" >/dev/null
assert_file "$DEEP/.cursor/rules/harness-lang-ts.mdc"
assert_not_file "$DEEP/.cursor/rules/harness-lang-go.mdc"
"$INSTALL" --lang go "$DEEP" >/dev/null
assert_file "$DEEP/.cursor/rules/harness-lang-go.mdc"
assert_not_file "$DEEP/.cursor/rules/harness-lang-ts.mdc"
assert_contains "$DEEP/harness/PROJECT.md" 'Ngôn ngữ nhận diện: `go`'

echo "6/7 guard behavior"
GUARD="$TMP_ROOT/guard"
mkdir -p "$GUARD/.cursor" "$GUARD/harness/templates"
cp "$ROOT/hooks/harness-guard.sh" "$GUARD/guard.sh"
init_git "$GUARD"
printf '%s\n' '{"mcpServers":{"x":{"apiKey":"api_live_1234567890abcdef"}}}' >"$GUARD/.cursor/mcp.json"
git -C "$GUARD" add .cursor/mcp.json
printf '%s\n' '{"mcpServers":{}}' >"$GUARD/.cursor/mcp.json"
out=$(cd "$GUARD" && printf '%s' '{"command":"git commit -m test"}' | sh guard.sh)
assert_json_permission "$out" "deny"
printf '%s\n' '{"mcpServers":{"db":{"url":"postgresql://admin:secret@db/prod"}}}' >"$GUARD/.cursor/mcp.json"
git -C "$GUARD" add .cursor/mcp.json
printf '%s\n' '{"mcpServers":{}}' >"$GUARD/.cursor/mcp.json"
out=$(cd "$GUARD" && printf '%s' '{"command":"git commit -m test"}' | sh guard.sh)
assert_json_permission "$out" "deny"
printf '%s\n' '{"mcpServers":{"x":{"token":"sk-proj-1234567890abcdef"}}}' >"$GUARD/.cursor/mcp.json"
git -C "$GUARD" add .cursor/mcp.json
printf '%s\n' '{"mcpServers":{}}' >"$GUARD/.cursor/mcp.json"
out=$(cd "$GUARD" && printf '%s' '{"command":"git commit -m test"}' | sh guard.sh)
assert_json_permission "$out" "deny"
out=$(cd "$GUARD" && printf '%s' '{"command":"git --no-pager commit -m test"}' | sh guard.sh)
assert_json_permission "$out" "deny"

NESTED="$GUARD/nested"
mkdir -p "$NESTED/.cursor"
init_git "$NESTED"
printf '%s\n' '{"mcpServers":{"x":{"apiKey":"nested_live_1234567890"}}}' >"$NESTED/.cursor/mcp.json"
git -C "$NESTED" add .cursor/mcp.json
printf '%s\n' '{"mcpServers":{}}' >"$NESTED/.cursor/mcp.json"
out=$(cd "$GUARD" && printf '%s' '{"command":"git -C nested commit -m test"}' | sh guard.sh)
assert_json_permission "$out" "deny"
out=$(cd "$GUARD" && printf '%s' '{"command":"git --no-pager -C nested commit -m test"}' | sh guard.sh)
assert_json_permission "$out" "deny"

PARENT_CHILD="$GUARD/parent-child"
mkdir -p "$PARENT_CHILD/.cursor"
printf '%s\n' '{"mcpServers":{"x":{"apiKey":"parent_nested_1234567890"}}}' >"$PARENT_CHILD/.cursor/mcp.json"
git -C "$GUARD" add parent-child/.cursor/mcp.json
printf '%s\n' '{"mcpServers":{}}' >"$PARENT_CHILD/.cursor/mcp.json"
out=$(cd "$PARENT_CHILD" && printf '%s' '{"command":"git commit -m test"}' | sh ../guard.sh)
assert_json_permission "$out" "deny"
out=$(cd "$GUARD" && printf '%s' '{"path":"harness/templates/change-brief.md"}' | sh guard.sh)
assert_json_permission "$out" "deny"
out=$(cd "$GUARD" && printf '%s' '{"path":"docs/changes/x/change-brief.md"}' | sh guard.sh)
assert_json_permission "$out" "allow"

echo "7/7 idempotent reinstall and clean removal"
LEGACY_CONFLICT="$TMP_ROOT/legacy-conflict"
make_legacy_install "$LEGACY_CONFLICT"
mkdir -p "$LEGACY_CONFLICT/harness/languages"
printf 'USER OWNED LEGACY-ADJACENT FILE\n' >"$LEGACY_CONFLICT/harness/languages/go.md"
if "$INSTALL" --adopt-legacy "$LEGACY_CONFLICT" >/dev/null 2>&1; then
  fail "legacy migration adopted a non-legacy file"
fi
assert_contains "$LEGACY_CONFLICT/harness/languages/go.md" "USER OWNED"
assert_not_file "$LEGACY_CONFLICT/.cursor/harness-install-manifest"

LEGACY="$TMP_ROOT/legacy"
make_legacy_install "$LEGACY"
if "$INSTALL" "$LEGACY" >/dev/null 2>&1; then
  fail "legacy install was adopted without explicit confirmation"
fi
assert_not_file "$LEGACY/.cursor/harness-install-manifest"
"$INSTALL" --adopt-legacy "$LEGACY" >/dev/null
"$INSTALL" --check "$LEGACY" >/dev/null

LEGACY_LATE_CONFLICT="$TMP_ROOT/legacy-late-conflict"
make_legacy_install "$LEGACY_LATE_CONFLICT"
mkdir "$LEGACY_LATE_CONFLICT/AGENTS.md"
if "$INSTALL" --adopt-legacy "$LEGACY_LATE_CONFLICT" >/dev/null 2>&1; then
  fail "legacy migration accepted non-file AGENTS.md"
fi
assert_not_file "$LEGACY_LATE_CONFLICT/.cursor/harness-install-manifest"
assert_not_file "$LEGACY_LATE_CONFLICT/harness/languages/go.md"

CLEAN="$TMP_ROOT/clean"
"$INSTALL" --claude "$CLEAN" >/dev/null
"$INSTALL" --claude "$CLEAN" >/dev/null
"$INSTALL" --check "$CLEAN" >/dev/null
"$INSTALL" --uninstall "$CLEAN" >/dev/null
assert_not_file "$CLEAN/.cursor/hooks.json"
assert_not_file "$CLEAN/.cursor/hooks/harness-guard.sh"
assert_not_file "$CLEAN/.cursor/harness-install-manifest"

MANIFEST="$TMP_ROOT/manifest"
"$INSTALL" "$MANIFEST" >/dev/null
rm -f "$MANIFEST/.cursor/harness-install-manifest"
if "$INSTALL" --check "$MANIFEST" >/dev/null 2>&1; then
  fail "--check accepted a target without ownership manifest"
fi
MANIFEST_PARTIAL="$TMP_ROOT/manifest-partial"
"$INSTALL" "$MANIFEST_PARTIAL" >/dev/null
grep -Fvx 'doc:HARNESS.md' "$MANIFEST_PARTIAL/.cursor/harness-install-manifest" >"$MANIFEST_PARTIAL/.cursor/manifest.tmp"
mv "$MANIFEST_PARTIAL/.cursor/manifest.tmp" "$MANIFEST_PARTIAL/.cursor/harness-install-manifest"
if "$INSTALL" --check "$MANIFEST_PARTIAL" >/dev/null 2>&1; then
  fail "--check accepted incomplete ownership metadata"
fi
HOOK_MANIFEST="$TMP_ROOT/hook-manifest"
"$INSTALL" "$HOOK_MANIFEST" >/dev/null
grep -Fvx 'hook-script-created' "$HOOK_MANIFEST/.cursor/harness-install-manifest" >"$HOOK_MANIFEST/.cursor/manifest.tmp"
mv "$HOOK_MANIFEST/.cursor/manifest.tmp" "$HOOK_MANIFEST/.cursor/harness-install-manifest"
if "$INSTALL" --check "$HOOK_MANIFEST" >/dev/null 2>&1; then
  fail "--check accepted missing hook-script ownership"
fi
HOOK_REG_MANIFEST="$TMP_ROOT/hook-reg-manifest"
"$INSTALL" "$HOOK_REG_MANIFEST" >/dev/null
grep -Fvx 'hooks-registration:preToolUse' "$HOOK_REG_MANIFEST/.cursor/harness-install-manifest" >"$HOOK_REG_MANIFEST/.cursor/manifest.tmp"
mv "$HOOK_REG_MANIFEST/.cursor/manifest.tmp" "$HOOK_REG_MANIFEST/.cursor/harness-install-manifest"
if "$INSTALL" --check "$HOOK_REG_MANIFEST" >/dev/null 2>&1; then
  fail "--check accepted missing hook-registration ownership"
fi
MERGED_HOOK_META="$TMP_ROOT/merged-hook-meta"
mkdir -p "$MERGED_HOOK_META/.cursor"
printf '%s\n' '{"version":1,"hooks":{}}' >"$MERGED_HOOK_META/.cursor/hooks.json"
"$INSTALL" "$MERGED_HOOK_META" >/dev/null
grep -Fvx 'hooks-registration:preToolUse' "$MERGED_HOOK_META/.cursor/harness-install-manifest" >"$MERGED_HOOK_META/.cursor/manifest.tmp"
mv "$MERGED_HOOK_META/.cursor/manifest.tmp" "$MERGED_HOOK_META/.cursor/harness-install-manifest"
if "$INSTALL" --check "$MERGED_HOOK_META" >/dev/null 2>&1; then
  fail "--check accepted missing merged-hook ownership"
fi

CLAUDE_CHECK="$TMP_ROOT/claude-check"
"$INSTALL" --claude "$CLAUDE_CHECK" >/dev/null
rm -f "$CLAUDE_CHECK/.claude/skills/run-harness/SKILL.md"
if "$INSTALL" --check "$CLAUDE_CHECK" >/dev/null 2>&1; then
  fail "--check accepted missing owned Claude skill"
fi
CLAUDE_META="$TMP_ROOT/claude-meta"
"$INSTALL" --claude "$CLAUDE_META" >/dev/null
rm -f "$CLAUDE_META/.claude/skills/run-harness/SKILL.md"
grep -Fvx 'claude-skill:run-harness' "$CLAUDE_META/.cursor/harness-install-manifest" >"$CLAUDE_META/.cursor/manifest.tmp"
mv "$CLAUDE_META/.cursor/manifest.tmp" "$CLAUDE_META/.cursor/harness-install-manifest"
if "$INSTALL" --check "$CLAUDE_META" >/dev/null 2>&1; then
  fail "--check accepted missing Claude skill and metadata"
fi

OWNERSHIP="$TMP_ROOT/ownership"
mkdir -p "$OWNERSHIP/.cursor/rules" "$OWNERSHIP/.cursor/skills/run-harness"
printf 'USER RULE\n' >"$OWNERSHIP/.cursor/rules/harness-core.mdc"
printf 'USER SKILL\n' >"$OWNERSHIP/.cursor/skills/run-harness/SKILL.md"
if "$INSTALL" "$OWNERSHIP" >/dev/null 2>&1; then
  fail "installer overwrote or accepted unowned Cursor artifacts"
fi
assert_contains "$OWNERSHIP/.cursor/rules/harness-core.mdc" "USER RULE"
assert_contains "$OWNERSHIP/.cursor/skills/run-harness/SKILL.md" "USER SKILL"

DOC_OWNERSHIP="$TMP_ROOT/doc-ownership"
mkdir -p "$DOC_OWNERSHIP/harness"
printf 'USER HARNESS DOC\n' >"$DOC_OWNERSHIP/harness/HARNESS.md"
if "$INSTALL" "$DOC_OWNERSHIP" >/dev/null 2>&1; then
  fail "installer overwrote an unowned harness document"
fi
assert_contains "$DOC_OWNERSHIP/harness/HARNESS.md" "USER HARNESS DOC"
assert_not_file "$DOC_OWNERSHIP/harness/PROJECT.md"
assert_not_file "$DOC_OWNERSHIP/.cursor/rules/harness-core.mdc"

IDENTICAL_DOC="$TMP_ROOT/identical-doc"
mkdir -p "$IDENTICAL_DOC/harness"
cp "$ROOT/HARNESS.md" "$IDENTICAL_DOC/harness/HARNESS.md"
if "$INSTALL" "$IDENTICAL_DOC" >/dev/null 2>&1; then
  fail "installer adopted an identical unowned document"
fi
assert_file "$IDENTICAL_DOC/harness/HARNESS.md"

INVALID_HOOKS="$TMP_ROOT/invalid-hooks"
mkdir -p "$INVALID_HOOKS/.cursor"
printf '%s\n' '{"version":1,"hooks":{"preToolUse":{}}}' >"$INVALID_HOOKS/.cursor/hooks.json"
if "$INSTALL" "$INVALID_HOOKS" >/dev/null 2>&1; then
  fail "installer accepted invalid hook event type"
fi
assert_not_file "$INVALID_HOOKS/harness/HARNESS.md"
assert_not_file "$INVALID_HOOKS/.cursor/harness-install-manifest"

MANAGED_DIRECTORY="$TMP_ROOT/managed-directory"
"$INSTALL" "$MANAGED_DIRECTORY" >/dev/null
rm -f "$MANAGED_DIRECTORY/.cursor/rules/harness-core.mdc"
mkdir "$MANAGED_DIRECTORY/.cursor/rules/harness-core.mdc"
if "$INSTALL" "$MANAGED_DIRECTORY" >/dev/null 2>&1; then
  fail "installer accepted directory at managed file path"
fi
assert_not_file "$MANAGED_DIRECTORY/.cursor/rules/harness-core.mdc/harness-core.mdc"

SYMLINK_SURFACE="$TMP_ROOT/symlink-surface"
mkdir -p "$SYMLINK_SURFACE"
printf 'EXTERNAL AGENT RULES\n' >"$TMP_ROOT/external-agents.md"
ln -s "$TMP_ROOT/external-agents.md" "$SYMLINK_SURFACE/AGENTS.md"
if "$INSTALL" "$SYMLINK_SURFACE" >/dev/null 2>&1; then
  fail "installer followed AGENTS.md symlink"
fi
assert_contains "$TMP_ROOT/external-agents.md" "EXTERNAL AGENT RULES"
assert_not_file "$SYMLINK_SURFACE/harness/HARNESS.md"

CLAUDE_SYMLINK="$TMP_ROOT/claude-symlink"
mkdir -p "$CLAUDE_SYMLINK" "$TMP_ROOT/external-claude"
ln -s "$TMP_ROOT/external-claude" "$CLAUDE_SYMLINK/.claude"
if "$INSTALL" --claude "$CLAUDE_SYMLINK" >/dev/null 2>&1; then
  fail "installer followed .claude symlink"
fi
assert_not_file "$TMP_ROOT/external-claude/skills/run-harness/SKILL.md"
assert_not_file "$CLAUDE_SYMLINK/harness/HARNESS.md"

MANAGED_SYMLINK="$TMP_ROOT/managed-symlink"
mkdir -p "$MANAGED_SYMLINK/harness"
ln -s "$TMP_ROOT/dangling-external.md" "$MANAGED_SYMLINK/harness/HARNESS.md"
if "$INSTALL" "$MANAGED_SYMLINK" >/dev/null 2>&1; then
  fail "installer followed a managed-file symlink"
fi
assert_not_file "$TMP_ROOT/dangling-external.md"
assert_not_file "$MANAGED_SYMLINK/.cursor/harness-install-manifest"

PROJECT_DIR="$TMP_ROOT/project-dir"
mkdir -p "$PROJECT_DIR/harness/PROJECT.md"
if "$INSTALL" "$PROJECT_DIR" >/dev/null 2>&1; then
  fail "installer accepted PROJECT.md directory"
fi
assert_not_file "$PROJECT_DIR/harness/HARNESS.md"

MCP_DIR="$TMP_ROOT/mcp-dir"
mkdir -p "$MCP_DIR/.cursor/mcp.json"
if "$INSTALL" "$MCP_DIR" >/dev/null 2>&1; then
  fail "installer accepted mcp.json directory"
fi
assert_not_file "$MCP_DIR/harness/HARNESS.md"

HOOKS_SYMLINK="$TMP_ROOT/hooks-symlink"
mkdir -p "$HOOKS_SYMLINK/.cursor"
printf '%s\n' '{"version":1,"hooks":{}}' >"$TMP_ROOT/external-hooks.json"
ln -s "$TMP_ROOT/external-hooks.json" "$HOOKS_SYMLINK/.cursor/hooks.json"
if "$INSTALL" "$HOOKS_SYMLINK" >/dev/null 2>&1; then
  fail "installer accepted hooks.json symlink"
fi
[ -L "$HOOKS_SYMLINK/.cursor/hooks.json" ] || fail "hooks.json symlink was replaced"
assert_not_file "$HOOKS_SYMLINK/harness/HARNESS.md"

MANIFEST_SYMLINK="$TMP_ROOT/manifest-symlink"
mkdir -p "$MANIFEST_SYMLINK/.cursor"
: >"$TMP_ROOT/external-manifest"
ln -s "$TMP_ROOT/external-manifest" "$MANIFEST_SYMLINK/.cursor/harness-install-manifest"
if "$INSTALL" "$MANIFEST_SYMLINK" >/dev/null 2>&1; then
  fail "installer accepted ownership-manifest symlink"
fi
[ ! -s "$TMP_ROOT/external-manifest" ] || fail "external manifest target was modified"
assert_not_file "$MANIFEST_SYMLINK/harness/HARNESS.md"

MALFORMED_MARKER="$TMP_ROOT/malformed-marker"
mkdir -p "$MALFORMED_MARKER"
cat >"$MALFORMED_MARKER/AGENTS.md" <<'EOF'
# Team rules
<!-- >>> harness-agents >>> -->
This content must survive.
EOF
if "$INSTALL" "$MALFORMED_MARKER" >/dev/null 2>&1; then
  fail "installer accepted an unmatched AGENTS.md marker"
fi
assert_contains "$MALFORMED_MARKER/AGENTS.md" "This content must survive."
assert_not_file "$MALFORMED_MARKER/harness/HARNESS.md"

if "$INSTALL" --claude --cursor-only "$TMP_ROOT/conflict" >/dev/null 2>&1; then
  fail "conflicting --claude --cursor-only options were accepted"
fi
if "$INSTALL" --check --uninstall "$TMP_ROOT/conflict" >/dev/null 2>&1; then
  fail "conflicting --check --uninstall modes were accepted"
fi

echo "PASS: all installer lifecycle tests"
