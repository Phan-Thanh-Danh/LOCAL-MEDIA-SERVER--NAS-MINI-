using Microsoft.Data.Sqlite;
using BCrypt.Net;

namespace LocalMediaServer.Services;

public class DatabaseService
{
    public string ConnectionString { get; }

    public DatabaseService()
    {
        var dbPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "media_server.db");
        ConnectionString = $"Data Source={dbPath}";
        InitializeDatabase();
    }

    private void InitializeDatabase()
    {
        using var connection = new SqliteConnection(ConnectionString);
        connection.Open();

        using var command = connection.CreateCommand();
        
        // 1. FolderLocks
        command.CommandText = @"
            CREATE TABLE IF NOT EXISTS FolderLocks (
                Path TEXT PRIMARY KEY,
                PasswordHash TEXT NOT NULL
            );
        ";
        command.ExecuteNonQuery();

        // 2. Users
        command.CommandText = @"
            CREATE TABLE IF NOT EXISTS Users (
                Id INTEGER PRIMARY KEY AUTOINCREMENT,
                Username TEXT UNIQUE NOT NULL,
                PasswordHash TEXT NOT NULL,
                Role TEXT NOT NULL
            );
        ";
        command.ExecuteNonQuery();

        // Check if admin user exists, if not create default admin:admin
        command.CommandText = "SELECT COUNT(*) FROM Users WHERE Username = 'admin'";
        long adminCount = (long)command.ExecuteScalar();
        if (adminCount == 0)
        {
            command.CommandText = @"
                INSERT INTO Users (Username, PasswordHash, Role)
                VALUES ('admin', $hash, 'Admin')
            ";
            command.Parameters.AddWithValue("$hash", BCrypt.Net.BCrypt.EnhancedHashPassword("admin", hashType: HashType.SHA256));
            command.ExecuteNonQuery();
        }

        // 3. WatchHistory
        command.CommandText = @"
            CREATE TABLE IF NOT EXISTS WatchHistory (
                UserId INTEGER NOT NULL,
                Path TEXT NOT NULL,
                Position INTEGER NOT NULL,
                UpdatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (UserId, Path)
            );
        ";
        command.ExecuteNonQuery();

        // 4. SharedLinks
        command.CommandText = @"
            CREATE TABLE IF NOT EXISTS SharedLinks (
                Token TEXT PRIMARY KEY,
                Path TEXT NOT NULL,
                ExpiresAt DATETIME,
                CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
            );
        ";
        command.ExecuteNonQuery();
    }
}
