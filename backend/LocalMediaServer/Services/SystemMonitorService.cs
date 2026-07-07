using System.Diagnostics;
using System.Net.NetworkInformation;
using System.Runtime.InteropServices;
using LocalMediaServer.Hubs;
using Microsoft.AspNetCore.SignalR;

namespace LocalMediaServer.Services;

public class SystemMonitorService : BackgroundService
{
    private readonly IHubContext<MediaHub> _hubContext;
    private readonly ILogger<SystemMonitorService> _logger;
    private PerformanceCounter? _cpuCounter;
    private PerformanceCounter? _diskReadCounter;
    private PerformanceCounter? _diskWriteCounter;

    // Network tracking
    private long _prevBytesReceived;
    private long _prevBytesSent;
    private DateTime _prevTime;

    public SystemMonitorService(IHubContext<MediaHub> hubContext, ILogger<SystemMonitorService> logger)
    {
        _hubContext = hubContext;
        _logger = logger;
        
        try
        {
            if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
            {
                try
                {
                    _cpuCounter = new PerformanceCounter("Processor Information", "% Processor Utility", "_Total", true);
                    _cpuCounter.NextValue();
                }
                catch
                {
                    // Fallback for older Windows
                    _cpuCounter = new PerformanceCounter("Processor", "% Processor Time", "_Total", true);
                    _cpuCounter.NextValue();
                }

                _diskReadCounter = new PerformanceCounter("PhysicalDisk", "Disk Read Bytes/sec", "_Total", true);
                _diskWriteCounter = new PerformanceCounter("PhysicalDisk", "Disk Write Bytes/sec", "_Total", true);
                
                // Khởi động counter lần đầu để có kết quả chính xác
                _diskReadCounter.NextValue();
                _diskWriteCounter.NextValue();
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning($"Không thể khởi tạo PerformanceCounters: {ex.Message}. Cần chạy quyền Admin để đo chính xác CPU và Ổ đĩa.");
        }

        UpdateNetworkStats(out _prevBytesReceived, out _prevBytesSent);
        _prevTime = DateTime.UtcNow;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                var metrics = GetSystemMetrics();
                await _hubContext.Clients.All.SendAsync("ReceiveSystemMetrics", metrics, cancellationToken: stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi khi đo đếm thông số hệ thống: {ex.Message}");
            }

            await Task.Delay(1000, stoppingToken);
        }
    }

    private object GetSystemMetrics()
    {
        // 1. CPU
        float cpuUsage = 0;
        if (_cpuCounter != null)
        {
            try { 
                cpuUsage = _cpuCounter.NextValue(); 
                if (cpuUsage > 100f) cpuUsage = 100f;
            } catch { }
        }

        // 2. RAM (Sử dụng GlobalMemoryStatusEx để đọc chính xác tuyệt đối mà không cần quyền Admin)
        var ramInfo = GetRamInfo();
        double totalRamGb = ramInfo.TotalPhysical / (1024.0 * 1024 * 1024);
        double usedRamGb = (ramInfo.TotalPhysical - ramInfo.AvailablePhysical) / (1024.0 * 1024 * 1024);

        // 3. Disk I/O
        float diskRead = 0;
        float diskWrite = 0;
        if (_diskReadCounter != null && _diskWriteCounter != null)
        {
            try
            {
                diskRead = _diskReadCounter.NextValue() / 1024f; // KB/s
                diskWrite = _diskWriteCounter.NextValue() / 1024f; // KB/s
            }
            catch { }
        }

        // 4. Network I/O
        UpdateNetworkStats(out long currentReceived, out long currentSent);
        var now = DateTime.UtcNow;
        var elapsedSeconds = (now - _prevTime).TotalSeconds;
        
        double netReceiveKbps = 0;
        double netSendKbps = 0;
        
        if (elapsedSeconds > 0)
        {
            // Bytes to KB/s
            netReceiveKbps = ((currentReceived - _prevBytesReceived) / elapsedSeconds) / 1024.0;
            netSendKbps = ((currentSent - _prevBytesSent) / elapsedSeconds) / 1024.0;
        }

        _prevBytesReceived = currentReceived;
        _prevBytesSent = currentSent;
        _prevTime = now;

        return new
        {
            cpu = Math.Round(cpuUsage, 1),
            ramUsed = Math.Round(usedRamGb, 2),
            ramTotal = Math.Round(totalRamGb, 2),
            diskRead = Math.Round(diskRead, 1),
            diskWrite = Math.Round(diskWrite, 1),
            netReceive = Math.Round(netReceiveKbps, 1),
            netSend = Math.Round(netSendKbps, 1),
            timestamp = DateTime.UtcNow.ToString("O")
        };
    }

    private void UpdateNetworkStats(out long totalReceived, out long totalSent)
    {
        totalReceived = 0;
        totalSent = 0;
        if (!NetworkInterface.GetIsNetworkAvailable()) return;

        var interfaces = NetworkInterface.GetAllNetworkInterfaces();
        foreach (var ni in interfaces)
        {
            if (ni.OperationalStatus == OperationalStatus.Up && 
                ni.NetworkInterfaceType != NetworkInterfaceType.Loopback)
            {
                var stats = ni.GetIPv4Statistics();
                totalReceived += stats.BytesReceived;
                totalSent += stats.BytesSent;
            }
        }
    }

    // Windows P/Invoke for exact RAM info without Admin permissions
    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool GlobalMemoryStatusEx(ref MEMORYSTATUSEX lpBuffer);

    [StructLayout(LayoutKind.Sequential)]
    private struct MEMORYSTATUSEX
    {
        public uint dwLength;
        public uint dwMemoryLoad;
        public ulong ullTotalPhys;
        public ulong ullAvailPhys;
        public ulong ullTotalPageFile;
        public ulong ullAvailPageFile;
        public ulong ullTotalVirtual;
        public ulong ullAvailVirtual;
        public ulong ullAvailExtendedVirtual;
    }

    private (ulong TotalPhysical, ulong AvailablePhysical) GetRamInfo()
    {
        if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
        {
            var memStatus = new MEMORYSTATUSEX();
            memStatus.dwLength = (uint)Marshal.SizeOf(typeof(MEMORYSTATUSEX));
            if (GlobalMemoryStatusEx(ref memStatus))
            {
                return (memStatus.ullTotalPhys, memStatus.ullAvailPhys);
            }
        }
        
        // Fallback for non-windows or errors: process RAM only
        var proc = Process.GetCurrentProcess();
        return (4UL * 1024 * 1024 * 1024, (ulong)proc.WorkingSet64); 
    }
}
