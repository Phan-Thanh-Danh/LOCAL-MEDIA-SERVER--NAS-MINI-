using System;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using System.Collections.Generic;

namespace Launcher
{
    public class Program
    {
        // P/Invoke for ANSI Colors in Windows Console
        private const int STD_OUTPUT_HANDLE = -11;
        private const uint ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004;

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern IntPtr GetStdHandle(int nStdHandle);

        [DllImport("kernel32.dll")]
        private static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);

        [DllImport("kernel32.dll")]
        private static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);

        private static readonly Dictionary<char, string[]> Font = new Dictionary<char, string[]>
        {
            ['N'] = new[] { "#   #", "##  #", "# # #", "#  ##", "#   #" },
            ['A'] = new[] { " ### ", "#   #", "#####", "#   #", "#   #" },
            ['S'] = new[] { " ####", "#    ", " ### ", "    #", "#### " },
            ['_'] = new[] { "     ", "     ", "     ", "     ", "#####" },
            ['D'] = new[] { "#### ", "#   #", "#   #", "#   #", "#### " },
            ['Z'] = new[] { "#####", "   # ", "  #  ", " #   ", "#####" },
            ['O'] = new[] { " ### ", "#   #", "#   #", "#   #", " ### " },
            ['E'] = new[] { "#####", "#    ", "###  ", "#    ", "#####" },
            ['X'] = new[] { "#   #", " # # ", "  #  ", " # # ", "#   #" }
        };

        private static readonly int[] Gradient = { 178, 214, 220, 226, 220, 214, 178, 172, 208, 214, 220, 226 };
        
        public static void Main(string[] args)
        {
            MainAsync(args).GetAwaiter().GetResult();
        }

        public static async Task MainAsync(string[] args)
        {
            EnableAnsi();
            try { Console.Title = "NAS DANZODEX - Services"; } catch { }
            try { Console.Clear(); } catch { }

            PrintLogo("NAS_DANZODEX");

            Console.WriteLine();
            Console.WriteLine("  \x1b[38;5;220m>> N A S _ D A N Z O D E X   T O O L S U I T E <<\x1b[0m");
            Console.WriteLine();

            string basePath = @"D:\LOCAL MEDIA SERVER (NAS MINI)";
            string backendPath = Path.Combine(basePath, "backend", "LocalMediaServer");
            string frontendPath = Path.Combine(basePath, "frontend");

            InitializeJobObject();

            var beTask = StartProcessWithProgressBar("Backend service", 214, "dotnet", "run --urls http://0.0.0.0:5000", backendPath);
            var feTask = StartProcessWithProgressBar("Frontend service", 226, "cmd.exe", "/c npm run dev -- --host 0.0.0.0 --port 5173", frontendPath);
            var cfTask = StartProcessWithProgressBar("Cloudflare Tunnel", 208, "cloudflared", "tunnel --url https://localhost:5173 --no-tls-verify --logfile cloudflare_tunnel.log", basePath);

            var (backendProc, frontendProc, cloudflareProc) = (await beTask, await feTask, await cfTask);
            
            Console.WriteLine();
            Console.WriteLine("  \x1b[1m\x1b[38;5;51m╔═══════════════════════ LOCAL SERVICES ═══════════════════════╗\x1b[0m");
            Console.WriteLine("  \x1b[1m\x1b[38;5;51m║\x1b[0m  \x1b[38;5;214mBackend\x1b[0m  : http://0.0.0.0:5000                            \x1b[1m\x1b[38;5;51m║\x1b[0m");
            Console.WriteLine("  \x1b[1m\x1b[38;5;51m║\x1b[0m  \x1b[38;5;226mFrontend\x1b[0m : https://localhost:5173                         \x1b[1m\x1b[38;5;51m║\x1b[0m");
            Console.WriteLine("  \x1b[1m\x1b[38;5;51m╚══════════════════════════════════════════════════════════════╝\x1b[0m");
            Console.WriteLine();

            Console.WriteLine("  \x1b[1m\x1b[38;5;178m── REQUEST / AUDIT ACTIVITY LOG ───────────────────────────────\x1b[0m");

            var beLogTask = StreamLogs(backendProc, "Backend");
            var feLogTask = StreamLogs(frontendProc, "Frontend");
            var cfLogTask = StreamLogs(cloudflareProc, "Cloudflare");

            Console.WriteLine("  \x1b[1m\x1b[38;5;82m✔ System ready. All services operational.\x1b[0m\n");

            // Open Browser
            try
            {
                Process.Start(new ProcessStartInfo
                {
                    FileName = "https://localhost:5173",
                    UseShellExecute = true
                });
            }
            catch { }

            await Task.WhenAll(beLogTask, feLogTask, cfLogTask);
        }

        private static void EnableAnsi()
        {
            var handle = GetStdHandle(STD_OUTPUT_HANDLE);
            GetConsoleMode(handle, out uint mode);
            SetConsoleMode(handle, mode | ENABLE_VIRTUAL_TERMINAL_PROCESSING);
        }

        private static void PrintLogo(string text)
        {
            int height = 5;
            string[] lines = new string[height];
            for (int i = 0; i < height; i++) lines[i] = "";

            foreach (char ch in text)
            {
                var glyph = Font.ContainsKey(ch) ? Font[ch] : new[] { "     ", "     ", "     ", "     ", "     " };
                for (int i = 0; i < height; i++)
                {
                    lines[i] += glyph[i] + " ";
                }
            }

            int n = Gradient.Length;
            int width = lines[0].Length;
            Console.WriteLine();
            foreach (var line in lines)
            {
                string colored = "  ";
                for (int x = 0; x < line.Length; x++)
                {
                    if (line[x] == '#')
                    {
                        int color = Gradient[(int)((double)x / Math.Max(width, 1) * n) % n];
                        colored += $"\x1b[1m\x1b[38;5;{color}m█\x1b[0m";
                    }
                    else
                    {
                        colored += " ";
                    }
                }
                Console.WriteLine(colored);
            }
        }

        private static async Task<Process> StartProcessWithProgressBar(string label, int color, string fileName, string args, string wd)
        {
            var psi = new ProcessStartInfo
            {
                FileName = fileName,
                Arguments = args,
                WorkingDirectory = wd,
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true
            };

            var proc = Process.Start(psi);
            AddProcessToJob(proc);

            int width = 30;
            for (int pct = 0; pct <= 100; pct += 5)
            {
                int filled = (width * pct) / 100;
                string bar = new string('█', filled) + new string('░', width - filled);
                Console.Write($"\r  \x1b[38;5;{color}m{label,-22}\x1b[0m \x1b[38;5;{color}m[{bar}]\x1b[0m {pct,3}%");
                await Task.Delay(40);
            }
            Console.WriteLine($"\r  \x1b[38;5;{color}m{label,-22}\x1b[0m \x1b[38;5;{color}m[{new string('█', width)}]\x1b[0m 100%  \x1b[1m\x1b[38;5;82mONLINE\x1b[0m");

            return proc;
        }

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
        static extern IntPtr CreateJobObject(IntPtr a, string lpName);

        [DllImport("kernel32.dll")]
        static extern bool SetInformationJobObject(IntPtr hJob, int JobObjectInfoClass, IntPtr lpJobObjectInfo, int cbJobObjectInfoLength);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool AssignProcessToJobObject(IntPtr job, IntPtr process);

        [StructLayout(LayoutKind.Sequential)]
        struct JOBOBJECT_BASIC_LIMIT_INFORMATION
        {
            public Int64 PerProcessUserTimeLimit;
            public Int64 PerJobUserTimeLimit;
            public UInt32 LimitFlags;
            public UIntPtr MinimumWorkingSetSize;
            public UIntPtr MaximumWorkingSetSize;
            public UInt32 ActiveProcessLimit;
            public UIntPtr Affinity;
            public UInt32 PriorityClass;
            public UInt32 SchedulingClass;
        }

        [StructLayout(LayoutKind.Sequential)]
        struct IO_COUNTERS
        {
            public UInt64 ReadOperationCount;
            public UInt64 WriteOperationCount;
            public UInt64 OtherOperationCount;
            public UInt64 ReadTransferCount;
            public UInt64 WriteTransferCount;
            public UInt64 OtherTransferCount;
        }

        [StructLayout(LayoutKind.Sequential)]
        struct JOBOBJECT_EXTENDED_LIMIT_INFORMATION
        {
            public JOBOBJECT_BASIC_LIMIT_INFORMATION BasicLimitInformation;
            public IO_COUNTERS IoInfo;
            public UIntPtr ProcessMemoryLimit;
            public UIntPtr JobMemoryLimit;
            public UIntPtr PeakProcessMemoryUsed;
            public UIntPtr PeakJobMemoryUsed;
        }

        private static IntPtr _jobHandle;

        private static void InitializeJobObject()
        {
            _jobHandle = CreateJobObject(IntPtr.Zero, null);
            var info = new JOBOBJECT_EXTENDED_LIMIT_INFORMATION
            {
                BasicLimitInformation = new JOBOBJECT_BASIC_LIMIT_INFORMATION
                {
                    LimitFlags = 0x2000 // JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
                }
            };
            
            int length = Marshal.SizeOf(typeof(JOBOBJECT_EXTENDED_LIMIT_INFORMATION));
            IntPtr extendedInfoPtr = Marshal.AllocHGlobal(length);
            Marshal.StructureToPtr(info, extendedInfoPtr, false);
            
            SetInformationJobObject(_jobHandle, 9, extendedInfoPtr, length);
            Marshal.FreeHGlobal(extendedInfoPtr);
        }

        private static void AddProcessToJob(Process process)
        {
            if (_jobHandle != IntPtr.Zero)
            {
                AssignProcessToJobObject(_jobHandle, process.Handle);
            }
        }

        private static async Task StreamLogs(Process process, string serviceType)
        {
            var serilogRegex = new Regex(
                @"HTTP\s+(GET|POST|PUT|DELETE|PATCH)\s+([^ ]+)\s+responded\s+(\d+)\s+in\s+([\d\.,]+)\s+ms",
                RegexOptions.Compiled | RegexOptions.IgnoreCase
            );

            var aspnetRegex = new Regex(
                @"Request finished HTTP/[0-9\.]+\s+(GET|POST|PUT|DELETE|PATCH)\s+https?://[^/]+([^ ]*)\s+-\s+(\d+).*?([\d\.,]+)ms",
                RegexOptions.Compiled | RegexOptions.IgnoreCase
            );

            var cfRegex = new Regex(@"https://[a-zA-Z0-9-]+\.trycloudflare\.com", RegexOptions.Compiled | RegexOptions.IgnoreCase);
            bool cfUrlFound = false;

            if (serviceType == "Cloudflare")
            {
                _ = Task.Run(async () =>
                {
                    string logPath = "cloudflare_tunnel.log";
                    while (!process.HasExited)
                    {
                        try
                        {
                            File.AppendAllText("cf_poll_debug.log", $"Poll: {File.Exists(logPath)}\n");
                            if (File.Exists(logPath))
                            {
                                using var fs = new FileStream(logPath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite);
                                using var reader = new StreamReader(fs);
                                string content = await reader.ReadToEndAsync();
                                File.AppendAllText("cf_poll_debug.log", $"Read {content.Length} bytes\n");
                                
                                if (!cfUrlFound)
                                {
                                    var match = cfRegex.Match(content);
                                    if (match.Success)
                                    {
                                        cfUrlFound = true;
                                        string url = match.Value;
                                        try { Console.Title = $"NAS DANZODEX - {url}"; } catch { }
                                        Console.WriteLine();
                                        Console.WriteLine($"  \x1b[1m\x1b[38;5;82m╔═════════════════════════ PUBLIC ACCESS ═════════════════════════╗\x1b[0m");
                                        Console.WriteLine($"  \x1b[1m\x1b[38;5;82m║\x1b[0m \x1b[38;5;208mCloudflare Tunnel:\x1b[0m \x1b[1m\x1b[38;5;51m{url,-44}\x1b[0m\x1b[1m\x1b[38;5;82m║\x1b[0m");
                                        Console.WriteLine($"  \x1b[1m\x1b[38;5;82m╚═════════════════════════════════════════════════════════════════╝\x1b[0m");
                                        Console.WriteLine();
                                        File.AppendAllText("cf_poll_debug.log", $"Found URL: {url}\n");
                                        break; // Found it, no need to poll anymore
                                    }
                                }
                            }
                        }
                        catch (Exception ex) { File.AppendAllText("cf_poll_debug.log", $"Error: {ex.Message}\n"); }
                        await Task.Delay(500);
                    }
                });
                return;
            }

            async Task ReadStreamAsync(StreamReader reader, string source)
            {
                while (true)
                {
                    string line = await reader.ReadLineAsync();
                    if (line == null) break;
                    if (string.IsNullOrWhiteSpace(line)) continue;

                    line = Regex.Replace(line, @"\x1B\[[^@-~]*[@-~]", "");

                    if (serviceType != "Backend")
                        continue;

                    var match2 = serilogRegex.Match(line);
                    if (!match2.Success)
                        match2 = aspnetRegex.Match(line);

                    if (!match2.Success)
                    {
                        // Uncomment to debug raw log formats:
                        // Console.WriteLine($"[RAW:{source}] {line}");
                        continue;
                    }

                    string method = match2.Groups[1].Value;
                    string endpoint = match2.Groups[2].Value;
                    string status = match2.Groups[3].Value;
                    string latency = match2.Groups[4].Value;

                    if (endpoint.Length > 40)
                        endpoint = endpoint.Substring(0, 37) + "...";

                    int st = int.TryParse(status, out var parsedStatus) ? parsedStatus : 0;
                    string level = st < 400 ? "INFO" : st < 500 ? "WARN" : "ERROR";

                    int mcolor = method.ToUpper() == "GET" ? 45 : (method.ToUpper() == "POST" ? 214 : (method.ToUpper() == "PUT" ? 220 : 203));
                    int scolor = st < 300 ? 82 : (st < 500 ? 220 : 196);
                    int lcolor = level == "INFO" ? 82 : (level == "WARN" ? 220 : 196);

                    string ts = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");

                    Console.WriteLine($"  \x1b[38;5;240m[{ts}]\x1b[0m " +
                                      $"\x1b[1m\x1b[38;5;{lcolor}m{level,-5}\x1b[0m " +
                                      $"\x1b[38;5;{mcolor}m{method,-6}\x1b[0m " +
                                      $"{endpoint,-40} " +
                                      $"\x1b[1m\x1b[38;5;{scolor}m{status}\x1b[0m " +
                                      $"\x1b[38;5;240m{latency}ms\x1b[0m");
                }
            }

            var outputTask = ReadStreamAsync(process.StandardOutput, "OUT");
            var errorTask = ReadStreamAsync(process.StandardError, "ERR");

            await Task.WhenAll(outputTask, errorTask);
        }
    }
}
