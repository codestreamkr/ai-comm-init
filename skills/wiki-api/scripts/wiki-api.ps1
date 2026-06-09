[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet("check-env", "search", "smart-search", "get-page", "save-page", "update-page")]
    [string]$Command,

    [string]$Cql,
    [string]$Query,
    [string]$PageId,
    [string]$Space,
    [string]$Title,
    [string]$BodyFile,
    [string]$OutDir,
    [string]$Representation = "storage",
    [ValidateSet("", "bearer", "basic")]
    [string]$AuthTypeOverride = "",
    [switch]$NoProxy,
    [switch]$UseProxy,
    [switch]$Write
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:RestoreEnv = @{}

function Set-TemporaryEnv {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [AllowNull()][string]$Value
    )

    if (-not $script:RestoreEnv.ContainsKey($Name)) {
        $script:RestoreEnv[$Name] = [Environment]::GetEnvironmentVariable($Name, "Process")
    }

    [Environment]::SetEnvironmentVariable($Name, $Value, "Process")
}

function Restore-TemporaryEnv {
    foreach ($name in $script:RestoreEnv.Keys) {
        [Environment]::SetEnvironmentVariable($name, $script:RestoreEnv[$name], "Process")
    }
}

# Codex sessions can inherit a local proxy that rejects Wiki API calls.
if ($NoProxy -or -not $UseProxy) {
    foreach ($name in @("HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY", "NO_PROXY", "http_proxy", "https_proxy", "all_proxy", "no_proxy")) {
        Set-TemporaryEnv -Name $name -Value $null
    }
}

if (-not [string]::IsNullOrWhiteSpace($AuthTypeOverride)) {
    Set-TemporaryEnv -Name "WIKI_API_AUTH_TYPE" -Value $AuthTypeOverride
}

function Get-WikiEnv {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$FallbackName,
        [switch]$Required
    )

    $value = $null
    foreach ($scope in @("Process", "User", "Machine")) {
        $value = [Environment]::GetEnvironmentVariable($Name, $scope)
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            return $value
        }

        if (-not [string]::IsNullOrWhiteSpace($FallbackName)) {
            $value = [Environment]::GetEnvironmentVariable($FallbackName, $scope)
            if (-not [string]::IsNullOrWhiteSpace($value)) {
                return $value
            }
        }
    }

    if ($Required -and [string]::IsNullOrWhiteSpace($value)) {
        if ([string]::IsNullOrWhiteSpace($FallbackName)) {
            throw "Missing required environment variable: $Name"
        }
        throw "Missing required environment variable: $Name or $FallbackName"
    }

    return $value
}

function Test-WikiEnv {
    $names = @(
        "WIKI_API_BASE_URL",
        "WIKI_API_AUTH_TYPE",
        "WIKI_API_TOKEN",
        "WIKI_API_USER",
        "WIKI_API_PASSWORD",
        "WIKI_API_DEFAULT_SPACE",
        "WIKI_API_RAW_DIR",
        "WIKI_API_ROOT"
    )

    foreach ($name in $names) {
        $set = $false
        foreach ($scope in @("Process", "User", "Machine")) {
            if (-not [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($name, $scope))) {
                $set = $true
                break
            }
        }

        [pscustomobject]@{
            Name = $name
            Set = $set
        }
    }
}

function Get-WikiApiRoot {
    $apiRoot = Get-WikiEnv -Name "WIKI_API_ROOT" -FallbackName "CONFLUENCE_API_ROOT"
    if (-not [string]::IsNullOrWhiteSpace($apiRoot)) {
        return $apiRoot.TrimEnd("/")
    }

    $baseUrl = Get-WikiEnv -Name "WIKI_API_BASE_URL" -FallbackName "CONFLUENCE_BASE_URL" -Required
    return ($baseUrl.TrimEnd("/") + "/rest/api")
}

