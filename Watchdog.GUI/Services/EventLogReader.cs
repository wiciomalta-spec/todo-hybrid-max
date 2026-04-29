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
