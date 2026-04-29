using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System.IO;
using System.Threading;
using System.Threading.Tasks;

public class WatchdogService : BackgroundService
{
    private readonly ILogger<WatchdogService> _logger;
    private FileSystemWatcher _watcher;
    private readonly string _path = @"C:\Users\User\Desktop\todo-hybrid-max";

    public WatchdogService(ILogger<WatchdogService> logger)
    {
        _logger = logger;
    }

    protected override Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("WATCHDOG SERVICE START");

        if (!Directory.Exists(_path))
        {
            _logger.LogError("Path not found: {path}", _path);
            return Task.CompletedTask;
        }

        _watcher = new FileSystemWatcher(_path)
        {
            IncludeSubdirectories = true,
            EnableRaisingEvents = true
        };

        _watcher.Created += (s, e) => _logger.LogInformation("[CREATE] {0}", e.FullPath);
        _watcher.Changed += (s, e) => _logger.LogInformation("[CHANGE] {0}", e.FullPath);
        _watcher.Deleted += (s, e) => _logger.LogInformation("[DELETE] {0}", e.FullPath);
        _watcher.Renamed += (s, e) => _logger.LogInformation("[RENAME] {0} -> {1}", e.OldFullPath, e.FullPath);

        // Pętla życia usługi
        return Task.Run(async () =>
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                await Task.Delay(1000, stoppingToken);
            }
        }, stoppingToken);
    }

    public override void Dispose()
    {
        _watcher?.Dispose();
        base.Dispose();
    }
}
