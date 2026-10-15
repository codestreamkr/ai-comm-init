#!/bin/bash
# AI Comm Init - macOS/Linux
# Usage: bash install.sh [--force]
# 저장소를 clone 한 뒤 저장소 안에서 실행한다.

set -euo pipefail

SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_DIR="${AGENTS_HOME:-$HOME/.agents}"
CLAUDE_DIR="${CLAUDE_HOME:-$HOME/.claude}"
CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"
GROK_DIR="${GROK_HOME:-$HOME/.grok}"
GEMINI_DIR="${GEMINI_HOME:-$HOME/.gemini}"
PI_DIR="${PI_HOME:-$HOME/.pi/agent}"
FORCE=false

# Native Claude installations may not yet be on the calling shell's PATH.
if ! command -v claude >/dev/null 2>&1 && [ -x "$HOME/.local/bin/claude" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

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
    local source_path="$1" target_path="$2" label="$3"
    local backup

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
    local source_path="$1" target_path="$2" label="$3"
    local backup current

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

remove_stale_skills() {
    local target_skills="$1" agents_skills="$2"
    local target name backup

    [ -d "$target_skills" ] || return 0

    for target in "$target_skills"/*; do
        [ -e "$target" ] || [ -L "$target" ] || continue
        name="$(basename "$target")"
        case "$name" in *.backup-*) continue ;; esac
        case "$name" in ct-*) ;; *) continue ;; esac
        if [ -d "$agents_skills/$name" ]; then
            continue
        fi

        if [ -L "$target" ]; then
            rm -- "$target"
            echo "  removed stale link: skills/$name"
        elif [ "$FORCE" = true ]; then
            backup="$(backup_path "$target")"
            mv -- "$target" "$backup"
            echo "  backed up stale: $backup"
        else
            echo "  skipped stale (not a link): skills/$name"
        fi
    done
}

for required in skills claude codex agy; do
    if [ ! -d "$SOURCE_DIR/$required" ]; then
        echo "Invalid installation source: $SOURCE_DIR (missing $required/)" >&2
        exit 1
    fi
done

echo "[1/2] Installing source files ..."
if [ "$SOURCE_DIR" = "$AGENTS_DIR" ]; then
    echo "  source is already $AGENTS_DIR"
else
    mkdir -p "$AGENTS_DIR/skills"
    for skill in "$SOURCE_DIR"/skills/*; do
        [ -d "$skill" ] || continue
        name="$(basename "$skill")"
        install_item "$skill" "$AGENTS_DIR/skills/$name" "skills/$name" > /dev/null
    done
    for runtime in claude codex agy grok pi; do
        [ -d "$SOURCE_DIR/$runtime" ] || continue
        install_item "$SOURCE_DIR/$runtime" "$AGENTS_DIR/$runtime" "$runtime" > /dev/null
    done
fi

# A settings directory alone does not prove that a CLI is installed.
link_runtime() {
    local label="$1" source_dir="$2" runtime_home="$3" instructions="$4"
    shift 4
    local installed=false command_name skill name
    for command_name in "$@"; do
        if command -v "$command_name" >/dev/null 2>&1; then
            installed=true
            break
        fi
    done
    if [ "$installed" != true ]; then
        echo "  skipped: $label (CLI not found in PATH)"
        return
    fi

    mkdir -p "$runtime_home/skills"
    if [ -f "$AGENTS_DIR/$source_dir/$instructions" ]; then
        link_item "$AGENTS_DIR/$source_dir/$instructions" "$runtime_home/$instructions" "$label/$instructions" > /dev/null
    else
        echo "  skipped: $source_dir/$instructions not found"
    fi
    for skill in "$AGENTS_DIR"/skills/*; do
        [ -d "$skill" ] || continue
        name="$(basename "$skill")"
        case "$name" in *.backup-*) continue ;; esac
        link_item "$skill" "$runtime_home/skills/$name" "$label/skills/$name" > /dev/null
    done
    remove_stale_skills "$runtime_home/skills" "$AGENTS_DIR/skills" > /dev/null
    if [ "$source_dir" = grok ] && [ -f "$AGENTS_DIR/grok/statusline.js" ]; then
        link_item "$AGENTS_DIR/grok/statusline.js" "$runtime_home/statusline.js" "grok/statusline.js" > /dev/null
    fi
    echo "  완료: $label"
}

echo "[2/2] Detecting installed AI CLIs and linking instructions and skills ..."
link_runtime "Claude Code" claude "$CLAUDE_DIR" CLAUDE.md claude
link_runtime "Codex" codex "$CODEX_DIR" AGENTS.md codex
link_runtime "Antigravity / Gemini" agy "$GEMINI_DIR/config" GEMINI.md agy antigravity gemini
link_runtime "Grok" grok "$GROK_DIR" AGENTS.md grok
link_runtime "Pi" pi "$PI_DIR" AGENTS.md pi

echo ""
echo "Done. Source: $AGENTS_DIR"
echo "Existing files are preserved; use --force to back them up and replace them with links."
echo "Machine-local settings.json and config.toml files must be reviewed and merged separately."
