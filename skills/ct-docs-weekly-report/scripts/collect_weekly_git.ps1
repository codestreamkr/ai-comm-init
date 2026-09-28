[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Author,

    [Parameter(Mandatory = $true)]
    [datetimeoffset]$Since,

    [Parameter(Mandatory = $true)]
    [datetimeoffset]$Until,

    [string[]]$Branches,

    [string]$ExcludeSubjectRegex = '(?i)(infi\s+merge|integration\s+merge)',

    [switch]$IncludeIntegrationCommits
)

$ErrorActionPreference = 'Stop'

function Invoke-Git {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)

    $output = & git @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Arguments -join ' ') failed:`n$($output -join "`n")"
    }
    return @($output)
}

function Get-FileSummary {
    param(
        [string[]]$Paths,
        [string]$Pattern
    )

    $matched = @($Paths | Where-Object { $_ -like $Pattern })
    $unique = @($matched | Sort-Object -Unique)
    $frequency = @(
        $matched |
            Group-Object |
            Sort-Object -Property @(
                @{ Expression = 'Count'; Descending = $true },
                @{ Expression = 'Name'; Descending = $false }
            )
    )

    $representativePath = if ($frequency.Count -gt 0) { $frequency[0].Name } else { $null }
    $representativeName = if ($representativePath) {
        [System.IO.Path]::GetFileName($representativePath)
    } else {
        $null
    }

    [ordered]@{
        total = $unique.Count
        othersCount = [Math]::Max(0, $unique.Count - 1)
        representativeName = $representativeName
        representativePath = $representativePath
        files = $unique
    }
}

Invoke-Git rev-parse --is-inside-work-tree | Out-Null

if (-not $Branches -or $Branches.Count -eq 0) {
    $Branches = @(Invoke-Git branch --show-current)
    if (-not $Branches[0]) {
        throw '현재 브랜치를 확인할 수 없습니다. -Branches에 분석할 ref를 지정하세요.'
    }
}

$branchResults = @()

foreach ($branch in $Branches) {
    Invoke-Git rev-parse --verify "$branch^{commit}" | Out-Null

    $format = '%H%x1f%aI%x1f%P%x1f%s'
    $rows = @(Invoke-Git log $branch --regexp-ignore-case "--author=$Author" "--format=$format")
    $commitMap = @{}

    foreach ($row in $rows) {
        $parts = $row -split [char]0x1f, 4
        if ($parts.Count -ne 4) {
            continue
        }

        $hash = $parts[0]
        $authorDate = [datetimeoffset]$parts[1]
        $parents = @($parts[2] -split ' ' | Where-Object { $_ })
        $subject = $parts[3]

        if ($authorDate -lt $Since -or $authorDate -gt $Until) {
            continue
        }
        if ($parents.Count -gt 1) {
            continue
        }
        if (-not $IncludeIntegrationCommits -and $subject -match $ExcludeSubjectRegex) {
            continue
        }
        if (-not $commitMap.ContainsKey($hash)) {
            $commitMap[$hash] = [ordered]@{
                hash = $hash
                shortHash = $hash.Substring(0, [Math]::Min(9, $hash.Length))
                authorDate = $authorDate.ToString('o')
                subject = $subject
            }
        }
    }

    $commits = @($commitMap.Values | Sort-Object { [datetimeoffset]$_.authorDate })
    $allPaths = @()
    $commitDetails = @()

    foreach ($commit in $commits) {
        $paths = @(Invoke-Git diff-tree --no-commit-id --name-only -r $commit.hash)
        $paths = @($paths | Where-Object { $_ })
        $allPaths += $paths
        $commitDetails += [ordered]@{
            hash = $commit.hash
            shortHash = $commit.shortHash
            authorDate = $commit.authorDate
            subject = $commit.subject
            files = @($paths | Sort-Object -Unique)
        }
    }

    $mainJavaPaths = @($allPaths | Where-Object { $_ -like 'src/main/java/*.java' })
    $testJavaPaths = @($allPaths | Where-Object { $_ -like 'src/test/java/*.java' } | Sort-Object -Unique)
    $jspPaths = @($allPaths | Where-Object { $_ -like '*.jsp' })

    $branchResults += [ordered]@{
        branch = $branch
        author = $Author
        since = $Since.ToString('o')
        until = $Until.ToString('o')
        commitCount = $commitDetails.Count
        commits = $commitDetails
        mainJava = Get-FileSummary -Paths $mainJavaPaths -Pattern '*.java'
        testJavaCount = $testJavaPaths.Count
        jsp = Get-FileSummary -Paths $jspPaths -Pattern '*.jsp'
    }
}

[ordered]@{
    branches = $branchResults
} | ConvertTo-Json -Depth 8
