# AI Comm Init - Windows PowerShell
# Usage: .\install.ps1 [-Force]
# 저장소를 clone 한 뒤 저장소 안에서 실행한다.

param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$SourceDir = $PSScriptRoot
$AgentsDir = if ($env:AGENTS_HOME) { $env:AGENTS_HOME } else { Join-Path $env:USERPROFILE ".agents" }
$ClaudeDir = if ($env:CLAUDE_HOME) { $env:CLAUDE_HOME } else { Join-Path $env:USERPROFILE ".claude" }
$CodexDir  = if ($env:CODEX_HOME)  { $env:CODEX_HOME }  else { Join-Path $env:USERPROFILE ".codex" }

function Get-BackupPath {
    param([string]$Path)
    return "$Path.backup-$(Get-Date -Format 'yyyyMMddHHmmss')"
}

function Clear-ExistingTarget {
    param(
        [string]$Target,
        [string]$Label
    )

    if (-not (Test-Path $Target)) {
        return $true
    }

    if (-not $Force) {
        Write-Host "  skipped existing: $Label"
        return $false
    }

    $Backup = Get-BackupPath -Path $Target
    Move-Item -LiteralPath $Target -Destination $Backup
    Write-Host "  backed up: $Backup"
    return $true
}

function Install-Item {
    param(
        [string]$Source,
        [string]$Target,
        [string]$Label
    )

    if (-not (Clear-ExistingTarget -Target $Target -Label $Label)) { return }

    Copy-Item -LiteralPath $Source -Destination $Target -Recurse
    Write-Host "  installed: $Label"
}

function Install-Link {
    param(
        [string]$Source,
        [string]$Target,
        [string]$Label
    )

    $Existing = Get-Item -LiteralPath $Target -ErrorAction SilentlyContinue
    if ($Existing -and $Existing.LinkType -eq "SymbolicLink" -and $Existing.Target -contains $Source) {
        Write-Host "  already linked: $Label"
        return
    }

    if (-not (Clear-ExistingTarget -Target $Target -Label $Label)) { return }

    try {
        New-Item -ItemType SymbolicLink -Path $Target -Target $Source -ErrorAction Stop | Out-Null
        Write-Host "  linked: $Label"
    } catch {
        Copy-Item -LiteralPath $Source -Destination $Target -Recurse
        Write-Host "  copied (symlink unavailable): $Label"
        $script:SymlinkFallback = $true
    }
}

function Remove-StaleClaudeSkills {
    param(
        [string]$ClaudeSkillsDir,
        [string]$AgentsSkillsDir
    )

    if (-not (Test-Path $ClaudeSkillsDir)) {
        return
    }

    Get-ChildItem $ClaudeSkillsDir | ForEach-Object {
        $Name = $_.Name
        if ($Name -like "*.backup-*") { return }
        if ($Name -notlike "ct-*") { return }
        if (Test-Path (Join-Path $AgentsSkillsDir $Name)) { return }

        if ($_.LinkType -eq "SymbolicLink") {
            Remove-Item -LiteralPath $_.FullName
            Write-Host "  removed stale link: skills\$Name"
        } elseif ($Force) {
            $Backup = Get-BackupPath -Path $_.FullName
            Move-Item -LiteralPath $_.FullName -Destination $Backup
            Write-Host "  backed up stale: $Backup"
        } else {
            Write-Host "  skipped stale (not a link): skills\$Name"
        }
    }
}

$script:SymlinkFallback = $false

foreach ($Required in @("skills", "claude", "codex")) {
    if (-not (Test-Path (Join-Path $SourceDir $Required))) {
        throw "Invalid installation source: $SourceDir (missing $Required\)"
    }
}

Write-Host "[1/2] Installing Skills ..." -ForegroundColor Cyan
$AgentsSkillsDir = Join-Path $AgentsDir "skills"
if ($SourceDir -eq $AgentsDir) {
    Write-Host "  source is already $AgentsDir"
} else {
    New-Item -ItemType Directory -Path $AgentsSkillsDir -Force | Out-Null
    Get-ChildItem (Join-Path $SourceDir "skills") -Directory | ForEach-Object {
        Install-Item -Source $_.FullName -Target (Join-Path $AgentsSkillsDir $_.Name) -Label "skills\$($_.Name)"
    }
}

Write-Host "[2/2] Linking Skills into Claude Code ..." -ForegroundColor Cyan
$ClaudeSkillsDir = Join-Path $ClaudeDir "skills"
New-Item -ItemType Directory -Path $ClaudeSkillsDir -Force | Out-Null
Get-ChildItem $AgentsSkillsDir -Directory | Where-Object { $_.Name -notlike "*.backup-*" } | ForEach-Object {
    Install-Link -Source $_.FullName -Target (Join-Path $ClaudeSkillsDir $_.Name) -Label "skills\$($_.Name)"
}
Remove-StaleClaudeSkills -ClaudeSkillsDir $ClaudeSkillsDir -AgentsSkillsDir $AgentsSkillsDir

Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host "  Skills: $AgentsSkillsDir"
Write-Host ""
Write-Host "Next:"
Write-Host "  - Claude Code: ask to review and merge $(Join-Path $SourceDir 'claude') into $ClaudeDir."
Write-Host "  - Codex: ask to merge $(Join-Path $SourceDir 'codex\config.toml') into $(Join-Path $CodexDir 'config.toml')."

if ($script:SymlinkFallback) {
    Write-Host ""
    Write-Host "Note: symbolic links were unavailable, so Skills were copied." -ForegroundColor Yellow
    Write-Host "      Enable Developer Mode or run as administrator, then rerun to link them."
}
