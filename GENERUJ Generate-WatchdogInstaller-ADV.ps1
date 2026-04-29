$root      = "C:\Users\User\Desktop\todo-hybrid-max"
$gui       = "$root\Watchdog.GUI"
$installer = "$root\Watchdog.GUI.Installer"

Write-Host "Tworzenie zaawansowanego instalatora MSI..." -ForegroundColor Green

# 1. Sprawdzenie WiX
$wixPaths = @(
    "C:\Program Files (x86)\WiX Toolset v3.11\bin",
    "C:\Program Files\WiX Toolset v3.11\bin",
    "C:\Program Files (x86)\WiX Toolset v3.14\bin",
    "C:\Program Files\WiX Toolset v3.14\bin"
)

$wix = $wixPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $wix) {
    Write-Host "❌ WiX Toolset nie znaleziony! Zainstaluj WiX 3.11/3.14 i uruchom ponownie." -ForegroundColor Red
    exit 1
}

$candle = Join-Path $wix "candle.exe"
$light  = Join-Path $wix "light.exe"

Write-Host "WiX znaleziony w: $wix" -ForegroundColor Yellow

# 2. Upewnij się, że GUI jest opublikowane
if (-not (Test-Path "$gui\bin\Release\net10.0-windows\publish\Watchdog.GUI.exe")) {
    Write-Host "Publikuję Watchdog.GUI (Release)..." -ForegroundColor Yellow
    Push-Location $gui
    dotnet publish -c Release
    Pop-Location
}

# 3. Folder instalatora
New-Item -ItemType Directory -Force -Path $installer | Out-Null

# 4. Branding – placeholdery
$banner = Join-Path $installer "banner.bmp"
$dialog = Join-Path $installer "dialog.bmp"
$icon   = Join-Path $installer "icon.ico"

if (-not (Test-Path $banner)) {
    # proste puste pliki – możesz podmienić na własne grafiki
    New-Item -ItemType File -Path $banner | Out-Null
}
if (-not (Test-Path $dialog)) {
    New-Item -ItemType File -Path $dialog | Out-Null
}
if (-not (Test-Path $icon)) {
    New-Item -ItemType File -Path $icon | Out-Null
}

# 5. Product.wxs (ADV)
@'
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

    <!-- Branding -->
    <WixVariable Id="WixUIBannerBmp" Value="banner.bmp" />
    <WixVariable Id="WixUIDialogBmp" Value="dialog.bmp" />
    <WixVariable Id="WixUIIcon"      Value="icon.ico" />

    <UIRef Id="WixUI_InstallDir" />

    <!-- Ścieżka instalacji -->
    <Property Id="INSTALLFOLDER" Value="C:\Users\User\Desktop\todo-hybrid-max\Watchdog.GUI" />

    <Directory Id="TARGETDIR" Name="SourceDir">
      <Directory Id="INSTALLFOLDER" Name="Watchdog.GUI" />

      <Directory Id="DesktopFolder" Name="Desktop" />

      <Directory Id="ProgramMenuFolder">
        <Directory Id="WatchdogMenu" Name="Watchdog GUI" />
      </Directory>
    </Directory>

    <!-- Komponent: usługa WatchdogService -->
    <DirectoryRef Id="INSTALLFOLDER">
      <Component Id="WatchdogServiceComponent" Guid="11111111-1111-1111-1111-111111111111">
        <File Id="WatchdogServiceExe"
              Source="C:\Users\User\Desktop\todo-hybrid-max\Watchdog\bin\Release\net10.0\publish\Watchdog.exe"
              KeyPath="yes" />

        <ServiceInstall
            Id="WatchdogServiceInstaller"
            Name="WatchdogService"
            DisplayName="Watchdog Service"
            Description="Hybrid monitoring service"
            Start="auto"
            Type="ownProcess"
            ErrorControl="normal" />

        <ServiceControl
            Id="WatchdogServiceControl"
            Name="WatchdogService"
            Start="install"
            Stop="both"
            Remove="uninstall"
            Wait="yes" />
      </Component>

      <!-- Komponent: pliki GUI -->
      <Component Id="MainExecutable" Guid="22222222-2222-2222-2222-222222222222">
        <File Id="WatchdogGuiExe"
              Source="C:\Users\User\Desktop\todo-hybrid-max\Watchdog.GUI\bin\Release\net10.0-windows\publish\Watchdog.GUI.exe"
              KeyPath="yes" />
      </Component>

      <Component Id="AllFiles" Guid="33333333-3333-3333-3333-333333333333">
        <File Source="C:\Users\User\Desktop\todo-hybrid-max\Watchdog.GUI\bin\Release\net10.0-windows\publish\*" />
      </Component>
    </DirectoryRef>

    <!-- Skrót na pulpicie -->
    <DirectoryRef Id="DesktopFolder">
      <Component Id="DesktopShortcut" Guid="44444444-4444-4444-4444-444444444444">
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
      <Component Id="StartMenuShortcut" Guid="55555555-5555-5555-5555-555555555555">
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
      <ComponentRef Id="WatchdogServiceComponent" />
      <ComponentRef Id="MainExecutable" />
      <ComponentRef Id="AllFiles" />
      <ComponentRef Id="DesktopShortcut" />
      <ComponentRef Id="StartMenuShortcut" />
    </Feature>

  </Product>
</Wix>
'@ | Set-Content "$installer\Product.wxs"

Write-Host "Product.wxs wygenerowany." -ForegroundColor Green

# 6. Budowanie MSI
Write-Host "Budowanie instalatora (candle + light)..." -ForegroundColor Yellow

& $candle "$installer\Product.wxs" -o "$installer\Product.wixobj"
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Błąd w candle.exe" -ForegroundColor Red
    exit 1
}

& $light "$installer\Product.wixobj" -o "$installer\Watchdog.GUI.msi"
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Błąd w light.exe" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Instalator wygenerowany!" -ForegroundColor Green
Write-Host "MSI: $installer\Watchdog.GUI.msi" -ForegroundColor Cyan
