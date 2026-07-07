using LocalMediaServer.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.VisualBasic.FileIO;

namespace LocalMediaServer.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class MediaController : ControllerBase
{
    private readonly IMediaFileService _mediaFileService;
    private readonly ThumbnailService _thumbnailService;
    private readonly FolderSecurityService _securityService;

    public MediaController(IMediaFileService mediaFileService, ThumbnailService thumbnailService, FolderSecurityService securityService)
    {
        _mediaFileService = mediaFileService;
        _thumbnailService = thumbnailService;
        _securityService = securityService;
    }

    [HttpGet("thumbnail/{*relativePath}")]
    public async Task<IActionResult> GetThumbnail(string relativePath)
    {
        var absolutePath = _mediaFileService.GetAbsolutePath(relativePath);
        if (!System.IO.File.Exists(absolutePath))
        {
            return NotFound("File not found");
        }

        var thumbnailPath = await _thumbnailService.GetThumbnailAsync(absolutePath);
        if (string.IsNullOrEmpty(thumbnailPath) || !System.IO.File.Exists(thumbnailPath))
        {
            return NotFound("Could not generate thumbnail");
        }

        return PhysicalFile(thumbnailPath, "image/jpeg", enableRangeProcessing: true);
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

    [HttpGet("file/{*path}")]
    public async Task<IActionResult> GetFile(string path)
    {
        return await StreamMedia(path, isVideo: false);
    }

    [HttpGet("download/{*path}")]
    public IActionResult DownloadFile(string path)
    {
        try
        {
            var fullPath = _mediaFileService.GetAbsolutePath(path);
            var fileInfo = new FileInfo(fullPath);

            if (!fileInfo.Exists)
                return NotFound("File không tồn tại.");

            if ((fileInfo.Attributes & FileAttributes.Directory) == FileAttributes.Directory)
                return BadRequest("Không thể download thư mục.");

            var mimeType = _mediaFileService.GetMimeType(Path.GetExtension(fullPath));
            var stream = _mediaFileService.OpenReadStream(path);

            return File(stream, mimeType, fileDownloadName: fileInfo.Name, enableRangeProcessing: true);
        }
        catch (UnauthorizedAccessException)
        {
            return StatusCode(403, "Đường dẫn không hợp lệ.");
        }
        catch (Exception ex)
        {
            return StatusCode(500, $"Lỗi khi tải file: {ex.Message}");
        }
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
                    return File(stream, mimeType, enableRangeProcessing: true);
                }
            }

            Response.ContentLength = fileInfo.Length;
            return File(stream, mimeType, enableRangeProcessing: true);
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

    [HttpPost("upload")]
    [DisableRequestSizeLimit]
    public async Task<IActionResult> UploadFile([FromForm] IFormFile file, [FromForm] string subPath = "")
    {
        if (file == null || file.Length == 0)
            return BadRequest("Không có file nào được chọn.");

        string targetFolder;
        try
        {
            targetFolder = _mediaFileService.GetAbsolutePath(subPath);
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid("Đường dẫn không hợp lệ.");
        }

        if (!Directory.Exists(targetFolder))
            Directory.CreateDirectory(targetFolder);

        string filePath = Path.Combine(targetFolder, file.FileName);

        int count = 1;
        string fileNameOnly = Path.GetFileNameWithoutExtension(filePath);
        string extension = Path.GetExtension(filePath);
        while (System.IO.File.Exists(filePath))
        {
            string tempFileName = $"{fileNameOnly}({count++}){extension}";
            filePath = Path.Combine(targetFolder, tempFileName);
        }

        using (var stream = new FileStream(filePath, FileMode.Create))
        {
            await file.CopyToAsync(stream);
        }

        // Tự động tạo Thumbnail ngay khi upload xong, chờ tạo xong mới báo thành công
        var ext = Path.GetExtension(filePath).ToLowerInvariant();
        if (ext == ".mp4" || ext == ".mkv" || ext == ".avi" || ext == ".mov")
        {
            await _thumbnailService.GetThumbnailAsync(filePath);
        }

        return Ok(new { Message = "Tải file lên thành công!" });
    }

