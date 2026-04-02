Param()

$ErrorActionPreference = "Stop"

$repoUrl = "https://github.com/fightmin/chatgpt-codex-init.git"
$targetRoot = Join-Path $HOME ".codex"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$agentsPath = Join-Path $targetRoot "AGENTS.md"
$tempClonePath = Join-Path $env:TEMP ("codex-init-" + [guid]::NewGuid().ToString("N"))
$gitPath = Join-Path $targetRoot ".git"
$sourceAgentsPath = Join-Path $tempClonePath "AGENTS.md"
$sourceSkillsPath = Join-Path $tempClonePath "skills"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  throw "git 명령을 찾을 수 없습니다. Git 설치 후 다시 실행하세요."
}

function Backup-And-RemoveIfExists {
  param([string]$Path)

  if (Test-Path -LiteralPath $Path) {
    $backupPath = "${Path}_backup_${timestamp}"
    Copy-Item -LiteralPath $Path -Destination $backupPath -Force
    Remove-Item -LiteralPath $Path -Force
    Write-Output "Backup created: $backupPath"
  }
}

try {
  git clone $repoUrl $tempClonePath

  if (-not (Test-Path -LiteralPath $targetRoot)) {
    New-Item -Path $targetRoot -ItemType Directory | Out-Null
  }

  Backup-And-RemoveIfExists -Path $agentsPath

  if (Test-Path -LiteralPath $gitPath) {
    $gitBackupPath = Join-Path $targetRoot (".git_backup_" + $timestamp)
    Move-Item -LiteralPath $gitPath -Destination $gitBackupPath -Force
    Write-Output "Backup created: $gitBackupPath"
  }

  Copy-Item -LiteralPath $sourceAgentsPath -Destination $agentsPath -Force

  if (Test-Path -LiteralPath (Join-Path $targetRoot "skills")) {
    Remove-Item -LiteralPath (Join-Path $targetRoot "skills") -Recurse -Force
  }
  Copy-Item -LiteralPath $sourceSkillsPath -Destination (Join-Path $targetRoot "skills") -Recurse -Force

  Write-Output "Applied templates to: $targetRoot"
}
finally {
  if (Test-Path -LiteralPath $tempClonePath) {
    Remove-Item -LiteralPath $tempClonePath -Recurse -Force
  }
}

Write-Output "Done. Run 'codex' and login again (auth.json is user-specific)."
