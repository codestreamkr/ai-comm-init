# ChatGPT Codex Init

## 개요
새로운 PC에서 동일한 Codex 환경을 구성하기 위한 가이드.  

https://github.com/fightmin/chatgpt-codex-init.git

## 1단계: Codex 설치
```javascript
# Windows (PowerShell)
npm install -g @openai/codex
codex --version

# Mac/Linux
npm install -g @openai/codex
codex --version
```

## 2단계: install 스크립트 실행
```javascript
# Windows (PowerShell)
irm https://raw.githubusercontent.com/fightmin/chatgpt-codex-init/main/install.ps1 | iex

# Mac/Linux
curl -fsSL https://raw.githubusercontent.com/fightmin/chatgpt-codex-init/main/install.sh | bash
```

## 3단계: 설정 파일 확인
설치 스크립트 동작 요약:
- 저장소를 임시 폴더에 먼저 clone
- `~/.codex`가 이미 있어도 필요한 파일만 복사 적용
- 기존 `.git`이 있으면 `.git_backup_YYYYMMDD-HHMMSS`로 백업
- `AGENTS.md`는 있으면 `_backup_YYYYMMDD-HHMMSS` 파일로 백업 후 적용
- 백업할 파일이 없어도 에러 없이 진행

적용되는 핵심 파일:
- `AGENTS.md`
- `skills/`

## 4단계: config.toml 설정 추가
`~/.codex/config.toml` 파일 아래에 필요 항목만 직접 추가한다.

```toml
[tui]
status_line = ["model-with-reasoning", "five-hour-limit", "context-window-size", "weekly-limit", "context-used"]

[mcp_servers.playwright]
command = "npx"
args = ["@playwright/mcp@latest"]

[mcp_servers.context7]
command = "npx"
args = ["-y", "@upstash/context7-mcp"]

[mcp_servers.notion]
url = "https://mcp.notion.com/mcp"

[mcp_servers.figma]
url = "https://mcp.figma.com/mcp"

[mcp_servers.linear]
url = "https://mcp.linear.app/mcp"
```

## 5단계: 인증
```javascript
codex
```
`auth.json`은 사용자별 인증 파일이므로 Git으로 관리하지 않는다.

## 6단계: 설정 변경 후 동기화
```javascript
# 이 저장소를 수정하려면 별도 작업 디렉토리에서 clone 후 변경/배포한다.
```