    [HttpPost("create-folder")]
    public IActionResult CreateFolder([FromBody] CreateFolderRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.FolderName))
            return BadRequest("Tên thư mục không được để trống.");

        string targetFolder;
        try
        {
            var basePath = _mediaFileService.GetAbsolutePath(request.SubPath);
            targetFolder = Path.Combine(basePath, request.FolderName);
            
            var rootPath = _mediaFileService.GetAbsolutePath("");
            if (!Path.GetFullPath(targetFolder).StartsWith(rootPath, StringComparison.OrdinalIgnoreCase))
            {
                return Forbid("Đường dẫn không hợp lệ.");
            }
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid("Đường dẫn không hợp lệ.");
        }

        if (Directory.Exists(targetFolder))
        {
            return BadRequest("Thư mục này đã tồn tại rồi.");
        }

        Directory.CreateDirectory(targetFolder);
        return Ok(new { Message = "Tạo thư mục thành công!" });
    }
    [HttpPost("lock")]
    public IActionResult LockFolder([FromBody] LockFolderRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Password))
            return BadRequest("Mật khẩu không được để trống.");

        try
        {
            var absolutePath = _mediaFileService.GetAbsolutePath(request.Path);
            _securityService.LockFolder(absolutePath, request.Password);
            return Ok(new { Message = "Đã khóa thư mục thành công!" });
        }
        catch (Exception ex)
        {
            return BadRequest($"Lỗi: {ex.Message}");
        }
    }

    [HttpPost("unlock")]
    public IActionResult UnlockFolder([FromBody] LockFolderRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Password))
            return BadRequest("Mật khẩu không được để trống.");

        try
        {
            var absolutePath = _mediaFileService.GetAbsolutePath(request.Path);
            _securityService.UnlockFolder(absolutePath, request.Password);
            return Ok(new { Message = "Đã bỏ khóa thư mục thành công!" });
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(403, ex.Message);
        }
        catch (Exception ex)
        {
            return BadRequest($"Lỗi: {ex.Message}");
        }
    }

    [HttpPost("delete")]
    public IActionResult DeleteItem([FromBody] DeleteItemRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Path))
            return BadRequest("Đường dẫn không được để trống.");

        try
        {
            var absolutePath = _mediaFileService.GetAbsolutePath(request.Path);
            
            if (System.IO.File.Exists(absolutePath))
            {
                FileSystem.DeleteFile(absolutePath, UIOption.OnlyErrorDialogs, RecycleOption.SendToRecycleBin);
                return Ok(new { Message = "Đã xóa file vào thùng rác." });
            }
            else if (Directory.Exists(absolutePath))
            {
                FileSystem.DeleteDirectory(absolutePath, UIOption.OnlyErrorDialogs, RecycleOption.SendToRecycleBin);
                return Ok(new { Message = "Đã xóa thư mục vào thùng rác." });
            }
            
            return NotFound("Không tìm thấy file hoặc thư mục.");
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(403, ex.Message);
        }
        catch (Exception ex)
        {
            return BadRequest($"Lỗi khi xóa: {ex.Message}");
        }
    }

    [HttpPost("rename")]
    public IActionResult RenameItem([FromBody] RenameItemRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Path) || string.IsNullOrWhiteSpace(request.NewName))
            return BadRequest("Đường dẫn và tên mới không được để trống.");

        try
        {
            var absolutePath = _mediaFileService.GetAbsolutePath(request.Path);
            
            var directory = Path.GetDirectoryName(absolutePath);
            if (directory == null) return BadRequest("Lỗi đường dẫn.");
            var newPath = Path.Combine(directory, request.NewName);
            
            if (System.IO.File.Exists(newPath) || Directory.Exists(newPath))
                return BadRequest("Tên này đã tồn tại.");

            if (System.IO.File.Exists(absolutePath))
            {
                System.IO.File.Move(absolutePath, newPath);
                return Ok(new { Message = "Đã đổi tên file thành công." });
            }
            else if (Directory.Exists(absolutePath))
            {
                Directory.Move(absolutePath, newPath);
                return Ok(new { Message = "Đã đổi tên thư mục thành công." });
            }
            
            return NotFound("Không tìm thấy file hoặc thư mục.");
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(403, ex.Message);
        }
        catch (Exception ex)
        {
            return BadRequest($"Lỗi khi đổi tên: {ex.Message}");
        }
    }
}

public class CreateFolderRequest
{
    public string FolderName { get; set; } = string.Empty;
    public string? SubPath { get; set; } = string.Empty;
}

public class LockFolderRequest
{
    public string? Path { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}

public class DeleteItemRequest
{
    public string? Path { get; set; } = string.Empty;
}

public class RenameItemRequest
{
    public string? Path { get; set; } = string.Empty;
    public string NewName { get; set; } = string.Empty;
}
