#!/bin/bash
# AI Comm Init - macOS/Linux
# Usage: bash install.sh [--force]
# 저장소를 clone 한 뒤 저장소 안에서 실행한다.

set -euo pipefail

SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_DIR="${AGENTS_HOME:-$HOME/.agents}"
CLAUDE_DIR="${CLAUDE_HOME:-$HOME/.claude}"
CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"
FORCE=false

if [ "${1:-}" = "--force" ]; then
    FORCE=true
elif [ "$#" -gt 0 ]; then
    echo "Usage: bash install.sh [--force]" >&2
    exit 2
fi

backup_path() {
    printf '%s.backup-%s' "$1" "$(date +%Y%m%d%H%M%S)"
}

install_item() {
    source_path="$1"
    target_path="$2"
    label="$3"

    if [ -e "$target_path" ] || [ -L "$target_path" ]; then
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

link_item() {
    source_path="$1"
    target_path="$2"
    label="$3"

    if [ -L "$target_path" ]; then
        current="$(readlink -- "$target_path")"
        if [ "$current" = "$source_path" ]; then
            echo "  already linked: $label"
            return
        fi
    fi

    if [ -e "$target_path" ] || [ -L "$target_path" ]; then
        if [ "$FORCE" != true ]; then
            echo "  skipped existing: $label"
            return
        fi

        backup="$(backup_path "$target_path")"
        mv -- "$target_path" "$backup"
        echo "  backed up: $backup"
    fi

    ln -s -- "$source_path" "$target_path"
    echo "  linked: $label"
}

for required in skills claude codex; do
    if [ ! -d "$SOURCE_DIR/$required" ]; then
        echo "Invalid installation source: $SOURCE_DIR (missing $required/)" >&2
        exit 1
    fi
done

echo "[1/2] Installing Skills ..."
if [ "$SOURCE_DIR" = "$AGENTS_DIR" ]; then
    echo "  source is already $AGENTS_DIR"
else
    mkdir -p "$AGENTS_DIR/skills"
    for skill in "$SOURCE_DIR"/skills/*; do
        [ -d "$skill" ] || continue
        name="$(basename "$skill")"
        install_item "$skill" "$AGENTS_DIR/skills/$name" "skills/$name"
    done
fi

echo "[2/2] Linking Skills into Claude Code ..."
mkdir -p "$CLAUDE_DIR/skills"
for skill in "$AGENTS_DIR"/skills/*; do
    [ -d "$skill" ] || continue
    name="$(basename "$skill")"
    case "$name" in *.backup-*) continue ;; esac
    link_item "$skill" "$CLAUDE_DIR/skills/$name" "skills/$name"
done

echo ""
echo "Done."
echo "  Skills: $AGENTS_DIR/skills"
echo ""
echo "Next:"
echo "  - Claude Code: ask to review and merge $SOURCE_DIR/claude into $CLAUDE_DIR."
echo "  - Codex: ask to merge $SOURCE_DIR/codex/config.toml into $CODEX_DIR/config.toml."
