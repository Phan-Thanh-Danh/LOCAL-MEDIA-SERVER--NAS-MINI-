namespace LocalMediaServer.Services;

public class MediaServerOptions
{
    public const string SectionName = "MediaServer";
    public string RootPath { get; set; } = "D:/Tài Liệu";
    public List<string> AllowedExtensions { get; set; } = new();
}
