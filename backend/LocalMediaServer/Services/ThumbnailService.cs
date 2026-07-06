using System.IO;
using System.Threading.Tasks;
using Xabe.FFmpeg;
using Xabe.FFmpeg.Downloader;
using LocalMediaServer.Services;
using Microsoft.Extensions.Options;
using System;

namespace LocalMediaServer.Services;

public class ThumbnailService
{
    private readonly MediaServerOptions _options;
    private readonly string _thumbnailsCacheDir;
    private bool _ffmpegReady = false;
    private static readonly SemaphoreSlim _downloadLock = new SemaphoreSlim(1, 1);
    private static readonly SemaphoreSlim _processLock = new SemaphoreSlim(Environment.ProcessorCount);

    public ThumbnailService(IOptions<MediaServerOptions> options)
    {
        _options = options.Value;
        _thumbnailsCacheDir = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, ".thumbnails");
        Directory.CreateDirectory(_thumbnailsCacheDir);
        
        FFmpeg.SetExecutablesPath(AppDomain.CurrentDomain.BaseDirectory);
    }

    public async Task InitializeFFmpegAsync()
    {
        if (_ffmpegReady) return;

        await _downloadLock.WaitAsync();
        try
        {
            if (_ffmpegReady) return;
            
            var ffmpegPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "ffmpeg.exe");
            if (!File.Exists(ffmpegPath))
            {
                Console.WriteLine("Đang tải FFmpeg để xử lý Video Thumbnail...");
                await FFmpegDownloader.GetLatestVersion(FFmpegVersion.Official, AppDomain.CurrentDomain.BaseDirectory);
                Console.WriteLine("Tải FFmpeg thành công.");
            }
            
            _ffmpegReady = true;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Lỗi khi tải FFmpeg: {ex.Message}");
        }
        finally
        {
            _downloadLock.Release();
        }
    }

    public async Task<string?> GetThumbnailAsync(string videoAbsolutePath)
    {
        await InitializeFFmpegAsync();

        try
        {
            // Tạo tên file cache dựa trên độ dài, tên và ngày sửa để tránh trùng
            var fileInfo = new FileInfo(videoAbsolutePath);
            var hash = $"{fileInfo.Name}_{fileInfo.Length}_{fileInfo.LastWriteTimeUtc.Ticks}".GetHashCode().ToString("X");
            var thumbnailPath = Path.Combine(_thumbnailsCacheDir, $"{hash}.jpg");

            if (File.Exists(thumbnailPath))
            {
                return thumbnailPath;
            }

            // Trích xuất khung hình ở giây thứ 5
            var mediaInfo = await FFmpeg.GetMediaInfo(videoAbsolutePath);
            var videoStream = mediaInfo.VideoStreams.FirstOrDefault();
            
            if (videoStream == null) return null;

            // Nếu video ngắn hơn 5s, lấy ở 1/2 video
            var ts = TimeSpan.FromSeconds(5);
            if (mediaInfo.Duration < ts)
            {
                ts = TimeSpan.FromSeconds(mediaInfo.Duration.TotalSeconds / 2);
            }

            await _processLock.WaitAsync();
            try
            {
                var conversion = FFmpeg.Conversions.New()
                    .AddParameter($"-ss {ts.TotalSeconds}")
                    .AddParameter($"-i \"{videoAbsolutePath}\"")
                    .AddParameter("-vframes 1")
                    .AddParameter("-vf \"scale=480:-1\"")
                    .AddParameter("-threads 1")
                    .SetOutput(thumbnailPath);
                    
                await conversion.Start();
            }
            finally
            {
                _processLock.Release();
            }

            if (File.Exists(thumbnailPath))
            {
                return thumbnailPath;
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Lỗi tạo thumbnail: {ex.Message}");
        }

        return null;
    }
}
