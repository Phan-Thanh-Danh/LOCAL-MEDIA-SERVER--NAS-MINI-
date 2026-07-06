using LocalMediaServer.Hubs;
using Microsoft.AspNetCore.SignalR;
using Microsoft.Extensions.Options;

namespace LocalMediaServer.Services;

public class FileWatcherService : BackgroundService
{
    private readonly ILogger<FileWatcherService> _logger;
    private readonly IHubContext<MediaHub> _hubContext;
    private readonly MediaServerOptions _options;
    private readonly ThumbnailService _thumbnailService;
    private readonly FileSystemWatcher _watcher;

    public FileWatcherService(ILogger<FileWatcherService> logger, IHubContext<MediaHub> hubContext, IOptions<MediaServerOptions> options, ThumbnailService thumbnailService)
    {
        _logger = logger;
        _hubContext = hubContext;
        _options = options.Value;
        _thumbnailService = thumbnailService;

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

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _watcher.EnableRaisingEvents = true;
        _logger.LogInformation("File watcher started for {RootPath}", _options.RootPath);
        
        // Chạy ngầm quét toàn bộ video để tạo Thumbnail trước
        _ = Task.Run(async () => {
            _logger.LogInformation("Bắt đầu tiến trình quét và tạo Thumbnail ngầm...");
            var videoFiles = Directory.GetFiles(_options.RootPath, "*.*", SearchOption.AllDirectories)
                .Where(s => s.EndsWith(".mp4", StringComparison.OrdinalIgnoreCase) || 
                            s.EndsWith(".mkv", StringComparison.OrdinalIgnoreCase) ||
                            s.EndsWith(".avi", StringComparison.OrdinalIgnoreCase) ||
                            s.EndsWith(".mov", StringComparison.OrdinalIgnoreCase));
                            
            foreach (var file in videoFiles)
            {
                if (stoppingToken.IsCancellationRequested) break;
                await _thumbnailService.GetThumbnailAsync(file);
            }
            _logger.LogInformation("Đã hoàn tất tạo Thumbnail ngầm cho toàn bộ video.");
        }, stoppingToken);
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
