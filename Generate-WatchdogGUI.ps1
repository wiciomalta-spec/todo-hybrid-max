$root = "C:\Users\User\Desktop\todo-hybrid-max\Watchdog.GUI"

Write-Host "Tworzenie projektu Watchdog.GUI..." -ForegroundColor Green

# Tworzenie struktury katalogów
New-Item -ItemType Directory -Force -Path $root | Out-Null
New-Item -ItemType Directory -Force -Path "$root\Services" | Out-Null
New-Item -ItemType Directory -Force -Path "$root\Assets" | Out-Null

# ============================
# 1. Watchdog.GUI.csproj
# ============================
@"
<Project Sdk="Microsoft.NET.Sdk.WindowsDesktop">
  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net10.0-windows</TargetFramework>
    <UseWPF>true</UseWPF>
  </PropertyGroup>

  <ItemGroup>
    <Reference Include="System.Windows.Forms" />
    <Reference Include="System.Drawing" />
  </ItemGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.PowerShell.SDK" Version="7.4.0" />
  </ItemGroup>
</Project>
"@ | Set-Content "$root\Watchdog.GUI.csproj"

# ============================
# 2. App.xaml
# ============================
@"
<Application x:Class="Watchdog.GUI.App"
             xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             StartupUri="MainWindow.xaml">
    <Application.Resources>
    </Application.Resources>
</Application>
"@ | Set-Content "$root\App.xaml"

# ============================
# 3. App.xaml.cs
# ============================
@"
using System.Windows;

namespace Watchdog.GUI
{
    public partial class App : Application
    {
    }
}
"@ | Set-Content "$root\App.xaml.cs"

# ============================
# 4. SettingsWindow.xaml
# ============================
@"
<Window x:Class="Watchdog.GUI.SettingsWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Settings"
        Width="400" Height="220"
        Background="#000000"
        FontFamily="Consolas"
        WindowStartupLocation="CenterOwner"
        WindowStyle="ToolWindow">

    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,10">
            <TextBlock Text="Folder:" Foreground="#00FF00" Width="80" VerticalAlignment="Center"/>
            <TextBox x:Name="FolderBox" Width="220" Margin="0,0,5,0"/>
            <Button Content="..." Width="30" Click="Browse_Click"/>
        </StackPanel>

        <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,0,0,10">
            <TextBlock Text="Log level:" Foreground="#00FF00" Width="80" VerticalAlignment="Center"/>
            <ComboBox x:Name="LogLevelBox" Width="120">
                <ComboBoxItem Content="Info" IsSelected="True"/>
                <ComboBoxItem Content="Debug"/>
                <ComboBoxItem Content="Error"/>
            </ComboBox>
        </StackPanel>

        <StackPanel Grid.Row="3" Orientation="Horizontal" HorizontalAlignment="Right">
            <Button Content="OK" Width="80" Margin="0,0,5,0" Click="Ok_Click"/>
            <Button Content="Cancel" Width="80" Click="Cancel_Click"/>
        </StackPanel>
    </Grid>
</Window>
"@ | Set-Content "$root\SettingsWindow.xaml"

# ============================
# 5. SettingsWindow.xaml.cs
# ============================
@"
using System.Windows;
using System.Windows.Forms;
using System.Windows.Controls;

namespace Watchdog.GUI
{
    public partial class SettingsWindow : Window
    {
        public string SelectedFolder { get; private set; }
        public string SelectedLogLevel { get; private set; }

        public SettingsWindow(string currentFolder, string currentLogLevel)
        {
            InitializeComponent();

            FolderBox.Text = currentFolder;

            foreach (var item in LogLevelBox.Items)
            {
                if (item is ComboBoxItem cbi &&
                    (string)cbi.Content == currentLogLevel)
                {
                    cbi.IsSelected = true;
                    break;
                }
            }
        }

