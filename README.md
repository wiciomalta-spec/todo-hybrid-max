# 🔔 TODO-HYBRID-MAX - Advanced Windows Monitoring System

A powerful hybrid monitoring system combining C# backend watchdog service with Windows GUI interface for real-time file system surveillance.

---

## 📋 Overview

**TODO-HYBRID-MAX** is a multi-component Windows monitoring platform:

| Component | Purpose | Language | Status |
|-----------|---------|----------|--------|
| **Watchdog** | Backend monitoring service | C# / .NET | ✅ Active |
| **Watchdog.GUI** | Windows desktop interface | C# / WPF | ✅ Active |
| **Watchdog.GUI.Installer** | WiX-based installer package | C# / WiX | ✅ Ready |

---

## 🏗️ Architecture

```
todo-hybrid-max/
├── Watchdog/                      # Core service
│   ├── Program.cs                 # Windows service entry point
│   ├── WatchdogService.cs         # Main logic
│   └── appsettings.json           # Service config
│
├── Watchdog.GUI/                  # GUI Application
│   ├── Program.cs                 # GUI entry
│   ├── MainWindow.xaml            # WPF interface
│   └── ViewModels/                # MVVM pattern
│
├── Watchdog.GUI.Installer/        # Installer
│   ├── Program.cs                 # Installer logic
│   └── wix-main/                  # WiX toolkit files
│
├── Generate-WatchdogGUI.ps1       # GUI generator script
├── Generate-WatchdogInstaller.ps1 # Installer generator
├── auto_update_and_run.ps1        # Auto-update runner
├── setup.ps1                      # Setup script
└── build.ps1                      # Build orchestration
```

---

## ⚙️ System Requirements

- **OS:** Windows 10/11 or Windows Server 2019+
- **.NET:** .NET 6.0+ Runtime & SDK
- **Visual Studio:** 2022 Community/Professional (for development)
- **Admin Rights:** Required for service installation

---

## 🚀 Quick Start

### 1️⃣ Build the Project

```powershell
# Run the build script
.\build.ps1

# Or manual build
dotnet build -c Release
```

### 2️⃣ Install as Windows Service

```powershell
# Run installer with admin privileges
.\install-service.ps1
```

### 3️⃣ Launch GUI

```powershell
# Run GUI application
cd Watchdog.GUI
dotnet run
```

### 4️⃣ Auto-Update & Run

```powershell
# Handles update check + auto-restart
.\auto_update_and_run.ps1
```

---

## 📊 Core Functionality

### **Watchdog Service** (Backend)
- ✅ Real-time file system monitoring
- ✅ Watches target directory: `C:\Users\User\Desktop\todo-hybrid-max`
- ✅ Event logging: CREATE, CHANGE, DELETE, RENAME
- ✅ Windows service integration (auto-start)
- ✅ Structured logging with timestamps

**Event Types Monitored:**
```
[CREATE]  - New file created
[CHANGE]  - File modified
[DELETE]  - File removed
[RENAME]  - File renamed
```

### **GUI Application** (Frontend)
- 🖼️ Real-time event dashboard
- 📈 Performance metrics visualization
- 🔧 Service configuration interface
- 📋 Event history log viewer
- 🎛️ Control panel for start/stop/restart

### **Auto-Update System**
- 🔄 Check for new versions
- 📦 Automated backup before update
- 🔁 Graceful restart handling
- 📝 Update logs

---

## 🛠️ PowerShell Scripts

### `setup.ps1` - Initial Setup
```powershell
.\setup.ps1
```
- Validates .NET runtime
- Creates required directories
- Configures permissions
- Initializes database/config files

### `auto_update_and_run.ps1` - Production Runner
```powershell
.\auto_update_and_run.ps1
```
- Checks for updates
- Applies updates if available
- Starts monitoring service
- Monitors for crashes

### `Generate-WatchdogGUI.ps1` - GUI Builder
```powershell
.\Generate-WatchdogGUI.ps1
```
- Compiles GUI components
- Generates executable
- Creates GUI installer

