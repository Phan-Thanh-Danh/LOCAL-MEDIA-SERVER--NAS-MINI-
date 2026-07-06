using System.Collections.Concurrent;
using BCrypt.Net;
using Microsoft.Data.Sqlite;

namespace LocalMediaServer.Services;

public class FolderSecurityService
{
    private readonly string _connectionString;
    private readonly ConcurrentDictionary<string, string> _locksCache;

    public FolderSecurityService()
    {
        var dbPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "media_server.db");
        _connectionString = $"Data Source={dbPath}";
        _locksCache = new ConcurrentDictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        
        InitializeDatabase();
        LoadLocksCache();
    }

    private void InitializeDatabase()
    {
        using var connection = new SqliteConnection(_connectionString);
        connection.Open();

        var command = connection.CreateCommand();
        command.CommandText = @"
            CREATE TABLE IF NOT EXISTS FolderLocks (
                Path TEXT PRIMARY KEY,
                PasswordHash TEXT NOT NULL
            );
        ";
        command.ExecuteNonQuery();
    }

    private void LoadLocksCache()
    {
        using var connection = new SqliteConnection(_connectionString);
        connection.Open();

        var command = connection.CreateCommand();
        command.CommandText = "SELECT Path, PasswordHash FROM FolderLocks";
        
        using var reader = command.ExecuteReader();
        while (reader.Read())
        {
            _locksCache[reader.GetString(0)] = reader.GetString(1);
        }
    }

    public void LockFolder(string absolutePath, string password)
    {
        string hash = BCrypt.Net.BCrypt.EnhancedHashPassword(password, hashType: HashType.SHA256);

        using var connection = new SqliteConnection(_connectionString);
        connection.Open();

        var command = connection.CreateCommand();
        command.CommandText = @"
            INSERT INTO FolderLocks (Path, PasswordHash) 
            VALUES ($path, $hash)
            ON CONFLICT(Path) DO UPDATE SET PasswordHash = $hash;
        ";
        command.Parameters.AddWithValue("$path", absolutePath);
        command.Parameters.AddWithValue("$hash", hash);
        command.ExecuteNonQuery();

        _locksCache[absolutePath] = hash;
    }

    public void UnlockFolder(string absolutePath, string password)
    {
        if (_locksCache.TryGetValue(absolutePath, out var savedHash) && BCrypt.Net.BCrypt.EnhancedVerify(password, savedHash, hashType: HashType.SHA256))
        {
            using var connection = new SqliteConnection(_connectionString);
            connection.Open();

            var command = connection.CreateCommand();
            command.CommandText = "DELETE FROM FolderLocks WHERE Path = $path";
            command.Parameters.AddWithValue("$path", absolutePath);
            command.ExecuteNonQuery();

            _locksCache.TryRemove(absolutePath, out _);
        }
        else
        {
            throw new UnauthorizedAccessException("Mật khẩu không đúng.");
        }
    }

    /// <summary>
    /// Checks if the path or any of its parent directories is locked.
    /// If locked, it verifies the password.
    /// Returns true if access is granted (either unlocked or correct password).
    /// Returns false if access is denied (locked and missing/incorrect password).
    /// </summary>
    public bool IsAccessGranted(string absolutePath, string? password)
    {
        var currentPath = absolutePath;

        // Traverse up the directory tree to see if any parent is locked
        while (!string.IsNullOrEmpty(currentPath))
        {
            if (_locksCache.TryGetValue(currentPath, out var savedHash))
            {
                if (string.IsNullOrEmpty(password))
                    return false;
                    
                return BCrypt.Net.BCrypt.EnhancedVerify(password, savedHash, hashType: HashType.SHA256);
            }

            var parent = Path.GetDirectoryName(currentPath);
            if (parent == currentPath || string.IsNullOrEmpty(parent))
                break;
                
            currentPath = parent;
        }

        return true;
    }
}
