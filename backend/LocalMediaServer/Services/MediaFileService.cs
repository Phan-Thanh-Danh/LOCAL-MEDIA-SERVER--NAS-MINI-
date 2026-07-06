using LocalMediaServer.DTOs;
using Microsoft.Extensions.Options;

namespace LocalMediaServer.Services;

public interface IMediaFileService
{
    FileItemDto[] ListDirectory(string? subPath);
    FileStream OpenReadStream(string relativePath);
    string GetAbsolutePath(string? subPath);
    string GetMimeType(string extension);
    string FormatSize(long size);
    string GetRelativePath(string absolutePath);
}

public class MediaFileService : IMediaFileService
{
    private readonly MediaServerOptions _options;
    private readonly FolderSecurityService _securityService;

    public MediaFileService(IOptions<MediaServerOptions> options, FolderSecurityService securityService)
    {
        _options = options.Value;
        _securityService = securityService;
    }

    public FileItemDto[] ListDirectory(string? subPath)
    {
        var absolutePath = GetAbsolutePath(subPath);
        if (!Directory.Exists(absolutePath))
        {
            throw new DirectoryNotFoundException($"Directory not found: {absolutePath}");
        }

        var entries = new List<FileItemDto>();
        foreach (var path in Directory.GetFileSystemEntries(absolutePath))
        {
            try
            {
                var attributes = File.GetAttributes(path);
                if (attributes.HasFlag(FileAttributes.Hidden) || attributes.HasFlag(FileAttributes.System))
                {
                    continue;
                }
                entries.Add(CreateItem(path));
            }
            catch (Exception)
            {
                // Skip files or directories that cannot be accessed due to permissions or being locked
            }
        }

        return entries
            .OrderByDescending(x => x.IsDirectory)
            .ThenBy(x => x.Name, StringComparer.OrdinalIgnoreCase)
            .ToArray();
    }

    public FileStream OpenReadStream(string relativePath)
    {
        var absolutePath = GetAbsolutePath(relativePath);
        return new FileStream(absolutePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite);
    }

    public string GetAbsolutePath(string? subPath)
    {
        var root = Path.GetFullPath(_options.RootPath);
        if (string.IsNullOrWhiteSpace(subPath))
        {
            return root;
        }

        var fullPath = Path.GetFullPath(Path.Combine(root, subPath));
        if (!fullPath.StartsWith(root, StringComparison.OrdinalIgnoreCase))
        {
            throw new UnauthorizedAccessException("Invalid path outside root.");
        }

        return fullPath;
    }

    public string GetMimeType(string extension)
    {
        return extension.ToLowerInvariant() switch
        {
            ".mp4" => "video/mp4",
            ".webm" => "video/webm",
            ".mkv" => "video/x-matroska",
            ".jpg" or ".jpeg" => "image/jpeg",
            ".png" => "image/png",
            ".webp" => "image/webp",
            _ => "application/octet-stream"
        };
    }

    public string FormatSize(long size)
    {
        string[] sizes = { "B", "KB", "MB", "GB", "TB" };
        double len = size;
        int order = 0;
        while (len >= 1024 && order < sizes.Length - 1)
        {
            order++;
            len /= 1024;
        }
        return $"{len:0.##} {sizes[order]}";
    }

    public string GetRelativePath(string absolutePath)
    {
        var root = Path.GetFullPath(_options.RootPath);
        var fullPath = Path.GetFullPath(absolutePath);
        return fullPath.StartsWith(root, StringComparison.OrdinalIgnoreCase)
            ? Path.GetRelativePath(root, fullPath).Replace('\\', '/')
            : string.Empty;
    }

    private FileItemDto CreateItem(string path)
    {
        var isDirectory = Directory.Exists(path);
        FileSystemInfo entry = isDirectory ? new DirectoryInfo(path) : new FileInfo(path);

        var extension = isDirectory ? string.Empty : Path.GetExtension(entry.FullName);
        var mimeType = isDirectory ? "application/x-directory" : GetMimeType(extension);
        var relativePath = GetRelativePath(entry.FullName);

        long size = 0;
        string sizeFormatted = string.Empty;
        DateTimeOffset lastModified = DateTimeOffset.MinValue;
        DateTimeOffset createdDate = DateTimeOffset.MinValue;

        try
        {
            if (!isDirectory)
            {
                var fileInfo = new FileInfo(entry.FullName);
                size = fileInfo.Length;
                sizeFormatted = FormatSize(size);
            }
            lastModified = entry.LastWriteTimeUtc;
            createdDate = entry.CreationTimeUtc;
        }
        catch (Exception)
        {
            // Ignore if we can't read metadata (e.g. file locked by another process)
        }

        bool isLocked = isDirectory && !_securityService.IsAccessGranted(entry.FullName, null);

        return new FileItemDto
        {
            Name = entry.Name,
            RelativePath = relativePath,
            Extension = extension,
            Type = isDirectory ? "File folder" : GetTypeLabel(extension),
            Size = size,
            SizeFormatted = sizeFormatted,
            LastModified = lastModified,
            CreatedDate = createdDate,
            IsDirectory = isDirectory,
            IsLocked = isLocked,
            MimeType = mimeType
        };
    }

    private string GetTypeLabel(string extension) => extension.ToLowerInvariant() switch
    {
        ".mp4" or ".webm" or ".mkv" => "Video",
        ".jpg" or ".jpeg" or ".png" or ".webp" => "Image",
        _ => "File"
    };
}