### `install-service.ps1` - Service Registration
```powershell
# Must run as Administrator
.\install-service.ps1
```
- Registers watchdog as Windows service
- Sets auto-start on boot
- Configures service permissions

---

## 📝 Configuration

### Watchdog Service Settings

Edit `Watchdog/appsettings.json`:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft": "Warning"
    }
  },
  "WatchdogSettings": {
    "TargetDirectory": "C:\\Users\\User\\Desktop\\todo-hybrid-max",
    "IncludeSubdirectories": true,
    "EnableRaisingEvents": true
  }
}
```

### GUI Settings

Edit `Watchdog.GUI/appsettings.json`:

```json
{
  "ServiceConnection": {
    "ServiceName": "WatchdogService",
    "RefreshInterval": 1000
  }
}
```

---

## 🔍 Monitoring Events

The watchdog monitors and logs:

| Event | Trigger | Example Log |
|-------|---------|-------------|
| CREATE | File added | `[CREATE] C:\...\newfile.txt` |
| CHANGE | File modified | `[CHANGE] C:\...\config.json` |
| DELETE | File removed | `[DELETE] C:\...\backup.zip` |
| RENAME | File renamed | `[RENAME] old.txt -> new.txt` |

### View Logs

**Windows Event Viewer:**
```
Event Viewer → Windows Logs → Application → Source: "Watchdog"
```

**Local Log File:**
```
%APPDATA%\WatchdogService\logs\watchdog.log
```

---

## 🧪 Testing

### Unit Tests
```powershell
dotnet test --configuration Release
```

### Integration Tests
```powershell
dotnet test --filter Category=Integration
```

### Manual Service Test
```powershell
# Check service status
Get-Service WatchdogService

# Start service
Start-Service WatchdogService

# View logs
Get-EventLog Application -Source Watchdog -Newest 20
```

---

## 🐛 Troubleshooting

### Service Won't Start
```powershell
# Check service status
Get-Service WatchdogService | Select-Object Status, StartType

# View recent errors
Get-EventLog Application -Source Watchdog -Newest 10
```

### GUI Won't Connect
```powershell
# Verify service is running
Get-Service WatchdogService

# Check firewall (if using remote)
netstat -an | findstr "localhost:5000"
```

### High CPU Usage
- Reduce monitored directory size
- Exclude temporary folders in settings
- Increase refresh interval in GUI

---

## 📦 Installation Methods

### Method 1: MSI Installer (Recommended)
```powershell
# Generate installer
.\Generate-WatchdogInstaller.ps1

# Run installer
msiexec /i Watchdog.GUI.Installer.msi
```

### Method 2: Direct Service Installation
```powershell
# Build and install manually
dotnet build -c Release
.\install-service.ps1
```

### Method 3: Chocolatey (Future)
```powershell
# When published to Chocolatey
choco install todo-hybrid-max
```

---

## 🔗 Project Links

- 📚 **Documentation**: `/docs`
- 📋 **Changelog**: `CHANGELOG_*.txt`
- 🏗️ **Project Structure**: Auto-generated
- 📱 **Installer Components**: `Watchdog.GUI.Installer/`

---

## 📄 License

See LICENSE file for terms and conditions.

---

## 👥 Contributing

To contribute:

1. Create a feature branch
2. Make your changes
3. Run tests: `dotnet test`
4. Submit PR with description

---

## 📞 Support

For issues or questions:
- 📧 File an issue on GitHub
- 💬 Check existing issues
- 📖 Review documentation

---

## 🔄 Version History

| Version | Date | Status |
|---------|------|--------|
| 1.0.0 | 2026-07 | Release |
| 0.9.0 | 2026-06 | Beta |
| 0.5.0 | 2026-05 | Alpha |

---

## ✨ Features Roadmap

- [ ] Network monitoring (remote service)
- [ ] Database logging integration
- [ ] REST API for remote control
- [ ] Cross-platform support (Linux/macOS)
- [ ] Docker containerization
- [ ] Advanced analytics dashboard
- [ ] Machine learning anomaly detection

---

**Built with ❤️ | Last Updated: 2026-07-06**
