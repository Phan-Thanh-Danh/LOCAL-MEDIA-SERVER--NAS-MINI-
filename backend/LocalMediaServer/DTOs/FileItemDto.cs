namespace LocalMediaServer.DTOs;

public class FileItemDto
{
    public string Name { get; set; } = string.Empty;
    public string RelativePath { get; set; } = string.Empty;
    public string Extension { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public long Size { get; set; }
    public string SizeFormatted { get; set; } = string.Empty;
    public DateTimeOffset LastModified { get; set; }
    public DateTimeOffset CreatedDate { get; set; }
    public bool IsDirectory { get; set; }
    public bool IsLocked { get; set; }
    public string MimeType { get; set; } = string.Empty;
}
