using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.Sqlite;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using BCrypt.Net;
using LocalMediaServer.Services;

namespace LocalMediaServer.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly DatabaseService _db;
    private readonly IConfiguration _config;

    public AuthController(DatabaseService db, IConfiguration config)
    {
        _db = db;
        _config = config;
    }

    [HttpPost("login")]
    public IActionResult Login([FromBody] LoginRequest request)
    {
        if (string.IsNullOrEmpty(request.Username) || string.IsNullOrEmpty(request.Password))
            return BadRequest("Username and Password are required.");

        using var connection = new SqliteConnection(_db.ConnectionString);
        connection.Open();

        using var command = connection.CreateCommand();
        command.CommandText = "SELECT Id, PasswordHash, Role FROM Users WHERE Username = $username";
        command.Parameters.AddWithValue("$username", request.Username);

        using var reader = command.ExecuteReader();
        if (reader.Read())
        {
            var id = reader.GetInt32(0);
            var hash = reader.GetString(1);
            var role = reader.GetString(2);

            if (BCrypt.Net.BCrypt.EnhancedVerify(request.Password, hash, hashType: HashType.SHA256))
            {
                var token = GenerateJwtToken(id, request.Username, role);
                return Ok(new { token, role });
            }
        }

        return Unauthorized("Invalid credentials.");
    }

    private string GenerateJwtToken(int id, string username, string role)
    {
        var jwtKey = _config["Jwt:Key"] ?? "super_secret_local_media_server_key_must_be_long_enough";
        var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
        var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, username),
            new Claim("id", id.ToString()),
            new Claim(ClaimTypes.Role, role),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        var token = new JwtSecurityToken(
            issuer: "LocalMediaServer",
            audience: "LocalMediaServer",
            claims: claims,
            expires: DateTime.Now.AddDays(7),
            signingCredentials: credentials);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}

public class LoginRequest
{
    public string Username { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}
