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
$GeminiDir = if ($env:GEMINI_HOME) { $env:GEMINI_HOME } else { Join-Path $env:USERPROFILE ".gemini" }

$PiDir = if ($env:PI_HOME) { $env:PI_HOME } else { Join-Path $env:USERPROFILE ".pi/agent" }

function Get-BackupPath {
    param([string]$Path)
    return "$Path.backup-$(Get-Date -Format 'yyyyMMddHHmmss')"
}

function Clear-ExistingTarget {
    param(
        [string]$Target,
        [string]$Label
    )

    if (-not (Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue)) {
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
    param([string]$Source, [string]$Target, [string]$Label)

    $Existing = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
    if ($Existing -and $Existing.LinkType -eq "SymbolicLink" -and $Existing.Target -contains $Source) {
        Write-Host "  already linked: $Label"
        return
    }
    if (-not (Clear-ExistingTarget -Target $Target -Label $Label)) { return }
    try {
        New-Item -ItemType SymbolicLink -Path $Target -Target $Source -ErrorAction Stop | Out-Null
        Write-Host "  linked: $Label"
    } catch {
        throw "Cannot create symbolic link for $Label. Enable Developer Mode or run as administrator, then retry. $($_.Exception.Message)"
    }
}

function Remove-StaleSkills {
    param(
        [string]$TargetSkillsDir,
        [string]$AgentsSkillsDir
    )

    if (-not (Test-Path $TargetSkillsDir)) {
        return
    }

    Get-ChildItem $TargetSkillsDir | ForEach-Object {
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

foreach ($Required in @("skills", "claude", "codex", "agy")) {
    if (-not (Test-Path (Join-Path $SourceDir $Required))) {
        throw "Invalid installation source: $SourceDir (missing $Required\)"
    }
}

Write-Host "[1/2] Installing source files ..." -ForegroundColor Cyan
$AgentsSkillsDir = Join-Path $AgentsDir "skills"
if ($SourceDir -eq $AgentsDir) {
    Write-Host "  source is already $AgentsDir"
} else {
    New-Item -ItemType Directory -Path $AgentsSkillsDir -Force | Out-Null
    Get-ChildItem (Join-Path $SourceDir "skills") -Directory | ForEach-Object {
        Install-Item -Source $_.FullName -Target (Join-Path $AgentsSkillsDir $_.Name) -Label "skills\$($_.Name)" 6>$null
    }
    foreach ($Runtime in @("claude", "codex", "agy", "grok", "pi")) {
        $SourceRuntime = Join-Path $SourceDir $Runtime
        if (Test-Path $SourceRuntime) {
            Install-Item -Source $SourceRuntime -Target (Join-Path $AgentsDir $Runtime) -Label $Runtime 6>$null
        }
    }
}

function Install-Runtime {
    param(
        [string]$Label,
        [string]$SourceName,
        [string]$RuntimeHome,
        [string]$Instructions,
        [string[]]$Commands
    )
    $Detected = $null
    foreach ($CommandName in $Commands) {
        if (Get-Command $CommandName -CommandType Application,ExternalScript -ErrorAction SilentlyContinue) {
            $Detected = $CommandName
            break
        }
    }
    if (-not $Detected) {
        Write-Host "  skipped: $Label (CLI not found in PATH)"
        return
    }
    $SkillsDir = Join-Path $RuntimeHome "skills"
    New-Item -ItemType Directory -Path $SkillsDir -Force | Out-Null
    $InstructionsSource = Join-Path (Join-Path $AgentsDir $SourceName) $Instructions
    if (Test-Path -LiteralPath $InstructionsSource) {
        Install-Link -Source $InstructionsSource -Target (Join-Path $RuntimeHome $Instructions) -Label "$Label/$Instructions" 6>$null
    } else {
        Write-Host "  skipped: $SourceName/$Instructions not found"
    }
    Get-ChildItem -LiteralPath $AgentsSkillsDir -Directory | Where-Object { $_.Name -notlike "*.backup-*" } | ForEach-Object {
        Install-Link -Source $_.FullName -Target (Join-Path $SkillsDir $_.Name) -Label "$Label/skills/$($_.Name)" 6>$null
    }
    Remove-StaleSkills -TargetSkillsDir $SkillsDir -AgentsSkillsDir $AgentsSkillsDir 6>$null
    $StatuslineSource = Join-Path $AgentsDir "grok/statusline.js"
    if ($SourceName -eq "grok" -and (Test-Path -LiteralPath $StatuslineSource)) {
        Install-Link -Source $StatuslineSource -Target (Join-Path $RuntimeHome "statusline.js") -Label "grok/statusline.js" 6>$null
    }
    Write-Host "  완료: $Label"
}

Write-Host "[2/2] Detecting installed AI CLIs and linking instructions and skills ..." -ForegroundColor Cyan
Install-Runtime -Label "Claude Code" -SourceName claude -RuntimeHome $ClaudeDir -Instructions CLAUDE.md -Commands @("claude")
Install-Runtime -Label "Codex" -SourceName codex -RuntimeHome $CodexDir -Instructions AGENTS.md -Commands @("codex")
Install-Runtime -Label "Antigravity / Gemini" -SourceName agy -RuntimeHome (Join-Path $GeminiDir "config") -Instructions GEMINI.md -Commands @("agy", "antigravity", "gemini")
Install-Runtime -Label "Grok" -SourceName grok -RuntimeHome $GrokDir -Instructions AGENTS.md -Commands @("grok")
Install-Runtime -Label "Pi" -SourceName pi -RuntimeHome $PiDir -Instructions AGENTS.md -Commands @("pi")

Write-Host ""
Write-Host "Done. Source: $AgentsDir" -ForegroundColor Green
Write-Host "Existing files are preserved; use -Force to back them up and replace them with links."
Write-Host "Machine-local settings.json and config.toml files must be reviewed and merged separately."
