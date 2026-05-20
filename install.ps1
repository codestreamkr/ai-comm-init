# ChatGPT Codex Init - Windows PowerShell
# Usage: git clone https://github.com/codestreamkr/chatgpt-codex-init.git $env:TEMP\codex-init; & $env:TEMP\codex-init\install.ps1

param(
    [string]$Repo = "https://github.com/codestreamkr/chatgpt-codex-init.git"
)

$ErrorActionPreference = "Stop"
$CodexDir = "$env:USERPROFILE\.codex"
$GitDir = Join-Path $CodexDir ".git"
$TempDir = $null

function Get-McpConfigText {
    param(
        [string]$Name
    )

    try {
        $output = (& codex mcp get $Name 2>$null | Out-String).Trim()
        if ($LASTEXITCODE -eq 0) {
            return $output
        }
    } catch {
    }

    return ""
}

function Register-StdioMcp {
    param(
        [string]$Name,
        [string[]]$CommandArgs
    )

    $current = Get-McpConfigText -Name $Name
    $command = $CommandArgs[0]
    $args = ($CommandArgs[1..($CommandArgs.Length - 1)] -join " ")

    if (
        $current -and
        $current.Contains("transport: stdio") -and
        $current.Contains("command: $command") -and
        $current.Contains("args: $args")
    ) {
        Write-Host "  already configured: $Name"
        return
    }

    if ($current) {
        & codex mcp remove $Name *> $null
    }

    $cmd = @("mcp", "add", $Name, "--") + $CommandArgs
    & codex @cmd
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  registered: $Name"
    } else {
        Write-Host "  skipped: $Name"
    }
}

function Register-HttpMcp {
    param(
        [string]$Name,
        [string]$Url
    )

    $current = Get-McpConfigText -Name $Name
    if (
        $current -and
        $current.Contains("transport: streamable_http") -and
        $current.Contains("url: $Url")
    ) {
        Write-Host "  already configured: $Name"
        return
    }

    if ($current) {
        & codex mcp remove $Name *> $null
    }

    $cmd = @("mcp", "add", $Name, "--url", $Url)
    & codex @cmd
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  registered: $Name"
    } else {
        Write-Host "  skipped: $Name"
    }
}

try {
    Write-Host "[1/4] Preparing ~/.codex/ ..." -ForegroundColor Cyan
    if (-not (Test-Path $CodexDir)) {
        New-Item -ItemType Directory -Path $CodexDir -Force | Out-Null
        Write-Host "  ~/.codex/ created"
    } else {
        Write-Host "  ~/.codex/ already exists"
    }

    Write-Host "[2/4] Connecting git repo..." -ForegroundColor Cyan
    Write-Host "  configuring git: http.sslVerify=false"
    git config --global http.sslVerify false
    if (Test-Path $GitDir) {
        Push-Location $CodexDir
        $existing = git remote get-url origin 2>$null
        if (-not $existing) {
            git remote add origin $Repo
        } elseif ($existing -ne $Repo) {
            git remote set-url origin $Repo
        }
        git fetch origin
        git reset --hard origin/main
        Pop-Location
        Write-Host "  updated to latest"
    } else {
        $agentsPath = Join-Path $CodexDir "AGENTS.md"
        if (Test-Path $agentsPath) {
            $backupPath = Join-Path $CodexDir "AGENTS.md~backup"
            Move-Item $agentsPath $backupPath -Force
            Write-Host "  backed up: AGENTS.md -> AGENTS.md~backup"
        }

        $TempDir = Join-Path $env:TEMP ("codex-init-clone-" + [guid]::NewGuid().ToString("N"))
        git clone $Repo $TempDir
        Move-Item (Join-Path $TempDir ".git") $GitDir

        Push-Location $CodexDir
        git reset --hard HEAD
        Pop-Location
        Write-Host "  cloned and applied"
    }

    Write-Host "[3/4] Registering MCP servers..." -ForegroundColor Cyan
    if (Get-Command codex -ErrorAction SilentlyContinue) {
        Register-StdioMcp -Name "playwright" -CommandArgs @("npx", "-y", "@playwright/mcp@latest")
        Register-StdioMcp -Name "context7" -CommandArgs @("npx", "-y", "@upstash/context7-mcp")
    } else {
        Write-Host "  skipped (codex not found)"
    }

    Write-Host "[4/4] Verifying..." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Installed files:" -ForegroundColor Green
    foreach ($f in @("AGENTS.md", ".gitignore", "config.toml")) {
        if (Test-Path (Join-Path $CodexDir $f)) {
            Write-Host "  + $f"
        }
    }
    Get-ChildItem (Join-Path $CodexDir "skills") -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
        $relative = $_.FullName.Substring($CodexDir.Length + 1).Replace("\", "/")
        Write-Host "  + $relative"
    }

    Write-Host ""
    Write-Host "Done!" -ForegroundColor Green
    Write-Host "  Location: $CodexDir"
    Write-Host "  Push changes: cd $CodexDir && git add -A && git commit -m 'update' && git push"
    Write-Host ""
    Write-Host "Next: run 'codex' to authenticate and verify." -ForegroundColor Yellow
}
finally {
    if ($TempDir -and (Test-Path $TempDir)) {
        Remove-Item $TempDir -Recurse -Force
    }

    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    if ($ScriptDir -like "$env:TEMP*") {
        Remove-Item $ScriptDir -Recurse -Force
    }
}
