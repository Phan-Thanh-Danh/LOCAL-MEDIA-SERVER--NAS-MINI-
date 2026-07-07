using LocalMediaServer.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LocalMediaServer.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin")]
public class AuditController : ControllerBase
{
    private readonly AuditLogService _auditLogService;

    public AuditController(AuditLogService auditLogService)
    {
        _auditLogService = auditLogService;
    }

    [HttpGet]
    public IActionResult GetLogs([FromQuery] int limit = 100, [FromQuery] int offset = 0)
    {
        var logs = _auditLogService.GetLogs(limit, offset);
        return Ok(logs);
    }
}
