#!/bin/bash
# ChatGPT Codex Init - Mac/Linux
# Usage: git clone https://github.com/fightmin/chatgpt-codex-init.git /tmp/codex-init && bash /tmp/codex-init/install.sh

set -e

REPO="${1:-https://github.com/fightmin/chatgpt-codex-init.git}"
CODEX_DIR="$HOME/.codex"
TEMP_DIR=""

cleanup() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

get_mcp_config() {
    local name="$1"
    codex mcp get "$name" 2>/dev/null || true
}

register_stdio_mcp() {
    local name="$1"
    local command="$2"
    shift 2
    local args="$*"
    local current

    current="$(get_mcp_config "$name")"
    if printf '%s\n' "$current" | grep -Fq "transport: stdio" \
        && printf '%s\n' "$current" | grep -Fq "command: $command" \
        && printf '%s\n' "$current" | grep -Fq "args: $args"; then
        echo "  already configured: $name"
        return
    fi

    if [ -n "$current" ]; then
        codex mcp remove "$name" >/dev/null 2>&1 || true
    fi

    if codex mcp add "$name" -- "$command" "$@"; then
        echo "  registered: $name"
    else
        echo "  skipped: $name"
    fi
}

register_http_mcp() {
    local name="$1"
    local url="$2"
    local current

    current="$(get_mcp_config "$name")"
    if printf '%s\n' "$current" | grep -Fq "transport: streamable_http" \
        && printf '%s\n' "$current" | grep -Fq "url: $url"; then
        echo "  already configured: $name"
        return
    fi

    if [ -n "$current" ]; then
        codex mcp remove "$name" >/dev/null 2>&1 || true
    fi

    if codex mcp add "$name" --url "$url"; then
        echo "  registered: $name"
    else
        echo "  skipped: $name"
    fi
}

echo "[1/4] Preparing ~/.codex/ ..."
if [ ! -d "$CODEX_DIR" ]; then
    mkdir -p "$CODEX_DIR"
    echo "  ~/.codex/ created"
else
    echo "  ~/.codex/ already exists"
fi

echo "[2/4] Connecting git repo..."
if [ -d "$CODEX_DIR/.git" ]; then
    cd "$CODEX_DIR"
    existing=$(git remote get-url origin 2>/dev/null || true)
    if [ -z "$existing" ]; then
        git remote add origin "$REPO"
    elif [ "$existing" != "$REPO" ]; then
        git remote set-url origin "$REPO"
    fi
    git fetch origin
    git reset --hard origin/main
    echo "  updated to latest"
else
    if [ -e "$CODEX_DIR/AGENTS.md" ]; then
        mv "$CODEX_DIR/AGENTS.md" "$CODEX_DIR/AGENTS.md~backup"
        echo "  backed up: AGENTS.md -> AGENTS.md~backup"
    fi

    TEMP_DIR="$(mktemp -d)"
    git clone "$REPO" "$TEMP_DIR"
    mv "$TEMP_DIR/.git" "$CODEX_DIR/.git"

    cd "$CODEX_DIR"
    git reset --hard HEAD
    echo "  cloned and applied"
fi

echo "[3/4] Registering MCP servers..."
if command -v codex >/dev/null 2>&1; then
    register_stdio_mcp "playwright" npx -y @playwright/mcp@latest
    register_stdio_mcp "context7" npx -y @upstash/context7-mcp
    register_http_mcp "notion" "https://mcp.notion.com/mcp"
    register_http_mcp "figma" "https://mcp.figma.com/mcp"
else
    echo "  skipped (codex not found)"
fi

echo "[4/4] Verifying..."
echo ""
echo "Installed files:"
for f in AGENTS.md .gitignore config.toml; do
    [ -f "$CODEX_DIR/$f" ] && echo "  + $f"
done
find "$CODEX_DIR/skills" -type f 2>/dev/null | while read -r file; do
    echo "  + ${file#$CODEX_DIR/}"
done

echo ""
echo "Done!"
echo "  Location: $CODEX_DIR"
echo "  Push changes: cd $CODEX_DIR && git add -A && git commit -m 'update' && git push"
echo ""
echo "Next: run 'codex' to authenticate and verify."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
case "$SCRIPT_DIR" in
    /tmp/*)
        rm -rf "$SCRIPT_DIR"
        ;;
esac
