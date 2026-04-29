Write-Host "=== AUTO-UPDATE REPO START ===" -ForegroundColor Cyan

$root = "C:\Users\User\Desktop\todo-hybrid-max"
$versionFile = "$root\version.txt"
$backupDir = "$root\_backup"
$timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")

# 1) Backup
Write-Host "`n[1/6] Creating backup..." -ForegroundColor Yellow
if (!(Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
$backupPath = "$backupDir\backup_$timestamp.zip"
Compress-Archive -Path "$root\*" -DestinationPath $backupPath -Force
Write-Host "✔ Backup created: $backupPath" -ForegroundColor Green

# 2) Version bump
Write-Host "`n[2/6] Updating version..." -ForegroundColor Yellow
if (!(Test-Path $versionFile)) {
    "1.0.0" | Out-File $versionFile
}
$version = Get-Content $versionFile
$parts = $version.Split(".")
$parts[2] = [int]$parts[2] + 1
$newVersion = "$($parts[0]).$($parts[1]).$($parts[2])"
$newVersion | Out-File $versionFile
Write-Host "✔ Version updated: $version → $newVersion" -ForegroundColor Green

# 3) Git status
Write-Host "`n[3/6] Checking Git status..." -ForegroundColor Yellow
$changes = git -C $root status --porcelain
if (-not $changes) {
    Write-Host "ℹ No changes to commit." -ForegroundColor DarkYellow
    exit
}

# 4) Generate changelog
Write-Host "`n[4/6] Generating changelog..." -ForegroundColor Yellow
$changelog = "$root\CHANGELOG_$timestamp.txt"
$changes | Out-File $changelog
Write-Host "✔ Changelog saved: $changelog" -ForegroundColor Green

# 5) Commit + push
Write-Host "`n[5/6] Committing changes..." -ForegroundColor Yellow
git -C $root add .
git -C $root commit -m "Auto-update $timestamp | version $newVersion"
git -C $root push
Write-Host "✔ Changes pushed to repo" -ForegroundColor Green

# 6) Final log
Write-Host "`n[6/6] Auto-update complete." -ForegroundColor Green
Write-Host "=== AUTO-UPDATE REPO COMPLETE ===" -ForegroundColor Cyan
