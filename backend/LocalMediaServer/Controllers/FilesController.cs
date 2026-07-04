using LocalMediaServer.DTOs;
using LocalMediaServer.Services;
using Microsoft.AspNetCore.Mvc;

namespace LocalMediaServer.Controllers;

[ApiController]
[Route("api/[controller]")]
public class FilesController : ControllerBase
{
    private readonly IMediaFileService _mediaFileService;

    public FilesController(IMediaFileService mediaFileService)
    {
        _mediaFileService = mediaFileService;
    }

    [HttpGet]
    public ActionResult<FileItemDto[]> Get([FromQuery] string? path)
    {
        try
        {
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
