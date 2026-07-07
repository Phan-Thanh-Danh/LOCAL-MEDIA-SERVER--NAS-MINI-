using Microsoft.Data.Sqlite;
using System.Data;

namespace LocalMediaServer.Services;

public class AuditLog
{
    public int Id { get; set; }
    public string? Username { get; set; }
    public string Action { get; set; } = string.Empty;
    public string? ApiPath { get; set; }
    public string? Payload { get; set; }
    public string? IpAddress { get; set; }
    public DateTime Timestamp { get; set; }
}

public class AuditLogService
{
    private readonly DatabaseService _db;

    public AuditLogService(DatabaseService db)
    {
        _db = db;
    }

    public void LogAction(string? username, string action, string? apiPath, string? payload, string? ipAddress)
    {
        try
        {
            using var connection = new SqliteConnection(_db.ConnectionString);
            connection.Open();

            using var command = connection.CreateCommand();
            command.CommandText = @"
                INSERT INTO AuditLogs (Username, Action, ApiPath, Payload, IpAddress, Timestamp)
                VALUES ($username, $action, $apiPath, $payload, $ipAddress, $timestamp)
            ";

            // Get Vietnam Time (UTC+7)
            var vnTimeZone = TimeZoneInfo.FindSystemTimeZoneById("SE Asia Standard Time");
            var vnTime = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, vnTimeZone);

            command.Parameters.AddWithValue("$username", username ?? (object)DBNull.Value);
            command.Parameters.AddWithValue("$action", action);
            command.Parameters.AddWithValue("$apiPath", apiPath ?? (object)DBNull.Value);
            command.Parameters.AddWithValue("$payload", payload ?? (object)DBNull.Value);
            command.Parameters.AddWithValue("$ipAddress", ipAddress ?? (object)DBNull.Value);
            command.Parameters.AddWithValue("$timestamp", vnTime);

            command.ExecuteNonQuery();
        }
        catch (Exception ex)
        {
            Serilog.Log.Error(ex, "Failed to write audit log");
        }
    }

    public List<AuditLog> GetLogs(int limit = 100, int offset = 0)
    {
        var logs = new List<AuditLog>();
        try
        {
            using var connection = new SqliteConnection(_db.ConnectionString);
            connection.Open();

            using var command = connection.CreateCommand();
            command.CommandText = @"
                SELECT Id, Username, Action, ApiPath, Payload, IpAddress, Timestamp
                FROM AuditLogs
                ORDER BY Timestamp DESC
                LIMIT $limit OFFSET $offset
            ";
            command.Parameters.AddWithValue("$limit", limit);
            command.Parameters.AddWithValue("$offset", offset);

            using var reader = command.ExecuteReader();
            while (reader.Read())
            {
                logs.Add(new AuditLog
                {
                    Id = reader.GetInt32(0),
                    Username = reader.IsDBNull(1) ? null : reader.GetString(1),
                    Action = reader.GetString(2),
                    ApiPath = reader.IsDBNull(3) ? null : reader.GetString(3),
                    Payload = reader.IsDBNull(4) ? null : reader.GetString(4),
                    IpAddress = reader.IsDBNull(5) ? null : reader.GetString(5),
                    Timestamp = reader.GetDateTime(6)
                });
            }
        }
        catch (Exception ex)
        {
            Serilog.Log.Error(ex, "Failed to read audit logs");
        }
        return logs;
    }
}
