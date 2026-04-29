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
