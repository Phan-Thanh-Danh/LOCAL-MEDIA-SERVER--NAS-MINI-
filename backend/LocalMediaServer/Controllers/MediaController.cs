using LocalMediaServer.Services;
using Microsoft.AspNetCore.Mvc;

namespace LocalMediaServer.Controllers;

[ApiController]
[Route("api/[controller]")]
public class MediaController : ControllerBase
{
    private readonly IMediaFileService _mediaFileService;

    public MediaController(IMediaFileService mediaFileService)
    {
        _mediaFileService = mediaFileService;
    }

    [HttpGet("video/{*path}")]
    public async Task<IActionResult> GetVideo(string path)
    {
        return await StreamMedia(path, isVideo: true);
    }

    [HttpGet("image/{*path}")]
    public async Task<IActionResult> GetImage(string path)
    {
        return await StreamMedia(path, isVideo: false);
    }

    private async Task<IActionResult> StreamMedia(string path, bool isVideo)
    {
        try
        {
            var fullPath = _mediaFileService.GetAbsolutePath(path);
            var fileInfo = new FileInfo(fullPath);
            if (!fileInfo.Exists)
            {
                return NotFound();
            }

            var mimeType = _mediaFileService.GetMimeType(Path.GetExtension(fullPath));
            var stream = _mediaFileService.OpenReadStream(path);
            Response.Headers.AcceptRanges = "bytes";

            var rangeHeader = Request.Headers.Range.ToString();
            if (!string.IsNullOrWhiteSpace(rangeHeader) && rangeHeader.StartsWith("bytes=", StringComparison.OrdinalIgnoreCase))
            {
                var (start, end) = ParseRange(rangeHeader, fileInfo.Length);
                if (start.HasValue && end.HasValue)
                {
                    Response.StatusCode = StatusCodes.Status206PartialContent;
                    Response.Headers.ContentRange = $"bytes {start.Value}-{end.Value}/{fileInfo.Length}";
                    Response.ContentLength = end.Value - start.Value + 1;
                    stream.Seek(start.Value, SeekOrigin.Begin);
                    return File(stream, mimeType, enableRangeProcessing: true, fileDownloadName: fileInfo.Name);
                }
            }

            Response.ContentLength = fileInfo.Length;
            return File(stream, mimeType, enableRangeProcessing: true, fileDownloadName: fileInfo.Name);
        }
        catch (UnauthorizedAccessException)
        {
            return StatusCode(403, "Forbidden");
        }
        catch (Exception)
        {
            return BadRequest();
        }
    }

    private static (long? start, long? end) ParseRange(string rangeHeader, long fileLength)
    {
        var range = rangeHeader.Substring("bytes=".Length).Split('-');
        if (range.Length != 2) return (null, null);
        if (long.TryParse(range[0], out var start) && long.TryParse(range[1], out var end))
        {
            var endValue = end < fileLength - 1 ? end : fileLength - 1;
            return (start, endValue);
        }
        return (null, null);
    }
}