        private void Browse_Click(object sender, RoutedEventArgs e)
        {
            using var dlg = new FolderBrowserDialog();
            if (dlg.ShowDialog() == System.Windows.Forms.DialogResult.OK)
                FolderBox.Text = dlg.SelectedPath;
        }

        private void Ok_Click(object sender, RoutedEventArgs e)
        {
            SelectedFolder = FolderBox.Text;
            if (LogLevelBox.SelectedItem is ComboBoxItem cbi)
                SelectedLogLevel = (string)cbi.Content;
            else
                SelectedLogLevel = "Info";

            DialogResult = true;
            Close();
        }

        private void Cancel_Click(object sender, RoutedEventArgs e)
        {
            DialogResult = false;
            Close();
        }
    }
}
"@ | Set-Content "$root\SettingsWindow.xaml.cs"

# ============================
# 6. Services/ProcessStats.cs
# ============================
@"
using System.Diagnostics;

namespace Watchdog.GUI.Services
{
    public class ProcessStats
    {
        private readonly string _processName;

        public ProcessStats(string processName)
        {
            _processName = processName;
        }

        public (double cpu, double ramMb) Get()
        {
            var procs = Process.GetProcessesByName(_processName);
            if (procs.Length == 0)
                return (0, 0);

            var p = procs[0];
            double ramMb = p.WorkingSet64 / 1024.0 / 1024.0;

            return (0, ramMb);
        }
    }
}
"@ | Set-Content "$root\Services\ProcessStats.cs"

# ============================
# 7. Services/LogReader.cs
# ============================
@"
using System.IO;
using System.Linq;

namespace Watchdog.GUI.Services
{
    public class LogReader
    {
        private readonly string _path;

        public LogReader(string path)
        {
            _path = path;
        }

        public string ReadLastLines(int count)
        {
            if (!File.Exists(_path))
                return "Log file not found.";

            return string.Join("\n", File.ReadLines(_path).Reverse().Take(count).Reverse());
        }
    }
}
"@ | Set-Content "$root\Services\LogReader.cs"

# ============================
# 8. Services/EventLogReader.cs
# ============================
@"
using System.Diagnostics;
using System.Linq;
using System.Text;

namespace Watchdog.GUI.Services
{
    public class EventLogReader
    {
        private readonly string _source;

        public EventLogReader(string source)
        {
            _source = source;
        }

        public string ReadLast(int count)
        {
            var log = new EventLog("Application");
            var entries = log.Entries.Cast<EventLogEntry>()
                .Where(e => e.Source == _source)
                .OrderByDescending(e => e.TimeGenerated)
                .Take(count)
                .OrderBy(e => e.TimeGenerated);

            var sb = new StringBuilder();
            foreach (var e in entries)
                sb.AppendLine($"{e.TimeGenerated:HH:mm:ss} | {e.EntryType} | {e.Message}");

            return sb.ToString();
        }
    }
}
"@ | Set-Content "$root\Services\EventLogReader.cs"

# ============================
# 9. Services/ServiceControl.cs
# ============================
@"
using System.ServiceProcess;

namespace Watchdog.GUI.Services
{
    public class ServiceControl
    {
        private readonly string _serviceName;

        public ServiceControl(string name)
        {
            _serviceName = name;
        }

        public void Start()
        {
            using var sc = new ServiceController(_serviceName);
            if (sc.Status != ServiceControllerStatus.Running)
                sc.Start();
        }

        public void Stop()
        {
            using var sc = new ServiceController(_serviceName);
            if (sc.Status != ServiceControllerStatus.Stopped)
                sc.Stop();
        }
    }
}
"@ | Set-Content "$root\Services\ServiceControl.cs"

