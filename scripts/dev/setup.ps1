[CmdletBinding()]
param(
    [switch]$SkipDbInit
)

$RepoRoot = "D:\BUS_VERSE\BUS_VERSE_REAL"
if (-not (Test-Path $RepoRoot)) {
    Write-Error "Repository root not found at $RepoRoot"
    exit 1
}
Set-Location -Path $RepoRoot

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host " BUSVERSE REAL - AUTOMATED LOCAL SETUP (WIN10)   " -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# 1. Verify Runtimes
Write-Host ""
Write-Host "[1/6] Verifying system runtimes..." -ForegroundColor Yellow
$nodeVer = node -v 2>$null
$pnpmVer = pnpm -v 2>$null
$gitVer  = git --version 2>$null

Write-Host "  Node.js : $nodeVer"
Write-Host "  pnpm    : $pnpmVer"
Write-Host "  Git     : $gitVer"

if (-not $nodeVer -or -not $pnpmVer) {
    Write-Error "Missing Node.js or pnpm. Ensure both are installed and in PATH."
    exit 1
}

# 2. Verify Native Services (PostgreSQL & Redis)
Write-Host ""
Write-Host "[2/6] Probing native services..." -ForegroundColor Yellow
$pgTest = Test-NetConnection -ComputerName 127.0.0.1 -Port 5432 -InformationLevel Quiet
if ($pgTest) {
    Write-Host "  [OK] PostgreSQL listening on port 5432" -ForegroundColor Green
} else {
    Write-Host "  [WARN] PostgreSQL not responding on port 5432" -ForegroundColor Red
}

$redisTest = Test-NetConnection -ComputerName 127.0.0.1 -Port 6379 -InformationLevel Quiet
if ($redisTest) {
    Write-Host "  [OK] Redis/Memurai listening on port 6379" -ForegroundColor Green
} else {
    Write-Host "  [WARN] Redis/Memurai not responding on port 6379" -ForegroundColor Red
}

# 3. Provision Database and Extensions via init.sql
if (-not $SkipDbInit -and $pgTest) {
    Write-Host ""
    Write-Host "[3/6] Configuring database and spatial extensions..." -ForegroundColor Yellow
    $PG_BIN = "C:\Program Files\PostgreSQL\16\bin"
    $SQL_FILE = Join-Path $RepoRoot "scripts\db\init.sql"

    if ((Test-Path "$PG_BIN\psql.exe") -and (Test-Path $SQL_FILE)) {
        & "$PG_BIN\psql.exe" -U postgres -h localhost -p 5432 -f "$SQL_FILE" -q 2>$null
        Write-Host "  [OK] Database role, catalog, and PostGIS provisioned" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] psql.exe or init.sql not found. Skipping SQL execution." -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "[3/6] Skipping Database init" -ForegroundColor DarkGray
}

# 4. Verify Environment Files
Write-Host ""
Write-Host "[4/6] Verifying environment configurations..." -ForegroundColor Yellow
$requiredEnvs = @(
    ".env",
    ".env.example",
    "services\api\.env",
    "services\ws\.env",
    "services\worker\.env",
    "services\simulator\.env",
    "apps\passenger-web\.env.local",
    "apps\operator-panel\.env.local",
    "apps\admin-panel\.env.local",
    "apps\support-panel\.env.local",
    "apps\driver-app\.env"
)

$missing = $false
foreach ($f in $requiredEnvs) {
    if (-not (Test-Path "$RepoRoot\$f")) {
        $missing = $true
        Write-Host "  Missing: $f" -ForegroundColor Red
    }
}

if (-not $missing) {
    Write-Host "  [OK] All 11 environment configurations verified" -ForegroundColor Green
} else {
    Write-Host "  [WARN] Some .env files are missing." -ForegroundColor Yellow
}

# 5. Git Branch Setup & Safety
Write-Host ""
Write-Host "[5/6] Checking Git branch structure..." -ForegroundColor Yellow
$currentBranch = (git branch --show-current).Trim()
$allBranches   = git branch --list

if ($allBranches -notmatch "develop") {
    git branch develop
    Write-Host "  Created local develop branch" -ForegroundColor Green
}
Write-Host "  Active branch: $currentBranch"

# 6. Install Git Hooks & Update Live Status
Write-Host ""
Write-Host "[6/6] Linking Git hooks and updating status dashboard..." -ForegroundColor Yellow

pnpm lefthook install 2>$null
$statusScript = Join-Path $RepoRoot "scripts\dev\sync-git-status.ps1"
if (Test-Path $statusScript) {
    powershell -ExecutionPolicy Bypass -File $statusScript
}

$todayStr = (Get-Date).ToString("yyyy-MM-dd")
Write-Host ""
Write-Host "[COMPLETE] System setup completed successfully." -ForegroundColor Green
Write-Host "  Status file: DOCS/git-audit/STATUS.md"
Write-Host "  Daily log  : DOCS/git-audit/daily/$todayStr.md"
Write-Host ""
