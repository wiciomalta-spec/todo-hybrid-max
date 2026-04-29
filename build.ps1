Write-Host "=== HYBRID AUTO-BUILD START ===" -ForegroundColor Cyan

$root = "C:\Users\User\Desktop\todo-hybrid-max"
$watchdog = "$root\Watchdog\Watchdog.csproj"
$pythonScripts = @(
    "$root\script1.py",
    "$root\script2.py"
)

# 1) Build C#
Write-Host "`n[1/4] Building C# project..." -ForegroundColor Yellow
dotnet build $watchdog
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed — stopping." -ForegroundColor Red
    exit
}

# 2) Run Python scripts
Write-Host "`n[2/4] Running Python scripts..." -ForegroundColor Yellow
foreach ($script in $pythonScripts) {
    if (Test-Path $script) {
        Write-Host "→ Running $script" -ForegroundColor Green
        python $script
    } else {
        Write-Host "→ Skipped (not found): $script" -ForegroundColor DarkYellow
    }
}

# 3) Find Watchdog.exe
Write-Host "`n[3/4] Locating Watchdog.exe..." -ForegroundColor Yellow
$exe = Get-ChildItem "$root\Watchdog\bin\Debug" -Recurse -Filter "Watchdog.exe" | Select-Object -First 1

if (!$exe) {
    Write-Host "❌ Watchdog.exe not found — build incomplete." -ForegroundColor Red
    exit
}

Write-Host "✔ Found: $($exe.FullName)" -ForegroundColor Green

# 4) Run Watchdog
Write-Host "`n[4/4] Starting Watchdog..." -ForegroundColor Yellow
& $exe.FullName

Write-Host "`n=== HYBRID AUTO-BUILD COMPLETE ===" -ForegroundColor Cyan