# ============================
# 10. MainWindow.xaml
# ============================
@"
<Window x:Class="Watchdog.GUI.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="WATCHDOG CONTROL PANEL"
        Width="1000" Height="720"
        Background="#000000"
        FontFamily="Consolas"
        WindowStyle="None"
        ResizeMode="CanResize"
        AllowsTransparency="False">

    <Window.Resources>
        <Storyboard x:Key="Pulse">
            <DoubleAnimation Storyboard.TargetProperty="Opacity"
                             From="0.96" To="1.0"
                             Duration="0:0:0.4"
                             AutoReverse="True"
                             RepeatBehavior="Forever"/>
        </Storyboard>
    </Window.Resources>

    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="50"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="60"/>
        </Grid.RowDefinitions>

        <DockPanel Grid.Row="0">
            <TextBlock Text="WATCHDOG CONTROL PANEL"
                       Foreground="#00FF00"
                       FontSize="24"
                       VerticalAlignment="Center"
                       DockPanel.Dock="Left"/>

            <StackPanel Orientation="Horizontal" DockPanel.Dock="Right" VerticalAlignment="Center">
                <TextBlock x:Name="StatsText"
                           Foreground="#00FF00"
                           Margin="0,0,10,0"
                           VerticalAlignment="Center"
                           Text="CPU: 0%  RAM: 0 MB"/>
                <Button Content="SETTINGS"
                        Width="100"
                        Height="30"
                        Background="#111111"
                        Foreground="#00FFAA"
                        Margin="0,0,10,0"
                        Click="Settings_Click"/>
                <Button Content="X"
                        Width="40"
                        Height="40"
                        Background="#330000"
                        Foreground="#FF3333"
                        Click="Close_Click"/>
            </StackPanel>
        </DockPanel>

        <ScrollViewer Grid.Row="1" Background="#001100">
            <TextBlock x:Name="LogOutput"
                       Foreground="#00FF00"
                       FontSize="14"
                       TextWrapping="Wrap"/>
        </ScrollViewer>

        <TextBox Grid.Row="2"
                 x:Name="PsInput"
                 Background="#000000"
                 Foreground="#00FF00"
                 FontFamily="Consolas"
                 Height="30"
                 Margin="0,5,0,5"
                 Text="Get-Service WatchdogService" />

        <StackPanel Grid.Row="3" Orientation="Horizontal" HorizontalAlignment="Center" Spacing="20">

            <Button Content="START SERVICE"
                    Width="150" Height="40"
                    Background="#003300" Foreground="#00FF00"
                    Click="StartService_Click"/>

            <Button Content="STOP SERVICE"
                    Width="150" Height="40"
                    Background="#330000" Foreground="#FF3333"
                    Click="StopService_Click"/>

            <Button Content="REFRESH LOG"
                    Width="150" Height="40"
                    Background="#002200" Foreground="#00FF00"
                    Click="RefreshLog_Click"/>

            <Button Content="RUN PS"
                    Width="150" Height="40"
                    Background="#001133" Foreground="#00FFAA"
                    Click="RunPs_Click"/>

        </StackPanel>

    </Grid>
</Window>
"@ | Set-Content "$root\MainWindow.xaml"

# ============================
# 11. MainWindow.xaml.cs
# ============================
@"
using System;
using System.Linq;
using System.Windows;
using System.Windows.Forms;
using System.Windows.Threading;
using System.Management.Automation;
using Watchdog.GUI.Services;

namespace Watchdog.GUI
{
    public partial class MainWindow : Window
    {
        private readonly ServiceControl _service;
        private LogReader _log;
        private readonly EventLogReader _eventLog;
        private readonly ProcessStats _stats;
        private readonly DispatcherTimer _timer;
        private NotifyIcon _tray;
        private bool _cursorOn = true;

        private string _logFolder = @"C:\Users\User\Desktop\todo-hybrid-max\Watchdog";
        private string _logLevel = "Info";

