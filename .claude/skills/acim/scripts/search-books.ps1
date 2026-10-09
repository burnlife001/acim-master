# search-books.ps1 — 在 ACIM 五部语料中搜索关键词 (PowerShell / pwsh)
# 用法:
#   .\search-books.ps1 -Query "宽恕"
#   .\search-books.ps1 -Query "神圣一刻" -Source "01.正文"
#   .\search-books.ps1 -Query "第121课" -Source "02.练习手册" -Context 3
#   .\search-books.ps1 -Query "小我" -MaxHits 5

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Query,

    [ValidateSet("all","01.正文","02.练习手册","03.教师指南","04.词汇解释","05.补编：心理治疗目的、过程与行业")]
    [string]$Source = "all",

    [int]$Context = 2,

    [int]$MaxHits = 20,

    [switch]$CaseSensitive
)

$ErrorActionPreference = "Stop"
# 语料定位（先到先得）:
#   1. <当前目录>/src/books   —— 宿主项目 live 语料
#   2. <仓库>/src/books       —— 技能位于 <仓库>/.claude/skills/ 时的 legacy 位置
#   3. 技能自带 corpus/       —— 便携兜底
$sourcesDir = $null
foreach ($c in @((Join-Path (Get-Location) "src\books"),
                 (Join-Path $PSScriptRoot "..\..\..\..\src\books"),
                 (Join-Path $PSScriptRoot "..\corpus"))) {
    if (Test-Path (Join-Path $c "01.正文")) {
        $sourcesDir = (Resolve-Path $c).Path
        break
    }
}
if (-not $sourcesDir) {
    Write-Error "找不到语料目录（试过: 当前目录 src\books、仓库 src\books、技能 corpus\）"
    exit 1
}

$sourceMap = @{
    "01.正文"      = "正文"
    "02.练习手册"   = "练习手册"
    "03.教师指南"   = "教师指南"
    "04.词汇解释"   = "词汇解释"
    "05.补编：心理治疗目的、过程与行业" = "补编"
}

$targets = if ($Source -eq "all") { $sourceMap.Keys } else { @($Source) }

Write-Output "🔍 ACIM 语料搜索"
Write-Output ("─" * 60)
Write-Output "查询: $Query"
Write-Output "范围: $($targets -join ', ')"
Write-Output ""

$totalHits = 0
foreach ($file in $targets) {
    $path = Join-Path $sourcesDir $file
    if (-not (Test-Path $path)) {
        Write-Warning "目录不存在: $path"
        continue
    }

    $label = $sourceMap[$file]
    Write-Output "📖 [$label] $file"
    Write-Output ("─" * 60)

    # 递归取所有 .md，一次 Select-String；-CaseSensitive 按开关拼（修复跑两遍 bug）
    $mdFiles = @(Get-ChildItem -Path $path -Recurse -Filter *.md -File -ErrorAction SilentlyContinue)
    if ($mdFiles.Count -eq 0) {
        Write-Output "命中: 0"
        Write-Output ""
        continue
    }
    $selectArgs = @{
        Path    = $mdFiles.FullName
        Pattern = $Query
        Context = $Context
    }
    if ($CaseSensitive) { $selectArgs['CaseSensitive'] = $true }
    $hits = Select-String @selectArgs

    $hitCount = if ($hits) { @($hits).Count } else { 0 }
    Write-Output "命中: $hitCount"

    if ($hits -and $MaxHits -gt 0) {
        $shown = $hits | Select-Object -First $MaxHits
        $shown | ForEach-Object {
            $lineNum = $_.LineNumber
            $lineText = $_.Line.Trim()
            if ($lineText.Length -gt 200) {
                $lineText = $lineText.Substring(0,200) + "..."
            }
            # 相对路径（去掉 $sourcesDir 前缀，保留 source/dir/.../file.md）
            $relPath = $_.Path.Replace($sourcesDir, "").TrimStart('\','/')
            Write-Output "  $relPath : [行 $lineNum] $lineText"
        }
        if ($hitCount -gt $MaxHits) {
            Write-Output "  ... (还有 $($hitCount - $MaxHits) 条未显示)"
        }
    }
    Write-Output ""
    $totalHits += $hitCount
}

Write-Output ("─" * 60)
Write-Output "总命中: $totalHits"
