<#
.SYNOPSIS
    Skrypt instalacyjny dla Todo Hybrid MAX.
    Instaluje zależności, uruchamia Web App i Desktop App.
#>

# --- USTAWIENIA ---
$ProjectName = "Todo Hybrid MAX"
$PythonRequiredVersion = "3.8"
$NodeRequiredVersion = "16.0"
$WebPort = 8000
$DesktopMain = "desktop\main.py"

# --- FUNKCJE POMOCNICZE ---
function Write-Status([string]$Message, [string]$Color = "White") {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor $Color
}

function Check-Python {
    try {
        $pythonVersion = (python --version 2>$null).Trim()
        if ($pythonVersion -match "Python (\d+\.\d+)") {
            $version = $matches[1]
            if ([version]$version -ge [version]$PythonRequiredVersion) {
                Write-Status "Python $version znaleziony." -Color Green
                return $true
            } else {
                Write-Status "Python $version jest za stary. Wymagana wersja: $PythonRequiredVersion+" -Color Red
                return $false
            }
        }
    } catch {
        Write-Status "Python nie jest zainstalowany." -Color Red
        return $false
    }
    return $false
}

function Check-Node {
    try {
        $nodeVersion = (node --version 2>$null).Trim()
        if ($nodeVersion -match "v(\d+\.\d+)") {
            $version = $matches[1]
            if ([version]$version -ge [version]$NodeRequiredVersion) {
                Write-Status "Node.js $version znaleziony." -Color Green
                return $true
            } else {
                Write-Status "Node.js $version jest za stary. Wymagana wersja: $NodeRequiredVersion+" -Color Red
                return $false
            }
        }
    } catch {
        Write-Status "Node.js nie jest zainstalowany." -Color Red
        return $false
    }
    return $false
}

function Install-Python {
    Write-Status "Instalowanie Python $PythonRequiredVersion..." -Color Yellow
    $pythonUrl = "https://www.python.org/ftp/python/3.11.4/python-3.11.4-amd64.exe"
    $installer = "$env:TEMP\python_installer.exe"
    Invoke-WebRequest -Uri $pythonUrl -OutFile $installer
    Start-Process -FilePath $installer -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait
    Remove-Item $installer
    Write-Status "Python zainstalowany. Proszę uruchomić skrypt ponownie." -Color Green
    exit 1
}

function Install-Node {
    Write-Status "Instalowanie Node.js $NodeRequiredVersion..." -Color Yellow
    $nodeUrl = "https://nodejs.org/dist/v18.17.1/node-v18.17.1-x64.msi"
    $installer = "$env:TEMP\node_installer.msi"
    Invoke-WebRequest -Uri $nodeUrl -OutFile $installer
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $installer /quiet" -Wait
    Remove-Item $installer
    Write-Status "Node.js zainstalowany. Proszę uruchomić skrypt ponownie." -Color Green
    exit 1
}

function Install-Python-Packages {
    Write-Status "Instalowanie zależności Python..." -Color Yellow
    if (Test-Path "requirements.txt") {
        python -m pip install --upgrade pip
        python -m pip install -r requirements.txt
        Write-Status "Zależności Python zainstalowane." -Color Green
    } else {
        Write-Status "Brak pliku requirements.txt." -Color Red
        exit 1
    }
}

function Start-WebApp {
    Write-Status "Uruchamianie Web App (port $WebPort)..." -Color Cyan
    $webDir = "web"
    if (Test-Path $webDir) {
        Start-Process -FilePath "python" -ArgumentList "-m http.server $WebPort --directory $webDir" -NoNewWindow
        Write-Status "Web App dostępny pod: http://localhost:$WebPort" -Color Green
    } else {
        Write-Status "Katalog $webDir nie istnieje." -Color Red
    }
}

function Start-DesktopApp {
    Write-Status "Uruchamianie Desktop App..." -Color Cyan
    if (Test-Path $DesktopMain) {
        Start-Process -FilePath "python" -ArgumentList $DesktopMain -NoNewWindow
        Write-Status "Desktop App uruchomiony." -Color Green
    } else {
        Write-Status "Plik $DesktopMain nie istnieje." -Color Red
    }
}

# --- GŁÓWNA LOGIKA ---
Write-Status "=== $ProjectName - Instalacja ===" -Color Magenta

# Sprawdź Python
if (-not (Check-Python)) {
    Install-Python
}

# Sprawdź Node.js (opcjonalnie)
if (-not (Check-Node)) {
    Write-Status "Node.js nie jest wymagany, ale zalecany do rozwoju Web App." -Color Yellow
    # Install-Node  # Odkomentuj, jeśli Node.js jest wymagany
}

# Zainstaluj zależności Python
Install-Python-Packages

# Uruchom aplikacje
Start-WebApp
Start-DesktopApp

Write-Status "=== Instalacja zakończona. Naciśnij dowolny klawisz, aby zamknąć. ===" -Color Magenta
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")