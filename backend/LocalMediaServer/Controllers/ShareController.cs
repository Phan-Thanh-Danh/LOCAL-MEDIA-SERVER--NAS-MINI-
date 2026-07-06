using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.Sqlite;
using LocalMediaServer.Services;
using System.Security.Cryptography;
using Microsoft.Extensions.Options;

namespace LocalMediaServer.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ShareController : ControllerBase
{
    private readonly DatabaseService _db;
    private readonly MediaServerOptions _options;

    public ShareController(DatabaseService db, IOptions<MediaServerOptions> options)
    {
        _db = db;
        _options = options.Value;
    }

    [HttpPost]
    [Authorize]
    public IActionResult CreateShareLink([FromBody] ShareRequest request)
    {
        if (string.IsNullOrEmpty(request.Path)) return BadRequest();

        var absolutePath = Path.Combine(_options.RootPath, request.Path);
        if (!System.IO.File.Exists(absolutePath) && !System.IO.Directory.Exists(absolutePath))
        {
            return NotFound("File or folder not found.");
        }

        var token = Convert.ToHexString(RandomNumberGenerator.GetBytes(16)).ToLower();
        
        using var connection = new SqliteConnection(_db.ConnectionString);
        connection.Open();
        
        using var command = connection.CreateCommand();
        command.CommandText = @"
            INSERT INTO SharedLinks (Token, Path, ExpiresAt)
            VALUES ($token, $path, $expiresAt)
        ";
        command.Parameters.AddWithValue("$token", token);
        command.Parameters.AddWithValue("$path", request.Path);
        
        if (request.ExpiresInHours.HasValue)
        {
            command.Parameters.AddWithValue("$expiresAt", DateTime.UtcNow.AddHours(request.ExpiresInHours.Value));
        }
        else
        {
            command.Parameters.AddWithValue("$expiresAt", DBNull.Value);
        }
        
        command.ExecuteNonQuery();

        return Ok(new { Token = token, Url = $"/share/{token}" });
    }

    [HttpGet("{token}")]
    public IActionResult GetSharedItem(string token)
    {
        using var connection = new SqliteConnection(_db.ConnectionString);
        connection.Open();

        using var command = connection.CreateCommand();
        command.CommandText = "SELECT Path, ExpiresAt FROM SharedLinks WHERE Token = $token";
        command.Parameters.AddWithValue("$token", token);

        using var reader = command.ExecuteReader();
        if (reader.Read())
        {
            var expiresAt = reader.IsDBNull(1) ? (DateTime?)null : reader.GetDateTime(1);
            if (expiresAt.HasValue && expiresAt.Value < DateTime.UtcNow)
            {
                return BadRequest("Shared link has expired.");
            }

            var path = reader.GetString(0);
            var absolutePath = Path.Combine(_options.RootPath, path);
            
            if (System.IO.File.Exists(absolutePath))
            {
                return Ok(new { Type = "file", Name = Path.GetFileName(path) });
            }
            if (System.IO.Directory.Exists(absolutePath))
            {
                return Ok(new { Type = "directory", Name = Path.GetFileName(path) });
            }
            return NotFound();
        }

        return NotFound("Link not found.");
    }
    
    [HttpGet("{token}/download")]
    public IActionResult DownloadSharedItem(string token)
    {
        using var connection = new SqliteConnection(_db.ConnectionString);
        connection.Open();

        using var command = connection.CreateCommand();
        command.CommandText = "SELECT Path, ExpiresAt FROM SharedLinks WHERE Token = $token";
        command.Parameters.AddWithValue("$token", token);

        using var reader = command.ExecuteReader();
        if (reader.Read())
        {
            var expiresAt = reader.IsDBNull(1) ? (DateTime?)null : reader.GetDateTime(1);
            if (expiresAt.HasValue && expiresAt.Value < DateTime.UtcNow)
            {
                return BadRequest("Shared link has expired.");
            }

            var path = reader.GetString(0);
            var absolutePath = Path.Combine(_options.RootPath, path);
            
            if (System.IO.File.Exists(absolutePath))
            {
                var contentType = "application/octet-stream";
                var ext = Path.GetExtension(absolutePath).ToLowerInvariant();
                // set basic content types if needed...
                return PhysicalFile(absolutePath, contentType, Path.GetFileName(absolutePath), enableRangeProcessing: true);
            }
            
            return BadRequest("Cannot download a directory directly.");
        }

        return NotFound();
    }
}

public class ShareRequest
{
    public string Path { get; set; } = string.Empty;
    public int? ExpiresInHours { get; set; }
}
