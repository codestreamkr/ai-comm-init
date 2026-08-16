#!/bin/bash
# Codex CLI Agents - macOS/Linux
# Usage: curl -fsSL https://raw.githubusercontent.com/codestreamkr/chatgpt-codex-init/main/install.sh | bash

set -euo pipefail

REPO_ARCHIVE_URL="${CODEX_INIT_ARCHIVE_URL:-https://github.com/codestreamkr/chatgpt-codex-init/archive/refs/heads/main.tar.gz}"
AGENTS_DIR="${AGENTS_HOME:-$HOME/.agents}"
CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"
SOURCE_DIR="${CODEX_INIT_SOURCE_DIR:-}"
TEMP_DIR=""
FORCE=false

if [ "${1:-}" = "--force" ]; then
    FORCE=true
elif [ "$#" -gt 0 ]; then
    echo "Usage: bash install.sh [--force]" >&2
    exit 2
fi

cleanup() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        rm -rf -- "$TEMP_DIR"
    fi
}
trap cleanup EXIT

download() {
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$1" -o "$2"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$2" "$1"
    else
        echo "curl or wget is required." >&2
        exit 1
    fi
}

backup_path() {
    printf '%s.backup-%s' "$1" "$(date +%Y%m%d%H%M%S)"
}

install_item() {
    source_path="$1"
    target_path="$2"
    label="$3"

    if [ -e "$target_path" ]; then
        if [ "$FORCE" != true ]; then
            echo "  skipped existing: $label"
            return
        fi

        backup="$(backup_path "$target_path")"
        mv -- "$target_path" "$backup"
        echo "  backed up: $backup"
    fi

    cp -R -- "$source_path" "$target_path"
    echo "  installed: $label"
}

echo "[1/4] Checking Codex CLI ..."
if command -v codex >/dev/null 2>&1; then
    echo "  already installed: $(command -v codex)"
else
    echo "  installing with the official OpenAI installer ..."
    TEMP_DIR="$(mktemp -d)"
    official_installer="$TEMP_DIR/codex-install.sh"
    download "https://chatgpt.com/codex/install.sh" "$official_installer"
    sh "$official_installer"
fi

echo "[2/4] Preparing installation source ..."
if [ -z "$SOURCE_DIR" ]; then
    if [ -z "$TEMP_DIR" ]; then
        TEMP_DIR="$(mktemp -d)"
    fi
    archive="$TEMP_DIR/repository.tar.gz"
    extract_dir="$TEMP_DIR/repository"
    mkdir -p "$extract_dir"
    download "$REPO_ARCHIVE_URL" "$archive"
    tar -xzf "$archive" -C "$extract_dir" --strip-components=1
    SOURCE_DIR="$extract_dir"
fi

if [ ! -d "$SOURCE_DIR/skills" ] || [ ! -f "$SOURCE_DIR/config.user.toml" ]; then
    echo "Invalid installation source: $SOURCE_DIR" >&2
    exit 1
fi

echo "[3/4] Installing Skills ..."
mkdir -p "$AGENTS_DIR/skills"
for skill in "$SOURCE_DIR"/skills/*; do
    [ -d "$skill" ] || continue
    name="$(basename "$skill")"
    install_item "$skill" "$AGENTS_DIR/skills/$name" "skills/$name"
done

echo "[4/4] Installing config template ..."
mkdir -p "$CODEX_DIR"
install_item "$SOURCE_DIR/config.user.toml" "$CODEX_DIR/config.user.toml" "config.user.toml"

echo ""
echo "Done."
echo "  Skills: $AGENTS_DIR/skills"
echo "  Config template: $CODEX_DIR/config.user.toml"
echo "  Next: ask Codex to merge only the defined keys into $CODEX_DIR/config.toml."
