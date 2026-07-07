using LocalMediaServer.DTOs;
using LocalMediaServer.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;

namespace LocalMediaServer.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class FilesController : ControllerBase
{
    private readonly IMediaFileService _mediaFileService;
    private readonly FolderSecurityService _securityService;
    private readonly HiddenVaultService _hiddenVaultService;

    public FilesController(IMediaFileService mediaFileService, FolderSecurityService securityService, HiddenVaultService hiddenVaultService)
    {
        _mediaFileService = mediaFileService;
        _securityService = securityService;
        _hiddenVaultService = hiddenVaultService;
    }

    [HttpGet]
    public ActionResult<FileItemDto[]> Get([FromQuery] string? path, [FromQuery] string? password = null)
    {
        try
        {
            if (!string.IsNullOrEmpty(path))
            {
                var absolutePath = _mediaFileService.GetAbsolutePath(path);
                
                // If path itself is hidden and vault is not unlocked, block access
                var vaultPwdTemp = Request.Headers["Vault-Password"].ToString();
                bool showHiddenTemp = _hiddenVaultService.VerifyPassword(vaultPwdTemp);
                if (_hiddenVaultService.IsHidden(absolutePath) && !showHiddenTemp)
                {
                    return NotFound("Directory not found.");
                }

                if (!_securityService.IsAccessGranted(absolutePath, password))
                {
                    return StatusCode(401, "LOCKED");
                }
            }
            
            var vaultPwd = Request.Headers["Vault-Password"].ToString();
            bool showHidden = _hiddenVaultService.VerifyPassword(vaultPwd);
            
            return Ok(_mediaFileService.ListDirectory(path, showHidden));
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
