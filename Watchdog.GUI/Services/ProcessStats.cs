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
