using LocalMediaServer.DTOs;
using LocalMediaServer.Services;
using Microsoft.AspNetCore.Mvc;

namespace LocalMediaServer.Controllers;

[ApiController]
[Route("api/[controller]")]
public class FilesController : ControllerBase
{
    private readonly IMediaFileService _mediaFileService;
    private readonly FolderSecurityService _securityService;

    public FilesController(IMediaFileService mediaFileService, FolderSecurityService securityService)
    {
        _mediaFileService = mediaFileService;
        _securityService = securityService;
    }

    [HttpGet]
    public ActionResult<FileItemDto[]> Get([FromQuery] string? path, [FromQuery] string? password = null)
    {
        try
        {
            if (!string.IsNullOrEmpty(path))
            {
                var absolutePath = _mediaFileService.GetAbsolutePath(path);
                if (!_securityService.IsAccessGranted(absolutePath, password))
                {
                    return StatusCode(401, "LOCKED");
                }
            }
            return Ok(_mediaFileService.ListDirectory(path));
        }
        catch (DirectoryNotFoundException ex)
        {
            return NotFound(ex.Message);
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(403, ex.Message);
        }
    }
}
