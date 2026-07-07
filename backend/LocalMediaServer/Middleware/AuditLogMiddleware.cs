using LocalMediaServer.Services;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Http;

namespace LocalMediaServer.Middleware;

public class AuditLogMiddleware
{
    private readonly RequestDelegate _next;

    public AuditLogMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context, AuditLogService auditLogService)
    {
        var path = context.Request.Path.Value?.ToLower() ?? "";
        
        bool isMutatingMethod = context.Request.Method == HttpMethods.Post ||
                                context.Request.Method == HttpMethods.Put ||
                                context.Request.Method == HttpMethods.Delete ||
                                context.Request.Method == HttpMethods.Patch;

        bool isApiRoute = path.StartsWith("/api/");
        bool isLogin = path.Contains("/api/auth/login");

        if (isApiRoute && isMutatingMethod)
        {
            context.Request.EnableBuffering();

            string payload = "";
            if (context.Request.HasFormContentType)
            {
                // If it's multipart/form-data, don't read the whole body as text
                payload = "[Form Data / File Upload]";
            }
            else if (context.Request.ContentLength > 0)
            {
                using var reader = new StreamReader(
                    context.Request.Body,
                    Encoding.UTF8,
                    detectEncodingFromByteOrderMarks: false,
                    leaveOpen: true);
                
                payload = await reader.ReadToEndAsync();
                context.Request.Body.Position = 0;
            }

            var username = context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(username) && isLogin)
            {
                // Try to extract username from payload just for logging if not authenticated yet
                try {
                    var json = System.Text.Json.JsonDocument.Parse(payload);
                    if (json.RootElement.TryGetProperty("username", out var userEl))
                    {
                        username = userEl.GetString();
                    }
                } catch { }
            }

            var ipAddress = context.Connection.RemoteIpAddress?.ToString();
            var action = context.Request.Method;

            if (isLogin && !string.IsNullOrEmpty(payload) && payload != "[Form Data / File Upload]")
            {
                payload = "{\"username\": \"" + username + "\", \"password\": \"[REDACTED]\"}";
            }

            auditLogService.LogAction(username, action, path, payload, ipAddress);
        }

        await _next(context);
    }
}
