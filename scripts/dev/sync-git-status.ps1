$RepoRoot = "D:\BUS_VERSE\BUS_VERSE_REAL"
Set-Location -Path $RepoRoot

$AuditDir = Join-Path $RepoRoot "DOCS\git-audit"
$DailyDir = Join-Path $AuditDir "daily"
if (-not (Test-Path $DailyDir)) { New-Item -ItemType Directory -Path $DailyDir -Force | Out-Null }

$Timestamp     = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
$DateStamp     = (Get-Date).ToString("yyyy-MM-dd")
$CurrentBranch = (git branch --show-current).Trim()
$LatestTag     = (git describe --tags --abbrev=0 2>$null)
if (-not $LatestTag) { $LatestTag = "v0.0.0 (Pre-release)" }

$RecentCommits  = git log -n 10 --pretty=format:"* **%h** - %s *(%cr by %an)*" 2>$null
$GitStatusShort = git status --short 2>$null

$statusTreeText = if ($GitStatusShort) { $GitStatusShort -join "`n" } else { "Working tree clean. No uncommitted changes." }
$commitsText    = if ($RecentCommits) {$RecentCommits -join "`n" } else { "* No commits yet on branch" }

$statusLines = @(
    "# Git Repository Status & Tracking",
    "",
    "**Last Synced:** $Timestamp IST  ",
    "**Current Active Branch:** $CurrentBranch  ",
    "**Latest Tag:** $LatestTag  ",
    "",
    "---",
    "",
    "## 1. Working Tree State",
    "",
    "````text",
    $statusTreeText,
    "````",
    "",
    "---",
    "",
    "## 2. Recent Commits (Last 10)",
    "",
    $commitsText,
    "",
    "---",
    "",
    "## 3. Branch Mapping Reference",
    "",
    "* **Production:** main (Locked, deploy only)",
    "* **Pre-Production:** staging (Verified builds)",
    "* **Integration Baseline:** develop (Active integration)",
    "* **Task Branch Pattern:** feat/*, fix/*, chore/*"
)

$statusFile = Join-Path $AuditDir "STATUS.md"
$statusLines | Set-Content -Path $statusFile -Encoding utf8

$DailyLogFile = Join-Path $DailyDir "$DateStamp.md"
$LastCommit = (git log -1 --pretty=format:"%s (%h)" 2>$null)
if (-not $LastCommit) { $LastCommit = "No commits yet" }
$treeState = if ($GitStatusShort) { "Dirty (uncommitted files present)" } else { "Clean" }

$dailyLines = @(
    "",
    "### Update: $Timestamp IST",
    "* **Branch:** $CurrentBranch",
    "* **Latest Commit:** $LastCommit",
    "* **Working Tree:** $treeState"
)

$dailyLines | Add-Content -Path $DailyLogFile -Encoding utf8
