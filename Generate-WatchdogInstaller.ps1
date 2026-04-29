$root = "C:\Users\User\Desktop\todo-hybrid-max"
$gui = "$root\Watchdog.GUI"
$installer = "$root\Watchdog.GUI.Installer"

Write-Host "Tworzenie instalatora MSI..." -ForegroundColor Green

# Tworzenie folderu instalatora
New-Item -ItemType Directory -Force -Path $installer | Out-Null

# ============================
# 1. Product.wxs
# ============================
@"
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">

  <Product
      Id="*"
      Name="Watchdog GUI"
      Language="1033"
      Version="1.0.0.0"
      Manufacturer="Bartosz"
      UpgradeCode="A1234567-BBBB-4444-9999-ABCDEF123456">

    <Package InstallerVersion="500"
             Compressed="yes"
             InstallScope="perMachine" />

    <MediaTemplate />

    <!-- Ścieżka instalacji -->
    <Property Id="INSTALLFOLDER" Value="C:\Users\User\Desktop\todo-hybrid-max\Watchdog.GUI" />

    <Directory Id="TARGETDIR" Name="SourceDir">
      <Directory Id="INSTALLFOLDER" Name="Watchdog.GUI" />

      <Directory Id="DesktopFolder" Name="Desktop" />

      <Directory Id="ProgramMenuFolder">
        <Directory Id="WatchdogMenu" Name="Watchdog GUI" />
      </Directory>
    </Directory>

    <!-- Pliki -->
    <DirectoryRef Id="INSTALLFOLDER">
      <Component Id="MainExecutable" Guid="*">
        <File Id="WatchdogExe"
              Source="$gui\bin\Release\net10.0-windows\publish\Watchdog.GUI.exe"
              KeyPath="yes" />
      </Component>

      <Component Id="AllFiles" Guid="*">
        <File Source="$gui\bin\Release\net10.0-windows\publish\*" />
      </Component>
    </DirectoryRef>

    <!-- Skrót na pulpicie -->
    <DirectoryRef Id="DesktopFolder">
      <Component Id="DesktopShortcut" Guid="*">
        <Shortcut Id="DesktopShortcutLink"
                  Name="Watchdog GUI"
                  Target="[INSTALLFOLDER]\Watchdog.GUI.exe"
                  WorkingDirectory="INSTALLFOLDER" />
        <RegistryValue Root="HKCU"
                       Key="Software\WatchdogGUI"
                       Name="installed"
                       Type="integer"
                       Value="1"
                       KeyPath="yes" />
      </Component>
    </DirectoryRef>

    <!-- Skrót w menu Start -->
    <DirectoryRef Id="WatchdogMenu">
      <Component Id="StartMenuShortcut" Guid="*">
        <Shortcut Id="StartMenuShortcutLink"
                  Name="Watchdog GUI"
                  Target="[INSTALLFOLDER]\Watchdog.GUI.exe"
                  WorkingDirectory="INSTALLFOLDER" />
        <RegistryValue Root="HKCU"
                       Key="Software\WatchdogGUI"
                       Name="installed2"
                       Type="integer"
                       Value="1"
                       KeyPath="yes" />
      </Component>
    </DirectoryRef>

    <!-- Feature -->
    <Feature Id="MainFeature" Title="Watchdog GUI" Level="1">
      <ComponentRef Id="MainExecutable" />
      <ComponentRef Id="AllFiles" />
      <ComponentRef Id="DesktopShortcut" />
      <ComponentRef Id="StartMenuShortcut" />
    </Feature>

  </Product>
</Wix>
"@ | Set-Content "$installer\Product.wxs"

# ============================
# 2. Tworzenie projektu WiX
# ============================
Write-Host "Budowanie instalatora..." -ForegroundColor Yellow

# Lokalizacja narzędzi WiX (domyślna)
$wix = "C:\Program Files (x86)\WiX Toolset v3.11\bin"

$candle = Join-Path $wix "candle.exe"
$light  = Join-Path $wix "light.exe"

# Kompilacja .wxs → .wixobj
& $candle "$installer\Product.wxs" -o "$installer\Product.wixobj"

# Linkowanie → MSI
& $light "$installer\Product.wixobj" -o "$installer\Watchdog.GUI.msi"

Write-Host "Instalator wygenerowany!" -ForegroundColor Green
Write-Host "Plik MSI: $installer\Watchdog.GUI.msi" -ForegroundColor Cyan
