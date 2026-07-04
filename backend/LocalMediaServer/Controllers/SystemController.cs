using LocalMediaServer.Services;
using Microsoft.AspNetCore.Mvc;

namespace LocalMediaServer.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SystemController : ControllerBase
{
    private readonly IMediaFileService _mediaFileService;

    public SystemController(IMediaFileService mediaFileService)
    {
        _mediaFileService = mediaFileService;
    }

    [HttpGet("status")]
    public IActionResult Status() => Ok(new { status = "running", rootPath = _mediaFileService.GetAbsolutePath(null) });

    [HttpGet("storage")]
    public IActionResult Storage()
    {
        var root = _mediaFileService.GetAbsolutePath(null);
        var info = new DirectoryInfo(root);
        return Ok(new { path = root, exists = info.Exists, totalFiles = Directory.EnumerateFiles(root, "*", SearchOption.AllDirectories).Count() });
    }
}
