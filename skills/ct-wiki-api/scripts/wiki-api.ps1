[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet("help", "check-env", "search", "smart-search", "get-page", "get-comments", "get-attachments", "get-child-pages", "get-descendant-pages", "get-labels", "get-history", "get-restrictions", "get-page-bundle", "save-page", "save-comments", "create-page", "update-page")]
    [string]$Command,

    [string]$Cql,
    [string]$Query,
    [string]$PageId,
    [string]$ParentId,
    [string]$Space,
    [string]$Title,
    [string]$BodyFile,
    [string]$OutDir,
    [int]$Start = 0,
    [int]$Limit = 25,
    [string]$Expand,
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

function New-WikiQueryString {
    param([Parameter(Mandatory = $true)][System.Collections.IDictionary]$Params)

    $parts = @()
    foreach ($key in $Params.Keys) {
        $value = $Params[$key]
        if ($null -eq $value -or [string]::IsNullOrWhiteSpace([string]$value)) {
            continue
        }

        $parts += ((ConvertTo-QueryValue ([string]$key)) + "=" + (ConvertTo-QueryValue ([string]$value)))
    }

    if ($parts.Count -eq 0) {
        return ""
    }

    return "?" + ($parts -join "&")
}

function Invoke-WikiSearch {
    param(
        [Parameter(Mandatory = $true)][string]$SearchCql,
        [string]$ExpandValue = "space,version",
        [int]$StartIndex = 0,
        [int]$PageLimit = 25
    )

    if ($StartIndex -lt 0) {
        throw "Start must be 0 or greater."
    }
    if ($PageLimit -lt 1) {
        throw "Limit must be 1 or greater."
    }

    $query = New-WikiQueryString ([ordered]@{
        cql = $SearchCql
        expand = $ExpandValue
        start = $StartIndex
        limit = $PageLimit
    })
    return Invoke-WikiApi -Method "GET" -Path "/content/search$query"
}

function Invoke-WikiContentCollection {
    param(
        [Parameter(Mandatory = $true)][string]$ContentId,
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [string]$ExpandValue,
        [int]$StartIndex = 0,
        [int]$PageLimit = 25
    )

    if ($StartIndex -lt 0) {
        throw "Start must be 0 or greater."
    }
    if ($PageLimit -lt 1) {
        throw "Limit must be 1 or greater."
    }

    $query = New-WikiQueryString ([ordered]@{
        expand = $ExpandValue
        start = $StartIndex
        limit = $PageLimit
    })
    return Invoke-WikiApi -Method "GET" -Path "/content/$ContentId/$RelativePath$query"
}

function Invoke-WikiOptionalSection {
    param(
        [Parameter(Mandatory = $true)][scriptblock]$Action
    )

    try {
        return & $Action
    }
    catch {
        return [pscustomobject]@{
            error = $_.Exception.Message
        }
    }
}

