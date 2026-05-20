# ChatGPT Codex Init

새로운 PC에서 동일한 ChatGPT Codex 환경을 구성하기 위한 가이드.
설정 파일은 GitHub에서 관리하며, 설치 스크립트로 한 줄 설치 가능하다.

https://github.com/codestreamkr/chatgpt-codex-init

## 1단계: Codex 설치

### Windows (PowerShell)
```powershell
npm install -g @openai/codex
git clone https://github.com/codestreamkr/chatgpt-codex-init.git $env:TEMP\codex-init; & $env:TEMP\codex-init\install.ps1
```

### Mac/Linux
```bash
npm install -g @openai/codex
git clone https://github.com/codestreamkr/chatgpt-codex-init.git /tmp/codex-init && bash /tmp/codex-init/install.sh
```

## 2단계: 설치 결과 확인

설치 스크립트는 단순 파일 복사가 아니라, `~/.codex/`를 이 저장소와 연결된 git 저장소로 만든다.

**설치 방식**

1. 임시 경로에 저장소를 clone
2. `.git`만 `~/.codex/`로 이동
3. `~/.codex/`에서 `git reset --hard`로 파일 배포
4. 설치 중 `codex mcp add`로 MCP 서버 등록

결과적으로 `~/.codex/` 자체가 git 저장소가 된다. 원격 origin은 이 GitHub 저장소를 가리킨다.

**설치 후 적용되는 파일**

- `AGENTS.md`
- `skills/`
- MCP 서버: `playwright`, `context7`

`skills/` 아래 스킬은 `ct-` 네임스페이스를 기준으로 관리한다.
현재 저장소가 제공하는 스킬도 모두 `ct-*` 이름을 사용한다.

## 주의사항

### 기존 파일 백업

`~/.codex/`가 git 저장소가 아닌 상태에서 설치하면, 아래 파일이 있을 경우 자동으로 백업된다.

- `AGENTS.md` → `AGENTS.md~backup`

`skills/`는 별도 백업하지 않는다. 이 저장소의 스킬은 `ct-` 네임스페이스를 사용하므로, 기존에 같은 이름의 `ct-*` 스킬이 있다면 설치본으로 갱신된다고 보는 편이 맞다. 반대로 이름이 겹치지 않는 사용자 스킬 파일은 그대로 남는다.

기존 설정을 유지하려면 `AGENTS.md~backup`만 확인해서 필요한 내용을 병합하면 된다.

이미 git 저장소로 관리 중인 경우에는 백업 없이 `git fetch origin && git reset --hard origin/main`으로 최신 상태로 업데이트된다.

### config.toml

`config.toml`은 저장소에서 직접 덮어쓰지 않는다.
대신 설치 중 `codex mcp add`를 실행해 필요한 MCP 설정만 로컬 `~/.codex/config.toml`에 등록한다.
이미 같은 MCP 설정이 등록돼 있으면 재등록하지 않으므로, OAuth 화면도 다시 띄우지 않는다.

### 인증

설치 후 `codex`를 실행해 다시 로그인해야 할 수 있다.

```bash
codex
```

`auth.json`은 사용자별 인증 파일이므로 Git으로 관리하지 않는다.

## 3단계: 설정 변경 후 동기화

`~/.codex/`가 git 저장소이므로, 로컬에서 설정을 바꾼 뒤 바로 push해 다른 PC와 동기화할 수 있다.

```bash
# Windows
cd $HOME/.codex && git add -A && git commit -m "update" && git push

# Mac/Linux
cd ~/.codex && git add -A && git commit -m "update" && git push
```
