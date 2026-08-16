# Codex CLI Agents - Windows PowerShell
# Usage: irm https://raw.githubusercontent.com/codestreamkr/chatgpt-codex-init/main/install.ps1 | iex

param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$RepoArchiveUrl = if ($env:CODEX_INIT_ARCHIVE_URL) {
    $env:CODEX_INIT_ARCHIVE_URL
} else {
    "https://github.com/codestreamkr/chatgpt-codex-init/archive/refs/heads/main.zip"
}
$AgentsDir = if ($env:AGENTS_HOME) { $env:AGENTS_HOME } else { Join-Path $env:USERPROFILE ".agents" }
$CodexDir = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE ".codex" }
$SourceDir = $env:CODEX_INIT_SOURCE_DIR
$TempDir = $null

function Get-BackupPath {
    param([string]$Path)
    return "$Path.backup-$(Get-Date -Format 'yyyyMMddHHmmss')"
}

function Install-ItemPreservingExisting {
    param(
        [string]$Source,
        [string]$Target,
        [string]$Label
    )

    if (Test-Path $Target) {
        if (-not $Force) {
            Write-Host "  skipped existing: $Label"
            return
        }

        $Backup = Get-BackupPath -Path $Target
        Move-Item $Target $Backup
        Write-Host "  backed up: $Backup"
    }

    Copy-Item $Source $Target -Recurse
    Write-Host "  installed: $Label"
}

try {
    Write-Host "[1/4] Checking Codex CLI ..." -ForegroundColor Cyan
    $CodexCommand = Get-Command codex -ErrorAction SilentlyContinue
    if ($CodexCommand) {
        Write-Host "  already installed: $($CodexCommand.Source)"
    } else {
        Write-Host "  installing with the official OpenAI installer ..."
        Invoke-RestMethod "https://chatgpt.com/codex/install.ps1" | Invoke-Expression
    }

    Write-Host "[2/4] Preparing installation source ..." -ForegroundColor Cyan
    if (-not $SourceDir) {
        $TempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-agents-" + [guid]::NewGuid().ToString("N"))
        $Archive = Join-Path $TempDir "repository.zip"
        $ExtractDir = Join-Path $TempDir "repository"
        New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
        Invoke-WebRequest -Uri $RepoArchiveUrl -OutFile $Archive
        Expand-Archive -Path $Archive -DestinationPath $ExtractDir
        $SourceDir = (Get-ChildItem $ExtractDir -Directory | Select-Object -First 1).FullName
    }

    if (-not (Test-Path (Join-Path $SourceDir "skills")) -or -not (Test-Path (Join-Path $SourceDir "config.user.toml"))) {
        throw "Invalid installation source: $SourceDir"
    }

    Write-Host "[3/4] Installing Skills ..." -ForegroundColor Cyan
    $SkillsDir = Join-Path $AgentsDir "skills"
    New-Item -ItemType Directory -Path $SkillsDir -Force | Out-Null
    Get-ChildItem (Join-Path $SourceDir "skills") -Directory | ForEach-Object {
        Install-ItemPreservingExisting -Source $_.FullName -Target (Join-Path $SkillsDir $_.Name) -Label "skills/$($_.Name)"
    }

    Write-Host "[4/4] Installing config template ..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $CodexDir -Force | Out-Null
    Install-ItemPreservingExisting `
        -Source (Join-Path $SourceDir "config.user.toml") `
        -Target (Join-Path $CodexDir "config.user.toml") `
        -Label "config.user.toml"

    Write-Host ""
    Write-Host "Done." -ForegroundColor Green
    Write-Host "  Skills: $SkillsDir"
    Write-Host "  Config template: $(Join-Path $CodexDir 'config.user.toml')"
    Write-Host "  Next: ask Codex to merge only the defined keys into $(Join-Path $CodexDir 'config.toml')."
}
finally {
    if ($TempDir -and (Test-Path $TempDir)) {
        Remove-Item $TempDir -Recurse -Force
    }
}
