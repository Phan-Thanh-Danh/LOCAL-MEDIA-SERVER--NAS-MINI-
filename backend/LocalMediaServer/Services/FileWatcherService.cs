using LocalMediaServer.Hubs;
using Microsoft.AspNetCore.SignalR;
using Microsoft.Extensions.Options;

namespace LocalMediaServer.Services;

public class FileWatcherService : BackgroundService
{
    private readonly ILogger<FileWatcherService> _logger;
    private readonly IHubContext<MediaHub> _hubContext;
    private readonly MediaServerOptions _options;
    private readonly FileSystemWatcher _watcher;

    public FileWatcherService(ILogger<FileWatcherService> logger, IHubContext<MediaHub> hubContext, IOptions<MediaServerOptions> options)
    {
        _logger = logger;
        _hubContext = hubContext;
        _options = options.Value;

        Directory.CreateDirectory(_options.RootPath);

        _watcher = new FileSystemWatcher(_options.RootPath)
        {
            IncludeSubdirectories = true,
            NotifyFilter = NotifyFilters.FileName | NotifyFilters.DirectoryName | NotifyFilters.LastWrite | NotifyFilters.Size
        };

        _watcher.Created += OnChanged;
        _watcher.Deleted += OnChanged;
        _watcher.Changed += OnChanged;
        _watcher.Renamed += OnRenamed;
    }

    protected override Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _watcher.EnableRaisingEvents = true;
        _logger.LogInformation("File watcher started for {RootPath}", _options.RootPath);
        return Task.CompletedTask;
    }

    private async void OnChanged(object sender, FileSystemEventArgs e)
    {
        await _hubContext.Clients.All.SendAsync("FileChanged", e.FullPath, e.ChangeType.ToString());
    }

    private async void OnRenamed(object sender, RenamedEventArgs e)
    {
        await _hubContext.Clients.All.SendAsync("FileRenamed", e.OldFullPath, e.FullPath);
    }
}