function Get-WikiHeaders {
    $authType = (Get-WikiEnv -Name "WIKI_API_AUTH_TYPE" -FallbackName "CONFLUENCE_AUTH_TYPE" -Required).ToLowerInvariant()
    $headers = @{
        "Accept" = "application/json"
        "Content-Type" = "application/json; charset=utf-8"
    }

    if ($authType -eq "basic") {
        $user = Get-WikiEnv -Name "WIKI_API_USER" -FallbackName "CONFLUENCE_USER"
        $password = Get-WikiEnv -Name "WIKI_API_PASSWORD" -FallbackName "CONFLUENCE_PASSWORD"
        if ([string]::IsNullOrWhiteSpace($user) -or [string]::IsNullOrWhiteSpace($password)) {
            $credential = Get-WikiEnv -Name "WIKI_API_TOKEN" -FallbackName "CONFLUENCE_TOKEN" -Required
            $parts = $credential.Split(",", 2)
            if ($parts.Count -ne 2 -or [string]::IsNullOrWhiteSpace($parts[0]) -or [string]::IsNullOrWhiteSpace($parts[1])) {
                throw "WIKI_API_TOKEN must be formatted as id,password when WIKI_API_AUTH_TYPE=basic and user/password env vars are not set."
            }

            $user = $parts[0].Trim()
            $password = $parts[1]
        }

        $bytes = [Text.Encoding]::UTF8.GetBytes("${user}:${password}")
        $headers["Authorization"] = "Basic " + [Convert]::ToBase64String($bytes)
        return $headers
    }

    if ($authType -eq "bearer") {
        $token = Get-WikiEnv -Name "WIKI_API_TOKEN" -FallbackName "CONFLUENCE_TOKEN" -Required
        if ($token.Contains(",")) {
            throw "WIKI_API_AUTH_TYPE must be basic when WIKI_API_TOKEN is formatted as id,password."
        }

        $headers["Authorization"] = "Bearer $token"
        return $headers
    }

    throw "Unsupported WIKI_API_AUTH_TYPE: $authType"
}

function Invoke-WikiApi {
    param(
        [Parameter(Mandatory = $true)][string]$Method,
        [Parameter(Mandatory = $true)][string]$Path,
        [object]$Body = $null
    )

    if ([type]::GetType("System.Net.ServicePointManager")) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }

    $params = @{
        Method = $Method
        Uri = (Get-WikiApiRoot) + $Path
        Headers = Get-WikiHeaders
        ErrorAction = "Stop"
    }

    if ($null -ne $Body) {
        $params["Body"] = ($Body | ConvertTo-Json -Depth 20)
    }

    if ((Get-Command Invoke-RestMethod).Parameters.ContainsKey("SslProtocol")) {
        $params["SslProtocol"] = "Tls12"
    }

    try {
        return Invoke-RestMethod @params
    }
    catch {
        throw "Wiki API request failed. Method=$Method Path=$Path Error=$($_.Exception.Message)"
    }
}

function ConvertTo-QueryValue {
    param([string]$Value)
    return [Uri]::EscapeDataString($Value)
}

function ConvertFrom-UrlValue {
    param([string]$Value)
    return [Uri]::UnescapeDataString(($Value -replace "\+", " "))
}

function Normalize-WikiSearchText {
    param([string]$Value)
    $normalized = $Value -replace "[^\p{L}\p{Nd}]+", " "
    return ($normalized -replace "\s+", " ").Trim()
}

function Get-WikiSearchTokens {
    param([string]$Value)

    $normalized = Normalize-WikiSearchText $Value
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        return @()
    }

    $tokens = @()
    foreach ($token in ($normalized -split "\s+")) {
        if ($token.Length -lt 2) {
            continue
        }
        if ($token -match "^[A-Za-z0-9]+$" -and $token.Length -lt 3) {
            continue
        }
        $tokens += $token
    }

    return @($tokens | Select-Object -Unique)
}

function ConvertTo-CqlLiteral {
    param([string]$Value)
    return '"' + ($Value -replace '\\', '\\' -replace '"', '\"') + '"'
}

