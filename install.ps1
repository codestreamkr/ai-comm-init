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
$GrokDir   = if ($env:GROK_HOME)   { $env:GROK_HOME }   else { Join-Path $env:USERPROFILE ".grok" }

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
        [string]$Label,
        [scriptblock]$Fallback
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
        if ($Fallback) {
            & $Fallback
            Write-Host "  stubbed (symlink unavailable): $Label"
        } else {
            Copy-Item -LiteralPath $Source -Destination $Target -Recurse
            Write-Host "  copied (symlink unavailable): $Label"
        }
        $script:SymlinkFallback = $true
    }
}

function Write-GrokStatuslineStub {
    param(
        [string]$Target,
        [string]$AgentsHome
    )

    $escaped = $AgentsHome.Replace('\', '\\')
    @(
        '#!/usr/bin/env node'
        'const os = require(''os'');'
        'const path = require(''path'');'
        "const root = process.env.AGENTS_HOME || '$escaped';"
        "require(path.join(root, 'grok', 'statusline.js'));"
    ) -join "`n" | Set-Content -LiteralPath $Target -Encoding utf8NoBOM -NoNewline
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

Write-Host "[1/3] Installing Skills ..." -ForegroundColor Cyan
$AgentsSkillsDir = Join-Path $AgentsDir "skills"
if ($SourceDir -eq $AgentsDir) {
    Write-Host "  source is already $AgentsDir"
} else {
    New-Item -ItemType Directory -Path $AgentsSkillsDir -Force | Out-Null
    Get-ChildItem (Join-Path $SourceDir "skills") -Directory | ForEach-Object {
        Install-Item -Source $_.FullName -Target (Join-Path $AgentsSkillsDir $_.Name) -Label "skills\$($_.Name)"
    }
    $SourceGrok = Join-Path $SourceDir "grok"
    if (Test-Path $SourceGrok) {
        Install-Item -Source $SourceGrok -Target (Join-Path $AgentsDir "grok") -Label "grok"
    }
}

Write-Host "[2/3] Linking Skills into Claude Code ..." -ForegroundColor Cyan
$ClaudeSkillsDir = Join-Path $ClaudeDir "skills"
New-Item -ItemType Directory -Path $ClaudeSkillsDir -Force | Out-Null
Get-ChildItem $AgentsSkillsDir -Directory | Where-Object { $_.Name -notlike "*.backup-*" } | ForEach-Object {
    Install-Link -Source $_.FullName -Target (Join-Path $ClaudeSkillsDir $_.Name) -Label "skills\$($_.Name)"
}
Remove-StaleClaudeSkills -ClaudeSkillsDir $ClaudeSkillsDir -AgentsSkillsDir $AgentsSkillsDir

Write-Host "[3/3] Linking Grok statusline ..." -ForegroundColor Cyan
$GrokStatuslineSource = Join-Path $AgentsDir "grok\statusline.js"
$GrokStatuslineTarget = Join-Path $GrokDir "statusline.js"
if (Test-Path $GrokStatuslineSource) {
    New-Item -ItemType Directory -Path $GrokDir -Force | Out-Null
    Install-Link -Source $GrokStatuslineSource -Target $GrokStatuslineTarget -Label "grok\statusline.js" -Fallback {
        Write-GrokStatuslineStub -Target $GrokStatuslineTarget -AgentsHome $AgentsDir
    }
} else {
    Write-Host "  skipped: grok\statusline.js not found"
}

Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host "  Skills: $AgentsSkillsDir"
Write-Host "  Grok statusline: $GrokStatuslineTarget -> $GrokStatuslineSource"
Write-Host ""
Write-Host "Next:"
Write-Host "  - Claude Code: ask to review and merge $(Join-Path $SourceDir 'claude') into $ClaudeDir."
Write-Host "  - Codex: ask to merge $(Join-Path $SourceDir 'codex\config.toml') into $(Join-Path $CodexDir 'config.toml')."
Write-Host "  - Grok: keep $GrokDir\config.toml machine-local; it should run the linked statusline.js."

if ($script:SymlinkFallback) {
    Write-Host ""
    Write-Host "Note: symbolic links were unavailable, so Skills were copied and Grok statusline was stubbed." -ForegroundColor Yellow
    Write-Host "      Enable Developer Mode or run as administrator, then rerun to link them."
}
