using System;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Net.NetworkInformation;
using System.Threading;
using System.Threading.Tasks;

class Program
{
    static async Task Main(string[] args)
    {
        Console.Title = "Local Media Server - NAS Mini";
        Console.ForegroundColor = ConsoleColor.Green;
        Console.Clear();
        
        PrintHeader();
        
        try
        {
            string basePath = @"D:\LOCAL MEDIA SERVER (NAS MINI)";
            string backendPath = Path.Combine(basePath, "backend", "LocalMediaServer");
            string frontendPath = Path.Combine(basePath, "frontend");
            
            // Get LAN IP
            string lanIP = GetLocalIPAddress();
            
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine("\n[1/2] Starting Backend (ASP.NET Core)...\n");
            Console.ResetColor();
            
            // Start backend
            var backendProcess = StartBackend(backendPath);
            
            // Wait for backend to start
            await Task.Delay(3000);
            Console.WriteLine("✓ Backend started\n");
            
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine("[2/2] Starting Frontend (Vue.js + Vite)...\n");
            Console.ResetColor();
            
            // Start frontend
            var frontendProcess = StartFrontend(frontendPath);
            
            // Wait for frontend to be ready
            await Task.Delay(5000);
            Console.WriteLine("✓ Frontend started\n");
            
            // Open browser
            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine("Opening browser...\n");
            Console.ResetColor();
            
            try
            {
                Process.Start(new ProcessStartInfo
                {
                    FileName = "http://127.0.0.1:5173",
                    UseShellExecute = true
                });
            }
            catch { }
            
            // Print info
            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine("========================================");
            Console.WriteLine("   Local Media Server Started!");
            Console.WriteLine("========================================\n");
            Console.ResetColor();
            
            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine($"Local Access:  http://127.0.0.1:5173");
            Console.WriteLine($"LAN Access:    http://{lanIP}:5173\n");
            Console.WriteLine($"Backend API:   http://127.0.0.1:5000\n");
            Console.ResetColor();
            
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine("Close this window to stop the services.");
            Console.WriteLine("========================================\n");
            Console.ResetColor();
            
            // Keep the window open
            await Task.Delay(Timeout.Infinite);
        }
        catch (Exception ex)
        {
            Console.ForegroundColor = ConsoleColor.Red;
            Console.WriteLine($"\n✗ Error: {ex.Message}");
            Console.ResetColor();
            Console.WriteLine("\nPress any key to exit...");
            Console.ReadKey();
        }
    }
    
    static Process StartBackend(string backendPath)
    {
        var psi = new ProcessStartInfo
        {
            FileName = "dotnet",
            Arguments = "run --no-build --urls http://0.0.0.0:5000",
            WorkingDirectory = backendPath,
            UseShellExecute = true,
            CreateNoWindow = false,
            WindowStyle = ProcessWindowStyle.Normal
        };
        
        return Process.Start(psi);
    }
    
    static Process StartFrontend(string frontendPath)
    {
        var psi = new ProcessStartInfo
        {
            FileName = "cmd",
            Arguments = $"/k npm run dev -- --host 0.0.0.0 --port 5173",
            WorkingDirectory = frontendPath,
            UseShellExecute = true,
            CreateNoWindow = false,
            WindowStyle = ProcessWindowStyle.Normal
        };
        
        return Process.Start(psi);
    }
    
    static string GetLocalIPAddress()
    {
        foreach (var netInterface in NetworkInterface.GetAllNetworkInterfaces())
        {
            if (netInterface.NetworkInterfaceType == NetworkInterfaceType.Ethernet ||
                netInterface.NetworkInterfaceType == NetworkInterfaceType.Wireless80211)
            {
                var ipProps = netInterface.GetIPProperties();
                foreach (var addr in ipProps.UnicastAddresses)
                {
                    if (addr.Address.AddressFamily == System.Net.Sockets.AddressFamily.InterNetwork)
                    {
                        string ip = addr.Address.ToString();
                        if (ip.StartsWith("192.") || ip.StartsWith("10.") || ip.StartsWith("172."))
                        {
                            return ip;
                        }
                    }
                }
            }
        }
        
        return "localhost";
    }
    
    static void PrintHeader()
    {
        Console.WriteLine(@"
╔════════════════════════════════════════╗
║   Local Media Server - NAS Mini         ║
║   Browser: Video + Image Viewer         ║
╚════════════════════════════════════════╝
");
    }
}