function Get-WikiHelp {
    [pscustomobject]@{
        commands = @(
            [pscustomobject]@{ name = "check-env"; description = "환경변수 설정 여부 확인" },
            [pscustomobject]@{ name = "search"; description = "CQL 직접 검색"; required = "-Cql"; optional = "-Start -Limit -Expand" },
            [pscustomobject]@{ name = "smart-search"; description = "page id, URL, 제목, 본문 순서의 스마트 검색"; required = "-Query"; optional = "-Space" },
            [pscustomobject]@{ name = "get-page"; description = "페이지 본문, 버전, Space 조회"; required = "-PageId" },
            [pscustomobject]@{ name = "get-comments"; description = "페이지 코멘트 조회"; required = "-PageId"; optional = "-Start -Limit -Expand" },
            [pscustomobject]@{ name = "get-attachments"; description = "페이지 첨부파일 조회"; required = "-PageId"; optional = "-Start -Limit -Expand" },
            [pscustomobject]@{ name = "get-child-pages"; description = "직접 하위 페이지 조회"; required = "-PageId"; optional = "-Start -Limit -Expand" },
            [pscustomobject]@{ name = "get-descendant-pages"; description = "CQL ancestor 조건으로 전체 하위 페이지 조회"; required = "-PageId"; optional = "-Start -Limit -Expand" },
            [pscustomobject]@{ name = "get-labels"; description = "페이지 라벨 조회"; required = "-PageId"; optional = "-Start -Limit" },
            [pscustomobject]@{ name = "get-history"; description = "페이지 히스토리 조회"; required = "-PageId"; optional = "-Expand" },
            [pscustomobject]@{ name = "get-restrictions"; description = "페이지 제한 정보 조회"; required = "-PageId"; optional = "-Expand" },
            [pscustomobject]@{ name = "get-page-bundle"; description = "페이지, 코멘트, 첨부, 하위 페이지, 라벨, 히스토리, 제한 정보 묶음 조회"; required = "-PageId"; optional = "-Start -Limit" },
            [pscustomobject]@{ name = "save-page"; description = "페이지 원문 JSON 저장"; required = "-PageId"; optional = "-OutDir" },
            [pscustomobject]@{ name = "save-comments"; description = "페이지 코멘트 JSON 저장"; required = "-PageId"; optional = "-OutDir -Start -Limit -Expand" },
            [pscustomobject]@{ name = "create-page"; description = "페이지 생성 dry-run 또는 실제 생성"; required = "-Title -BodyFile"; optional = "-ParentId -Space -Representation -Write" },
            [pscustomobject]@{ name = "update-page"; description = "페이지 수정 dry-run 또는 실제 반영"; required = "-PageId -BodyFile"; optional = "-Title -Representation -Write" }
        )
        examples = @(
            "wiki-api.ps1 get-comments -PageId 231796715",
            "wiki-api.ps1 get-attachments -PageId 231796715",
            "wiki-api.ps1 get-page-bundle -PageId 231796715",
            "wiki-api.ps1 save-comments -PageId 231796715",
            "wiki-api.ps1 create-page -ParentId 349474638 -Title '직영몰 PG 고도화 최종 결정 요약' -BodyFile .\\work\\page-body.html -Write"
        )
    }
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
        "help" {
            Get-WikiHelp | ConvertTo-Json -Depth 10
        }

        "check-env" {
            Test-WikiEnv | ConvertTo-Json -Depth 5
        }

        "search" {
            if ([string]::IsNullOrWhiteSpace($Cql)) {
                throw "Cql is required for search."
            }

            $expandValue = $Expand
            if ([string]::IsNullOrWhiteSpace($expandValue)) {
                $expandValue = "space,version"
            }

            $result = Invoke-WikiSearch -SearchCql $Cql -ExpandValue $expandValue -StartIndex $Start -PageLimit $Limit
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

        "get-comments" {
            if ([string]::IsNullOrWhiteSpace($PageId)) {
                throw "PageId is required for get-comments."
            }

            $expandValue = $Expand
            if ([string]::IsNullOrWhiteSpace($expandValue)) {
                $expandValue = "body.storage,version,container,extensions"
            }

            $result = Invoke-WikiContentCollection -ContentId $PageId -RelativePath "child/comment" -ExpandValue $expandValue -StartIndex $Start -PageLimit $Limit
            $result | ConvertTo-Json -Depth 50
        }

        "get-attachments" {
            if ([string]::IsNullOrWhiteSpace($PageId)) {
                throw "PageId is required for get-attachments."
            }

            $expandValue = $Expand
            if ([string]::IsNullOrWhiteSpace($expandValue)) {
                $expandValue = "version,container"
            }

            $result = Invoke-WikiContentCollection -ContentId $PageId -RelativePath "child/attachment" -ExpandValue $expandValue -StartIndex $Start -PageLimit $Limit
            $result | ConvertTo-Json -Depth 50
        }

        "get-child-pages" {
            if ([string]::IsNullOrWhiteSpace($PageId)) {
                throw "PageId is required for get-child-pages."
            }

            $expandValue = $Expand
            if ([string]::IsNullOrWhiteSpace($expandValue)) {
                $expandValue = "space,version"
            }

            $result = Invoke-WikiContentCollection -ContentId $PageId -RelativePath "child/page" -ExpandValue $expandValue -StartIndex $Start -PageLimit $Limit
            $result | ConvertTo-Json -Depth 50
        }

        "get-descendant-pages" {
            if ([string]::IsNullOrWhiteSpace($PageId)) {
                throw "PageId is required for get-descendant-pages."
            }

            $expandValue = $Expand
            if ([string]::IsNullOrWhiteSpace($expandValue)) {
                $expandValue = "space,version"
            }

            $result = Invoke-WikiSearch -SearchCql "type = page and ancestor = $PageId" -ExpandValue $expandValue -StartIndex $Start -PageLimit $Limit
            $result | ConvertTo-Json -Depth 50
        }

        "get-labels" {
            if ([string]::IsNullOrWhiteSpace($PageId)) {
                throw "PageId is required for get-labels."
            }

            if ($Start -lt 0) {
                throw "Start must be 0 or greater."
            }
            if ($Limit -lt 1) {
                throw "Limit must be 1 or greater."
            }

            $query = New-WikiQueryString ([ordered]@{
                start = $Start
                limit = $Limit
            })
            $result = Invoke-WikiApi -Method "GET" -Path "/content/$PageId/label$query"
            $result | ConvertTo-Json -Depth 50
        }

        "get-history" {
            if ([string]::IsNullOrWhiteSpace($PageId)) {
                throw "PageId is required for get-history."
            }

            $expandValue = $Expand
            if ([string]::IsNullOrWhiteSpace($expandValue)) {
                $expandValue = "lastUpdated,previousVersion,nextVersion"
            }

            $query = New-WikiQueryString ([ordered]@{
                expand = $expandValue
            })
            $result = Invoke-WikiApi -Method "GET" -Path "/content/$PageId/history$query"
            $result | ConvertTo-Json -Depth 50
        }

        "get-restrictions" {
            if ([string]::IsNullOrWhiteSpace($PageId)) {
                throw "PageId is required for get-restrictions."
            }

            $query = New-WikiQueryString ([ordered]@{
                expand = $Expand
            })
            $result = Invoke-WikiApi -Method "GET" -Path "/content/$PageId/restriction/byOperation$query"
            $result | ConvertTo-Json -Depth 50
        }

        "get-page-bundle" {
            if ([string]::IsNullOrWhiteSpace($PageId)) {
                throw "PageId is required for get-page-bundle."
            }

            $result = [pscustomobject]@{
                page = Invoke-WikiOptionalSection { Invoke-WikiApi -Method "GET" -Path "/content/$PageId`?expand=body.storage,version,space" }
                comments = Invoke-WikiOptionalSection { Invoke-WikiContentCollection -ContentId $PageId -RelativePath "child/comment" -ExpandValue "body.storage,version,container,extensions" -StartIndex $Start -PageLimit $Limit }
                attachments = Invoke-WikiOptionalSection { Invoke-WikiContentCollection -ContentId $PageId -RelativePath "child/attachment" -ExpandValue "version,container" -StartIndex $Start -PageLimit $Limit }
                childPages = Invoke-WikiOptionalSection { Invoke-WikiContentCollection -ContentId $PageId -RelativePath "child/page" -ExpandValue "space,version" -StartIndex $Start -PageLimit $Limit }
                descendantPages = Invoke-WikiOptionalSection { Invoke-WikiSearch -SearchCql "type = page and ancestor = $PageId" -ExpandValue "space,version" -StartIndex $Start -PageLimit $Limit }
                labels = Invoke-WikiOptionalSection {
                    $labelQuery = New-WikiQueryString ([ordered]@{
                        start = $Start
                        limit = $Limit
                    })
                    Invoke-WikiApi -Method "GET" -Path "/content/$PageId/label$labelQuery"
                }
                history = Invoke-WikiOptionalSection { Invoke-WikiApi -Method "GET" -Path "/content/$PageId/history?expand=lastUpdated,previousVersion,nextVersion" }
                restrictions = Invoke-WikiOptionalSection { Invoke-WikiApi -Method "GET" -Path "/content/$PageId/restriction/byOperation" }
            }
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

        "save-comments" {
            if ([string]::IsNullOrWhiteSpace($PageId)) {
                throw "PageId is required for save-comments."
            }

            if ([string]::IsNullOrWhiteSpace($OutDir)) {
                $OutDir = Get-WikiEnv -Name "WIKI_API_RAW_DIR" -FallbackName "CONFLUENCE_RAW_DIR"
            }
            if ([string]::IsNullOrWhiteSpace($OutDir)) {
                $OutDir = ".wiki/raw/wiki-api"
            }

            $expandValue = $Expand
            if ([string]::IsNullOrWhiteSpace($expandValue)) {
                $expandValue = "body.storage,version,container,extensions"
            }

            $result = Invoke-WikiContentCollection -ContentId $PageId -RelativePath "child/comment" -ExpandValue $expandValue -StartIndex $Start -PageLimit $Limit
            $path = Join-Path $OutDir "$PageId-comments.json"
            Save-JsonFile -Value $result -Path $path
            Write-Output "Saved: $path"
        }

        "create-page" {
            if ([string]::IsNullOrWhiteSpace($Title)) {
                throw "Title is required for create-page."
            }
            if ([string]::IsNullOrWhiteSpace($BodyFile)) {
                throw "BodyFile is required for create-page."
            }
            if (-not (Test-Path -LiteralPath $BodyFile)) {
                throw "BodyFile does not exist: $BodyFile"
            }

            $spaceKey = $Space
            $ancestors = @()
            if (-not [string]::IsNullOrWhiteSpace($ParentId)) {
                $parent = Invoke-WikiApi -Method "GET" -Path "/content/$ParentId`?expand=space"
                $ancestors += @{ id = $ParentId }
                if ([string]::IsNullOrWhiteSpace($spaceKey)) {
                    $spaceKey = $parent.space.key
                }
            }

            if ([string]::IsNullOrWhiteSpace($spaceKey)) {
                throw "Space is required for create-page when ParentId is not provided."
            }

            $payload = @{
                type = "page"
                title = $Title
                space = @{
                    key = $spaceKey
                }
                body = @{
                    storage = @{
                        value = Get-Content -Raw -LiteralPath $BodyFile
                        representation = $Representation
                    }
                }
            }

            if ($ancestors.Count -gt 0) {
                $payload["ancestors"] = $ancestors
            }

            if (-not $Write) {
                Write-Output "Dry-run only. Add -Write to create the page."
                $payload | ConvertTo-Json -Depth 20
                return
            }

            $result = Invoke-WikiApi -Method "POST" -Path "/content" -Body $payload
            $result | ConvertTo-Json -Depth 20
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