        public MainWindow()
        {
            InitializeComponent();

            _service = new ServiceControl("WatchdogService");
            _log = new LogReader(System.IO.Path.Combine(_logFolder, "watchdog.log"));
            _eventLog = new EventLogReader("WatchdogService");
            _stats = new ProcessStats("Watchdog");

            InitTray();
            InitAutoRefresh();
            InitCRT();

            LoadLog();
        }

        private void InitCRT()
        {
            var sb = (System.Windows.Media.Animation.Storyboard)FindResource("Pulse");
            sb.Begin(this);
        }

        private void InitAutoRefresh()
        {
            _timer = new DispatcherTimer
            {
                Interval = TimeSpan.FromSeconds(1)
            };
            _timer.Tick += (s, e) => LoadLog();
            _timer.Start();
        }

        private void InitTray()
        {
            _tray = new NotifyIcon
            {
                Icon = System.Drawing.SystemIcons.Application,
                Visible = true,
                Text = "Watchdog Control Panel"
            };

            var menu = new ContextMenuStrip();
            menu.Items.Add("Start Service", null, (s, e) => _service.Start());
            menu.Items.Add("Stop Service", null, (s, e) => _service.Stop());
            menu.Items.Add("Show Panel", null, (s, e) => ShowWindow());
            menu.Items.Add("Exit", null, (s, e) => ExitApp());

            _tray.ContextMenuStrip = menu;
            _tray.DoubleClick += (s, e) => ShowWindow();
        }

        private void ShowWindow()
        {
            Show();
            WindowState = WindowState.Normal;
            Activate();
        }

        private void ExitApp()
        {
            _tray.Visible = false;
            _tray.Dispose();
            Application.Current.Shutdown();
        }

        protected override void OnStateChanged(EventArgs e)
        {
            base.OnStateChanged(e);
            if (WindowState == WindowState.Minimized)
                Hide();
        }

        protected override void OnClosed(EventArgs e)
        {
            _tray.Visible = false;
            _tray.Dispose();
            base.OnClosed(e);
        }

        private void LoadLog()
        {
            _log = new LogReader(System.IO.Path.Combine(_logFolder, "watchdog.log"));

            var fileLog = _log.ReadLastLines(200);
            var eventLog = _eventLog.ReadLast(50);

            var cursor = _cursorOn ? "_" : " ";
            _cursorOn = !_cursorOn;

            var (cpu, ram) = _stats.Get();
            StatsText.Text = $"CPU: {cpu:0}%  RAM: {ram:0} MB  |  Folder: {_logFolder}  |  Level: {_logLevel}";

            LogOutput.Text =
                fileLog +
                "\n\n=== EVENT LOG ===\n\n" +
                eventLog +
                "\n" + cursor;
        }

        private void StartService_Click(object sender, RoutedEventArgs e)
        {
            _service.Start();
            LoadLog();
        }

        private void StopService_Click(object sender, RoutedEventArgs e)
        {
            _service.Stop();
            LoadLog();
        }

        private void RefreshLog_Click(object sender, RoutedEventArgs e)
        {
            LoadLog();
        }

        private void RunPs_Click(object sender, RoutedEventArgs e)
        {
            using var ps = PowerShell.Create();
            ps.AddScript(PsInput.Text);
            var results = ps.Invoke();
            var output = string.Join("\n", results.Select(r => r.ToString()));

            LogOutput.Text += "\n\n=== PS OUT ===\n" + output;
        }

        private void Close_Click(object sender, RoutedEventArgs e)
        {
            ExitApp();
        }

        private void Settings_Click(object sender, RoutedEventArgs e)
        {
            var win = new SettingsWindow(_logFolder, _logLevel)
            {
                Owner = this
            };

            if (win.ShowDialog() == true)
            {
                _logFolder = win.SelectedFolder;
                _logLevel = win.SelectedLogLevel;
                LoadLog();
            }
        }
    }
}
"@ | Set-Content "$root\MainWindow.xaml.cs"

Write-Host "Projekt Watchdog.GUI został wygenerowany!" -ForegroundColor Green
