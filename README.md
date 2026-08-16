# Codex CLI Agents

Codex CLI와 사용자 공용 Skill을 한 번에 구성하기 위한 저장소다.

## 포함 항목

- `skills/`: `$HOME/.agents/skills`에 설치되는 `ct-*` Skill
- `config.user.toml`: `$HOME/.codex/config.user.toml`에 복사되는 사용자 설정 템플릿
- `install.sh`: macOS/Linux 설치 스크립트
- `install.ps1`: Windows PowerShell 설치 스크립트

## 설치

Codex CLI가 없으면 OpenAI 공식 설치기로 먼저 설치한다. 이미 설치되어 있으면 해당 단계는 건너뛴다.

### macOS/Linux

```bash
curl -fsSL https://raw.githubusercontent.com/codestreamkr/chatgpt-codex-init/main/install.sh | bash
```

### Windows PowerShell

```powershell
irm https://raw.githubusercontent.com/codestreamkr/chatgpt-codex-init/main/install.ps1 | iex
```

설치기는 기존 Skill과 `config.user.toml`을 덮어쓰지 않는다. 저장소 버전으로 갱신하려면 설치 파일을 내려받아 macOS/Linux에서는 `--force`, Windows에서는 `-Force` 옵션으로 실행한다. 이 경우 기존 항목은 타임스탬프가 붙은 이름으로 백업한다.

## 설정 적용

설치 후 Codex에 다음과 같이 요청한다.

> `~/.codex/config.user.toml`에 정의된 키만 실제 `~/.codex/config.toml`에 병합해 줘. 정의되지 않은 기존 설정은 보존해 줘.

`config.toml`은 사용자별 로컬 설정이므로 저장소나 설치 스크립트가 직접 덮어쓰지 않는다.

## 저장소 관리

관리자는 이 저장소를 `$HOME/.agents`에 clone하여 Skill과 템플릿을 Git으로 관리한다. 일반 사용자 설치에는 clone이나 이후 Git 관리가 필요하지 않다.

자세한 활용 방법은 [CodeStream Codex 가이드](https://github.com/codestreamkr/docs/tree/main/Platforms/Codex)를 참고한다.
