using System.Collections.Concurrent;
using BCrypt.Net;
using Microsoft.Data.Sqlite;

namespace LocalMediaServer.Services;

public class HiddenVaultService
{
    private readonly DatabaseService _dbService;
    private string? _passwordHash;
    private ConcurrentDictionary<string, bool> _hiddenFolders = new();

    public HiddenVaultService(DatabaseService dbService)
    {
        _dbService = dbService;
        LoadSettings();
    }

    private void LoadSettings()
    {
        using var connection = new SqliteConnection(_dbService.ConnectionString);
        connection.Open();

        using var cmd1 = connection.CreateCommand();
        cmd1.CommandText = "SELECT Value FROM Settings WHERE Key = 'VaultPasswordHash'";
        var result = cmd1.ExecuteScalar();
        if (result != null)
        {
            _passwordHash = result.ToString();
        }

        using var cmd2 = connection.CreateCommand();
        cmd2.CommandText = "SELECT Path FROM HiddenFolders";
        using var reader = cmd2.ExecuteReader();
        while (reader.Read())
        {
            _hiddenFolders[reader.GetString(0)] = true;
        }
    }

    public bool IsPasswordSet()
    {
        return !string.IsNullOrEmpty(_passwordHash);
    }

    public bool VerifyPassword(string? password)
    {
        if (string.IsNullOrEmpty(_passwordHash)) return false;
        if (string.IsNullOrEmpty(password)) return false;
        return BCrypt.Net.BCrypt.EnhancedVerify(password, _passwordHash, hashType: HashType.SHA256);
    }

    public void SetPassword(string newPassword)
    {
        _passwordHash = BCrypt.Net.BCrypt.EnhancedHashPassword(newPassword, hashType: HashType.SHA256);
        using var connection = new SqliteConnection(_dbService.ConnectionString);
        connection.Open();
        using var cmd = connection.CreateCommand();
        cmd.CommandText = @"
            INSERT INTO Settings (Key, Value) VALUES ('VaultPasswordHash', @val)
            ON CONFLICT(Key) DO UPDATE SET Value = @val;
        ";
        cmd.Parameters.AddWithValue("@val", _passwordHash);
        cmd.ExecuteNonQuery();
    }

    public void ChangePassword(string? oldPassword, string newPassword)
    {
        if (IsPasswordSet() && !VerifyPassword(oldPassword))
            throw new UnauthorizedAccessException("Mật khẩu cũ không chính xác.");
        SetPassword(newPassword);
    }

    public bool IsHidden(string absolutePath)
    {
        return _hiddenFolders.ContainsKey(absolutePath);
    }

    public void HideFolder(string absolutePath)
    {
        _hiddenFolders[absolutePath] = true;
        using var connection = new SqliteConnection(_dbService.ConnectionString);
        connection.Open();
        using var cmd = connection.CreateCommand();
        cmd.CommandText = "INSERT OR IGNORE INTO HiddenFolders (Path) VALUES (@path)";
        cmd.Parameters.AddWithValue("@path", absolutePath);
        cmd.ExecuteNonQuery();
    }

    public void UnhideFolder(string absolutePath)
    {
        _hiddenFolders.TryRemove(absolutePath, out _);
        using var connection = new SqliteConnection(_dbService.ConnectionString);
        connection.Open();
        using var cmd = connection.CreateCommand();
        cmd.CommandText = "DELETE FROM HiddenFolders WHERE Path = @path";
        cmd.Parameters.AddWithValue("@path", absolutePath);
        cmd.ExecuteNonQuery();
    }
}
