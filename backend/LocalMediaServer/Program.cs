using LocalMediaServer.Hubs;
using LocalMediaServer.Middleware;
using LocalMediaServer.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Serilog;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

var rootPath = builder.Configuration["MediaServer:RootPath"] ?? "D:/Tài Liệu";
Directory.CreateDirectory(rootPath);

Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .WriteTo.File("logs/local-media-server-.log", rollingInterval: RollingInterval.Day)
    .CreateLogger();

builder.Host.UseSerilog();
builder.Services.Configure<Microsoft.AspNetCore.Http.Features.FormOptions>(options => {
    options.MultipartBodyLengthLimit = 5242880000; // Cho phép file tối đa ~5GB
});
builder.Services.AddControllers();
builder.Services.AddSignalR();
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

var jwtKey = builder.Configuration["Jwt:Key"] ?? "super_secret_local_media_server_key_must_be_long_enough";
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = false,
            ValidateAudience = false,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey))
        };
        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                var accessToken = context.Request.Query["access_token"];
                if (!string.IsNullOrEmpty(accessToken))
                {
                    context.Token = accessToken;
                }
                return Task.CompletedTask;
            }
        };
    });
builder.Services.AddAuthorization();

builder.Services.Configure<MediaServerOptions>(builder.Configuration.GetSection(MediaServerOptions.SectionName));
builder.Services.AddSingleton<DatabaseService>();
builder.Services.AddSingleton<FolderSecurityService>();
builder.Services.AddSingleton<ThumbnailService>();
builder.Services.AddSingleton<IMediaFileService, MediaFileService>();
builder.Services.AddSingleton<FileWatcherService>();
builder.Services.AddHostedService(sp => sp.GetRequiredService<FileWatcherService>());
builder.Services.AddHostedService<SystemMonitorService>();

var app = builder.Build();

app.UseCors();
app.UseRouting();
app.UseAuthentication();
app.UseAuthorization();
app.UseMiddleware<PathSecurityMiddleware>();
app.MapControllers();
app.MapHub<MediaHub>("/hubs/media");

app.Run();
