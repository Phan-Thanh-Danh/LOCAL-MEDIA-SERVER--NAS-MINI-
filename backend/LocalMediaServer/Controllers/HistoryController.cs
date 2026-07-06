using LocalMediaServer.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using Microsoft.Data.Sqlite;

namespace LocalMediaServer.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class HistoryController : ControllerBase
{
    private readonly DatabaseService _db;

    public HistoryController(DatabaseService db)
    {
        _db = db;
    }

    [HttpPost]
    public IActionResult UpdateHistory([FromBody] WatchHistoryRequest req)
    {
        if (string.IsNullOrEmpty(req.Path)) return BadRequest();

        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId)) return Unauthorized();

        using var connection = new SqliteConnection(_db.ConnectionString);
        connection.Open();

        using var command = connection.CreateCommand();
        command.CommandText = @"
            INSERT INTO WatchHistory (UserId, Path, Position, UpdatedAt) 
            VALUES (@userId, @path, @position, CURRENT_TIMESTAMP)
            ON CONFLICT(UserId, Path) 
            DO UPDATE SET Position = excluded.Position, UpdatedAt = CURRENT_TIMESTAMP;
        ";
        command.Parameters.AddWithValue("@userId", userId);
        command.Parameters.AddWithValue("@path", req.Path);
        command.Parameters.AddWithValue("@position", req.StoppedAt);
        
        command.ExecuteNonQuery();

        return Ok(new { success = true });
    }

    [HttpGet]
    public IActionResult GetHistory([FromQuery] string path)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId)) return Unauthorized();

        using var connection = new SqliteConnection(_db.ConnectionString);
        connection.Open();

        using var command = connection.CreateCommand();
        command.CommandText = "SELECT Position FROM WatchHistory WHERE UserId = @userId AND Path = @path";
        command.Parameters.AddWithValue("@userId", userId);
        command.Parameters.AddWithValue("@path", path);

        var result = command.ExecuteScalar();
        if (result != null && result != DBNull.Value)
        {
            return Ok(new { stoppedAt = Convert.ToDouble(result) });
        }

        return Ok(new { stoppedAt = 0 });
    }
}

public class WatchHistoryRequest
{
    public string Path { get; set; } = string.Empty;
    public double StoppedAt { get; set; }
}
