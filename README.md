# AI Comm Init

AI 공통 설정 및 스킬 저장소

## 1. CLI 설치

```bash
# macOS/Linux
curl -fsSL https://claude.ai/install.sh | bash
curl -fsSL https://chatgpt.com/codex/install.sh | sh
curl -fsSL https://antigravity.google/cli/install.sh | bash

git clone https://github.com/codestreamkr/ai-comm-init.git ~/.agents
```

```powershell
# Windows
irm https://claude.ai/install.ps1 | iex
irm https://chatgpt.com/codex/install.ps1 | iex
irm https://antigravity.google/cli/install.ps1 | iex

git clone https://github.com/codestreamkr/ai-comm-init.git $env:USERPROFILE\.agents
```

정본은 이 저장소(`~/.agents`)다. `~/.claude`, `~/.codex`, `~/.grok`, `~/.gemini`, `~/.pi/agent`는 정본을 가져다 쓰는 런타임 홈이다.

## 2. 스킬 배치

```bash
bash ~/.agents/install.sh          # 기존 파일 보존
bash ~/.agents/install.sh --force  # 기존 파일 백업 후 덮어쓰기
```

```powershell
& "$env:USERPROFILE\.agents\install.ps1"
& "$env:USERPROFILE\.agents\install.ps1" -Force
```

설치는 `~/.claude/skills` 및 `~/.gemini/config/skills`에 스킬을 링크하고, Grok의 `statusline.js`와 `AGENTS.md`를 `~/.grok`에 링크한다.

## 3. 전역 설정 적용

전역 지침 Markdown 파일은 저장소 파일을 정본으로 두고 심볼릭 링크로 연결한다. 기존 파일이 있으면 내용을 확인하고 백업한 뒤 연결한다. Grok 지침은 설치 스크립트가 링크하며, 나머지 전역 지침은 각각 직접 적용한다.

| 저장소 파일 | 링크 위치 |
| --- | --- |
| `~/.agents/claude/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `~/.agents/codex/AGENTS.md` | `~/.codex/AGENTS.md` |
| `~/.agents/agy/GEMINI.md` | `~/.gemini/config/GEMINI.md` |
| `~/.agents/pi/AGENTS.md` | `~/.pi/agent/AGENTS.md` |
| `~/.agents/grok/AGENTS.md` | `~/.grok/AGENTS.md` |

기존 값이나 로컬 변경을 유지해야 하는 설정·스크립트는 링크로 교체하지 않고 검토 후 병합한다. 각 CLI에 요청할 수 있다.

- Claude Code: `~/.agents/claude/settings.json`과 `statusline.js`를 `~/.claude`의 기존 파일에 병합해줘.
- Codex CLI: `~/.agents/codex/config.toml`을 `~/.codex/config.toml`에 병합해줘.
- Antigravity (agy): `~/.agents/agy/settings.json`을 해당 런타임 설정에 병합해줘.
- Pi: `~/.agents/pi/settings.json`을 `~/.pi/agent/settings.json`에 병합해줘.

병합 시 기존 설정을 유지한다. Pi는 `~/.agents/skills`의 스킬을 자동으로 발견하므로 별도 링크가 필요 없다.

파일 전체를 정본으로 관리하는 Grok `statusline.js`는 설치 스크립트가 `~/.grok/statusline.js`에 링크한다. Grok 전역 지침은 별도 `AGENTS.md`로 관리해 나중에 Claude 지침과 독립적으로 수정할 수 있다. Grok `config.toml`과 훅은 머신 로컬이다. 상태줄 `command`는 연결된 `~/.grok/statusline.js`를 실행하면 된다.

## 4. 최신 정보 갱신

```bash
cd ~/.agents && git pull
bash install.sh --force
```

설치는 `~/.claude/skills` 및 `~/.gemini/config/skills`에서 저장소에 없는 `ct-*` 링크를 정리한다.

Windows 심볼릭 링크에는 개발자 모드 또는 관리자 권한이 필요하다.
실패 시 다시 시도할 수 있도록 안내한다.
