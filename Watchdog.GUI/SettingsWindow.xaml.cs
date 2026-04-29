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
