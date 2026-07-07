using Microsoft.Data.Sqlite;

namespace LocalMediaServer.Services;

public class PinnedItemService
{
    private readonly DatabaseService _dbService;

    public PinnedItemService(DatabaseService dbService)
    {
        _dbService = dbService;
    }

    public List<string> GetAllPinnedPaths()
    {
        var paths = new List<string>();
        using var connection = new SqliteConnection(_dbService.ConnectionString);
        connection.Open();

        using var command = connection.CreateCommand();
        command.CommandText = "SELECT Path FROM PinnedItems";

        using var reader = command.ExecuteReader();
        while (reader.Read())
        {
            paths.Add(reader.GetString(0));
        }

        return paths;
    }

    public void PinItem(string path)
    {
        using var connection = new SqliteConnection(_dbService.ConnectionString);
        connection.Open();

        using var command = connection.CreateCommand();
        command.CommandText = @"
            INSERT OR IGNORE INTO PinnedItems (Path)
            VALUES (@Path)
        ";
        command.Parameters.AddWithValue("@Path", path);
        command.ExecuteNonQuery();
    }

    public void UnpinItem(string path)
    {
        using var connection = new SqliteConnection(_dbService.ConnectionString);
        connection.Open();

        using var command = connection.CreateCommand();
        command.CommandText = @"
            DELETE FROM PinnedItems
            WHERE Path = @Path
        ";
        command.Parameters.AddWithValue("@Path", path);
        command.ExecuteNonQuery();
    }
}
