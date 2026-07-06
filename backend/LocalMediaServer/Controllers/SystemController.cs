using LocalMediaServer.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Diagnostics;

namespace LocalMediaServer.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class SystemController : ControllerBase
{
    private readonly IMediaFileService _mediaFileService;

    public SystemController(IMediaFileService mediaFileService)
    {
        _mediaFileService = mediaFileService;
    }

    [HttpGet("status")]
    public IActionResult Status() => Ok(new { status = "running", rootPath = _mediaFileService.GetAbsolutePath(null) });

    [HttpGet("dashboard")]
    public IActionResult Dashboard()
    {
        // 1. Disk Information
        var drives = DriveInfo.GetDrives()
            .Where(d => d.IsReady && d.DriveType == DriveType.Fixed)
            .Select(d => new
            {
                Name = d.Name,
                TotalSize = d.TotalSize,
                AvailableFreeSpace = d.AvailableFreeSpace,
                UsedSpace = d.TotalSize - d.AvailableFreeSpace,
                UsedPercentage = Math.Round((double)(d.TotalSize - d.AvailableFreeSpace) / d.TotalSize * 100, 1)
            }).ToList();

        // 2. RAM Information (Process memory for safety, system memory requires WMI/PInvoke)
        var process = Process.GetCurrentProcess();
        var usedRam = process.WorkingSet64; // Bytes

        // Note: CPU usage requires PerformanceCounters which can be slow or throw exceptions if not admin.
        // We will provide a simple mock or process CPU time.
        
        return Ok(new
        {
            Drives = drives,
            AppRamUsage = usedRam,
            Uptime = (DateTime.Now - process.StartTime).ToString(@"dd\.hh\:mm\:ss")
        });
    }
}
