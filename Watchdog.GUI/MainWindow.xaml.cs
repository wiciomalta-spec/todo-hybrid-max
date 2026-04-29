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