function Join-WikiCql {
    param([string[]]$Parts)
    return (($Parts | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join " and ")
}

function New-WikiSearchCql {
    param(
        [Parameter(Mandatory = $true)][ValidateSet("title-full", "title-tokens", "text-full", "text-tokens")][string]$Kind,
        [Parameter(Mandatory = $true)][string]$Text,
        [string]$SpaceKey
    )

    $parts = @()
    if (-not [string]::IsNullOrWhiteSpace($SpaceKey)) {
        $parts += ("space = " + (ConvertTo-CqlLiteral $SpaceKey))
    }

    if ($Kind -like "title-*") {
        $parts += "type = page"
    }

    if ($Kind -eq "title-full") {
        $normalized = Normalize-WikiSearchText $Text
        if ([string]::IsNullOrWhiteSpace($normalized)) {
            return $null
        }
        $parts += ("title ~ " + (ConvertTo-CqlLiteral $normalized))
        return Join-WikiCql $parts
    }

    if ($Kind -eq "text-full") {
        $normalized = Normalize-WikiSearchText $Text
        if ([string]::IsNullOrWhiteSpace($normalized)) {
            return $null
        }
        $parts += ("text ~ " + (ConvertTo-CqlLiteral $normalized))
        return Join-WikiCql $parts
    }

    $tokens = Get-WikiSearchTokens $Text
    if ($tokens.Count -eq 0) {
        return $null
    }

    $field = "text"
    if ($Kind -eq "title-tokens") {
        $field = "title"
    }

    foreach ($token in $tokens) {
        $parts += ("$field ~ " + (ConvertTo-CqlLiteral $token))
    }

    return Join-WikiCql $parts
}

function Invoke-WikiSearch {
    param([Parameter(Mandatory = $true)][string]$SearchCql)

    $encodedCql = ConvertTo-QueryValue $SearchCql
    return Invoke-WikiApi -Method "GET" -Path "/content/search?cql=$encodedCql&expand=space,version"
}

function Invoke-WikiSmartSearch {
    param(
        [Parameter(Mandatory = $true)][string]$InputText,
        [string]$SpaceKey
    )

    $value = $InputText.Trim()
    if ($value -match "^\d+$") {
        $page = Invoke-WikiApi -Method "GET" -Path "/content/$value`?expand=body.storage,version,space"
        return [pscustomobject]@{
            mode = "page-id"
            pageId = $value
            result = $page
        }
    }

    if ($value -match "(?i)(?:\?|&)pageId=(\d+)") {
        $resolvedPageId = $Matches[1]
        $page = Invoke-WikiApi -Method "GET" -Path "/content/$resolvedPageId`?expand=body.storage,version,space"
        return [pscustomobject]@{
            mode = "url-page-id"
            pageId = $resolvedPageId
            result = $page
        }
    }

    $searchText = $value
    $searchSpace = $SpaceKey
    if ($value -match "(?i)/display/([^/?#]+)/([^?#]+)") {
        if ([string]::IsNullOrWhiteSpace($searchSpace)) {
            $searchSpace = ConvertFrom-UrlValue $Matches[1]
        }
        $searchText = ConvertFrom-UrlValue $Matches[2]
    }

    $attempts = @(
        @{ mode = "title-full"; cql = New-WikiSearchCql -Kind "title-full" -Text $searchText -SpaceKey $searchSpace },
        @{ mode = "title-tokens"; cql = New-WikiSearchCql -Kind "title-tokens" -Text $searchText -SpaceKey $searchSpace },
        @{ mode = "text-full"; cql = New-WikiSearchCql -Kind "text-full" -Text $searchText -SpaceKey $searchSpace },
        @{ mode = "text-tokens"; cql = New-WikiSearchCql -Kind "text-tokens" -Text $searchText -SpaceKey $searchSpace }
    )

    $errors = @()
    foreach ($attempt in $attempts) {
        if ([string]::IsNullOrWhiteSpace($attempt.cql)) {
            continue
        }

        try {
            $result = Invoke-WikiSearch -SearchCql $attempt.cql
            if ([int]$result.size -gt 0) {
                return [pscustomobject]@{
                    mode = $attempt.mode
                    cql = $attempt.cql
                    result = $result
                }
            }
        }
        catch {
            $errors += [pscustomobject]@{
                mode = $attempt.mode
                cql = $attempt.cql
                error = $_.Exception.Message
            }
        }
    }

    return [pscustomobject]@{
        mode = "not-found"
        query = $searchText
        space = $searchSpace
        attempts = @($attempts | Where-Object { -not [string]::IsNullOrWhiteSpace($_.cql) })
        errors = $errors
    }
}

function Save-JsonFile {
    param(
        [Parameter(Mandatory = $true)][object]$Value,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $parent = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }

    $Value | ConvertTo-Json -Depth 50 | Set-Content -LiteralPath $Path -Encoding utf8
}

try {
    switch ($Command) {
        "check-env" {
            Test-WikiEnv | ConvertTo-Json -Depth 5
        }

        "search" {
            if ([string]::IsNullOrWhiteSpace($Cql)) {
                throw "Cql is required for search."
            }

            $result = Invoke-WikiSearch -SearchCql $Cql
            $result | ConvertTo-Json -Depth 20
        }

        "smart-search" {
            if ([string]::IsNullOrWhiteSpace($Query)) {
                throw "Query is required for smart-search."
            }

            $result = Invoke-WikiSmartSearch -InputText $Query -SpaceKey $Space
            $result | ConvertTo-Json -Depth 50
        }

        "get-page" {
            if ([string]::IsNullOrWhiteSpace($PageId)) {
                throw "PageId is required for get-page."
            }

            $result = Invoke-WikiApi -Method "GET" -Path "/content/$PageId`?expand=body.storage,version,space"
            $result | ConvertTo-Json -Depth 50
        }

        "save-page" {
            if ([string]::IsNullOrWhiteSpace($PageId)) {
                throw "PageId is required for save-page."
            }

            if ([string]::IsNullOrWhiteSpace($OutDir)) {
                $OutDir = Get-WikiEnv -Name "WIKI_API_RAW_DIR" -FallbackName "CONFLUENCE_RAW_DIR"
            }
            if ([string]::IsNullOrWhiteSpace($OutDir)) {
                $OutDir = ".wiki/raw/wiki-api"
            }

            $result = Invoke-WikiApi -Method "GET" -Path "/content/$PageId`?expand=body.storage,version,space"
            $safeTitle = ($result.title -replace '[\\/:*?"<>|]', "_")
            $path = Join-Path $OutDir "$PageId-$safeTitle.json"
            Save-JsonFile -Value $result -Path $path
            Write-Output "Saved: $path"
        }

        "update-page" {
            if ([string]::IsNullOrWhiteSpace($PageId)) {
                throw "PageId is required for update-page."
            }
            if ([string]::IsNullOrWhiteSpace($BodyFile)) {
                throw "BodyFile is required for update-page."
            }
            if (-not (Test-Path -LiteralPath $BodyFile)) {
                throw "BodyFile does not exist: $BodyFile"
            }

            $current = Invoke-WikiApi -Method "GET" -Path "/content/$PageId`?expand=body.storage,version,space"
            $nextTitle = $Title
            if ([string]::IsNullOrWhiteSpace($nextTitle)) {
                $nextTitle = $current.title
            }

            $payload = @{
                id = $PageId
                type = "page"
                title = $nextTitle
                version = @{
                    number = ([int]$current.version.number + 1)
                }
                body = @{
                    storage = @{
                        value = Get-Content -Raw -LiteralPath $BodyFile
                        representation = $Representation
                    }
                }
            }

            if (-not $Write) {
                Write-Output "Dry-run only. Add -Write to update the page."
                $payload | ConvertTo-Json -Depth 20
                return
            }

            $result = Invoke-WikiApi -Method "PUT" -Path "/content/$PageId" -Body $payload
            $result | ConvertTo-Json -Depth 20
        }
    }
}
finally {
    Restore-TemporaryEnv
}
