using LocalMediaServer.Services;

namespace LocalMediaServer.Middleware;

public class PathSecurityMiddleware
{
    private readonly RequestDelegate _next;

    public PathSecurityMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context, IMediaFileService mediaFileService)
    {
        if (context.Request.Path.StartsWithSegments("/api/files", StringComparison.OrdinalIgnoreCase) ||
            context.Request.Path.StartsWithSegments("/api/media", StringComparison.OrdinalIgnoreCase))
        {
            var pathValue = context.Request.Query["path"].ToString();
            if (!string.IsNullOrWhiteSpace(pathValue))
            {
                try
                {
                    var _ = mediaFileService.GetAbsolutePath(pathValue);
                }
                catch (UnauthorizedAccessException)
                {
                    context.Response.StatusCode = StatusCodes.Status403Forbidden;
                    await context.Response.WriteAsync("Forbidden");
                    return;
                }
                catch (Exception)
                {
                    context.Response.StatusCode = StatusCodes.Status400BadRequest;
                    await context.Response.WriteAsync("Invalid path");
                    return;
                }
            }
        }

        await _next(context);
    }
}
