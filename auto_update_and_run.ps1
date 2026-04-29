<#
.SYNOPSIS
    Pełna automatyzacja: sprawdza aktualizacje, pobiera, robi backup, aktualizuje i uruchamia system.
    Uruchom w katalogu głównym projektu (todo-hybrid-max/).
#>

# --- KONFIGURACJA (dostosuj do swoich potrzeb) ---
$ProjectName = "Todo Hybrid MAX"
$LocalUpdateFile = "update.json"  # Lokalny plik z wersją
$RemoteUpdateUrl = "https://raw.githubusercontent.com/wiciomalta-spec/todo-hybrid-max/main/update.json"  # URL do zdalnego update.json
$BackupDir = "backups"  # Folder na backupy
$SetupScript = "setup.ps1"  # Skrypt do uruchomienia po aktualizacji
$TempDir = "$env:TEMP\$ProjectName-update"  # Folder tymczasowy

# --- FUNKCJE POMOCNICZE ---
function Write-Status([string]$Message, [string]$Color = "White") {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor $Color
}

function Get-LocalVersion {
    if (Test-Path $LocalUpdateFile) {
        try {
            $localUpdate = Get-Content $LocalUpdateFile | ConvertFrom-Json
            return $localUpdate.version
        } catch {
            Write-Status "Błąd odczytu lokalnego update.json: $_" -Color Red
            return "0.0.0"
        }
    }
    return "0.0.0"
}

function Get-RemoteUpdate {
    try {
        $remoteUpdate = Invoke-RestMethod -Uri $RemoteUpdateUrl -UseBasicParsing -ErrorAction Stop
        return $remoteUpdate
    } catch {
        Write-Status "Błąd pobierania zdalnego update.json: $_" -Color Red
        return $null
    }
}

function Create-Backup {
    param (
        [string]$BackupName
    )

    $backupPath = Join-Path $BackupDir $BackupName
    if (-not (Test-Path $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir | Out-Null
    }
    if (-not (Test-Path $backupPath)) {
        New-Item -ItemType Directory -Path $backupPath | Out-Null
    }

    # Kopiuj wszystkie pliki zdefiniowane w update.json (lub wszystkie, jeśli nie zdefiniowane)
    $remoteUpdate = Get-RemoteUpdate
    if ($remoteUpdate -and $remoteUpdate.files_to_replace) {
        foreach ($file in $remoteUpdate.files_to_replace) {
            if (Test-Path $file) {
                $dest = Join-Path $backupPath $file
                $parent = Split-Path $dest -Parent
                if (-not (Test-Path $parent)) {
                    New-Item -ItemType Directory -Path $parent | Out-Null
                }
                Copy-Item -Path $file -Destination $dest -Force
                Write-Status "Backup: $file -> $dest" -Color Cyan
            }
        }
    } else {
        # Jeśli nie ma listy plików, zrób backup całego katalogu (opcjonalnie)
        Write-Status "Brak listy plików do backupu. Pomijam." -Color Yellow
    }
}

function Download-Update([string]$Url, [string]$Destination) {
    try {
        if (-not (Test-Path $TempDir)) {
            New-Item -ItemType Directory -Path $TempDir | Out-Null
        }
        Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing
        return $true
    } catch {
        Write-Status "Błąd pobierania aktualizacji: $_" -Color Red
        return $false
    }
}

function Apply-Update([string]$ZipPath) {
    try {
        # Wypakuj ZIP
        Expand-Archive -Path $ZipPath -DestinationPath $TempDir -Force

        # Pobierz listę plików do zastąpienia
        $remoteUpdate = Get-RemoteUpdate
        if ($remoteUpdate -and $remoteUpdate.files_to_replace) {
            foreach ($file in $remoteUpdate.files_to_replace) {
                $source = Join-Path $TempDir $file
                $destination = Join-Path (Get-Location) $file

                if (Test-Path $source) {
                    if (Test-Path $destination) {
                        # Zrób backup przed zastąpieniem
                        Copy-Item -Path $destination -Destination (Join-Path $TempDir "backup_$file") -Force
                    }
                    Copy-Item -Path $source -Destination $destination -Force
                    Write-Status "Zastąpiono: $file" -Color Green
                } else {
                    Write-Status "Brak pliku w archiwum: $file" -Color Yellow
                }
            }
        } else {
            Write-Status "Brak listy plików do zastąpienia w update.json." -Color Yellow
            return $false
        }

        # Zaktualizuj lokalny update.json
        $remoteUpdate | ConvertTo-Json | Out-File $LocalUpdateFile -Force
        Write-Status "Zaktualizowano lokalny update.json." -Color Green

        return $true
    } catch {
        Write-Status "Błąd podczas zastępowania plików: $_" -Color Red
        return $false
    }
}

function Cleanup-Temp {
    if (Test-Path $TempDir) {
        Remove-Item $TempDir -Recurse -Force
        Write-Status "Wyczyszczono folder tymczasowy." -Color Cyan
    }
}

# --- GŁÓWNA LOGIKA ---
Write-Status "=== $ProjectName - Automatyczna aktualizacja i uruchomienie ===" -Color Magenta

# 1. Sprawdź lokalną wersję
$localVersion = Get-LocalVersion
Write-Status "Lokalna wersja: $localVersion" -Color White

# 2. Pobierz zdalną wersję
$remoteUpdate = Get-RemoteUpdate
if ($remoteUpdate -eq $null) {
    Write-Status "Nie można pobrać informacji o aktualizacji. Pomijam aktualizację." -Color Yellow
    $updateAvailable = $false
} else {
    $remoteVersion = $remoteUpdate.version
    Write-Status "Zdalna wersja: $remoteVersion" -Color White

    # 3. Porównaj wersje
    if ([version]$remoteVersion -gt [version]$localVersion) {
        $updateAvailable = $true
        Write-Status "Dostępna nowa wersja: $remoteVersion" -Color Green

        # 4. Pobierz aktualizację
        Write-Status "Pobieranie aktualizacji..." -Color Yellow
        $zipPath = "$TempDir\update.zip"
        if (Download-Update -Url $remoteUpdate.download_url -Destination $zipPath) {
            # 5. Zrób backup
            $backupName = "backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Write-Status "Tworzę backup: $backupName" -Color Cyan
            Create-Backup -BackupName $backupName

            # 6. Zastosuj aktualizację
            if (Apply-Update -ZipPath $zipPath) {
                Write-Status "Aktualizacja zakończona pomyślnie!" -Color Green
                Cleanup-Temp
            } else {
                Write-Status "Błąd podczas aktualizacji. Przywracanie backupu nie jest zautomatyzowane (ręczne przywrócenie z $BackupDir\$backupName)." -Color Red
                Cleanup-Temp
                exit 1
            }
        } else {
            Write-Status "Nie udało się pobrać aktualizacji." -Color Red
            Cleanup-Temp
            exit 1
        }
    } else {
        $updateAvailable = $false
        Write-Status "Masz najnowszą wersję ($localVersion)." -Color Green
    }
}

# 7. Uruchom setup.ps1 (jeśli istnieje)
if (Test-Path $SetupScript) {
    Write-Status "Uruchamiam $SetupScript..." -Color Cyan
    & .\$SetupScript
} else {
    Write-Status "Nie znaleziono skryptu $SetupScript." -Color Red
}

Write-Status "=== Zakończono ===" -Color Magenta