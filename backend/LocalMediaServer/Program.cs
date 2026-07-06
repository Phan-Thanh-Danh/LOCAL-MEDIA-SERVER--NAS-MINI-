using LocalMediaServer.Hubs;
using LocalMediaServer.Middleware;
using LocalMediaServer.Services;
using Serilog;

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

builder.Services.Configure<MediaServerOptions>(builder.Configuration.GetSection(MediaServerOptions.SectionName));
builder.Services.AddSingleton<IMediaFileService, MediaFileService>();
builder.Services.AddSingleton<FileWatcherService>();
builder.Services.AddHostedService(sp => sp.GetRequiredService<FileWatcherService>());

var app = builder.Build();

app.UseCors();
app.UseMiddleware<PathSecurityMiddleware>();
app.UseRouting();
app.MapControllers();
app.MapHub<MediaHub>("/hubs/media");

app.Run();
