# AI Comm Init

AI 공통 설정 및 스킬 저장소

## 1. CLI 설치

```bash
# macOS/Linux
curl -fsSL https://claude.ai/install.sh | bash
curl -fsSL https://chatgpt.com/codex/install.sh | sh

git clone https://github.com/codestreamkr/ai-comm-init.git ~/.agents
```

```powershell
# Windows
irm https://claude.ai/install.ps1 | iex
irm https://chatgpt.com/codex/install.ps1 | iex

git clone https://github.com/codestreamkr/ai-comm-init.git $env:USERPROFILE\.agents
```

## 2. 스킬 배치

```bash
bash ~/.agents/install.sh          # 기존 파일 보존
bash ~/.agents/install.sh --force  # 기존 파일 백업 후 덮어쓰기
```

```powershell
& "$env:USERPROFILE\.agents\install.ps1"
& "$env:USERPROFILE\.agents\install.ps1" -Force
```

## 3. 설정 병합

Claude Code에 요청한다.

> `~/.agents/claude`의 설정을 검토하고 `~/.claude`에 병합·적용해줘. 기존 설정은 유지해줘.

Codex CLI에 요청한다.

> `~/.agents/codex/config.toml` 내용을 `~/.codex/config.toml`에 병합해줘. 기존 설정은 유지해줘.

## 4. 최신 정보 갱신

```bash
cd ~/.agents && git pull
bash install.sh --force
```

Windows 심볼릭 링크에는 개발자 모드 또는 관리자 권한이 필요하다.
실패 시 다시 시도할 수 있도록 안내한다.
