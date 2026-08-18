[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null
Clear-Host

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin -and $Host.Name -eq "ConsoleHost" -and $PSCommandPath -and -not [Console]::IsInputRedirected) {
    try {
        Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$PSCommandPath`"" -Verb RunAs -ErrorAction Stop
        exit
    } catch { }
}

$currentFont = (Get-ItemProperty "HKCU:\\Console" -ErrorAction SilentlyContinue).FaceName
if ($currentFont -notmatch "NSimSun|Gothic|Noto") {
    Write-Host "Tip: For optimal Unicode character rendering, set your terminal font to 'NSimSun'" -ForegroundColor DarkYellow
    Write-Host
}

$Banner = @"

  ┌───────────────────────────────────────────────────────────────────────────┐
  │  █████╗ ██████╗ ██████╗ ████████╗    ███╗   ███╗██████╗ ██████╗          │
  │ ██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝    ████╗ ████║██╔══██╗██╔══██╗         │
  │ ███████║██████╔╝██████╔╝   ██║       ██╔████╔██║██║  ██║██║  ██║         │
  │ ██╔══██║██╔═══╝ ██╔═══╝    ██║       ██║╚██╔╝██║██║  ██║██║  ██║         │
  │ ██║  ██║██║     ██║        ██║       ██║ ╚═╝ ██║╚██████╔╝██████╔╝         │
  │ ╚═╝  ╚═╝╚═╝     ╚═╝        ╚═╝       ╚═╝     ╚═╝ ╚═════╝ ╚═════╝          │
  │  █████╗ ███╗   ██╗█████╗ ██╗  ██╗███████╗███████╗██████╗                 │
  │ ██╔══██╗████╗  ██║██╔══██╗██║  ██║╚══███╔╝██╔════╝██╔══██╗                │
  │ ███████║██╔██╗ ██║███████║██║  ██║  ███╔╝ █████╗  ██████╔╝                │
  │ ██╔══██║██║╚██╗██║██╔══██║██║  ██║ ███╔╝  ██╔══╝  ██╔══██╗                │
  │ ██║  ██║██║ ╚████║██║  ██║███████║███████╗███████╗██║  ██║                │
  │ ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝                │
  └───────────────────────────────────────────────────────────────────────────┘

"@

Write-Host $Banner -ForegroundColor Cyan
Write-Host ""
Write-Host "                                   by " -ForegroundColor Gray -NoNewline
Write-Host "APPT" -ForegroundColor Cyan
Write-Host ""
Write-Host ("─" * 77) -ForegroundColor DarkCyan
Write-Host

$discoveredPaths = [System.Collections.Generic.List[string]]::new()

$mcProcess = Get-Process javaw -ErrorAction SilentlyContinue
if (-not $mcProcess) { $mcProcess = Get-Process java -ErrorAction SilentlyContinue }

if ($mcProcess) {
    try {
        $targetPid = ($mcProcess | Select-Object -First 1).Id
        $wmiProc = Get-CimInstance Win32_Process -Filter "ProcessId = $targetPid" -ErrorAction SilentlyContinue
        if ($wmiProc -and $wmiProc.CommandLine) {
            if ($wmiProc.CommandLine -match '--gameDir\\s+(?:"([^"]+)"|([^\\s]+))') {
                $gDir = if ($matches[1]) { $matches[1] } else { $matches[2] }
                $gMods = Join-Path $gDir "mods"
                if (Test-Path $gMods) { [void]$discoveredPaths.Add($gMods) }
            }
        }
    } catch { }
}

$launcherPatterns = @(
    "$env:APPDATA\\PrismLauncher\\instances\\*\\.minecraft\\mods",
    "$env:APPDATA\\MultiMC\\instances\\*\\.minecraft\\mods",
    "$env:APPDATA\\com.modrinth.theseus\\profiles\\*\\mods",
    "$env:USERPROFILE\\curseforge\\minecraft\\Instances\\*\\mods",
    "$env:APPDATA\\.feather\\user-mods",
    "$env:USERPROFILE\\.lunarclient\\offline\\multiver\\mods",
    "$env:APPDATA\\ATLauncher\\instances\\*\\mods",
    "$env:APPDATA\\gdlauncher_next\\instances\\*\\mods",
    "$env:APPDATA\\.tlauncher\\legacy\\Minecraft\\game\\mods",
    "$env:APPDATA\\.minecraft\\mods"
)

foreach ($lp in $launcherPatterns) {
    try {
        $resolved = Resolve-Path $lp -ErrorAction SilentlyContinue
        if ($resolved) {
            foreach ($r in $resolved) {
                $p = $r.Path
                if (Test-Path $p -PathType Container) {
                    $jarCount = (Get-ChildItem -Path $p -Filter *.jar -ErrorAction SilentlyContinue).Count
                    if ($jarCount -gt 0 -and -not $discoveredPaths.Contains($p)) {
                        [void]$discoveredPaths.Add($p)
                    }
                }
            }
        }
    } catch { }
}

$modsPath = ""
if ($discoveredPaths.Count -eq 1) {
    $suggested = $discoveredPaths[0]
    Write-Host "Auto-discovered active mods folder: " -ForegroundColor DarkCyan -NoNewline
    Write-Host $suggested -ForegroundColor White
    Write-Host "Press Enter to scan this folder or type a custom path: " -NoNewline
    $userChoice = Read-Host "PATH"
    $modsPath = if ([string]::IsNullOrWhiteSpace($userChoice)) { $suggested } else { $userChoice.Trim('"') }
} elseif ($discoveredPaths.Count -gt 1) {
    Write-Host "Discovered multiple Minecraft instances:" -ForegroundColor DarkCyan
    for ($i = 0; $i -lt $discoveredPaths.Count; $i++) {
        $count = (Get-ChildItem -Path $discoveredPaths[$i] -Filter *.jar -ErrorAction SilentlyContinue).Count
        Write-Host "  [$($i + 1)] " -ForegroundColor Cyan -NoNewline
        Write-Host "$($discoveredPaths[$i]) " -ForegroundColor White -NoNewline
        Write-Host "($count mods)" -ForegroundColor Gray
    }
    Write-Host "Select number [1-$($discoveredPaths.Count)] or enter path: " -NoNewline
    $userChoice = Read-Host "PATH"
    if ($userChoice -match "^\\d+$" -and [int]$userChoice -ge 1 -and [int]$userChoice -le $discoveredPaths.Count) {
        $modsPath = $discoveredPaths[[int]$userChoice - 1]
    } elseif ([string]::IsNullOrWhiteSpace($userChoice)) {
        $modsPath = $discoveredPaths[0]
    } else {
        $modsPath = $userChoice.Trim('"')
    }
} else {
    Write-Host "Enter mods folder path: " -NoNewline
    Write-Host "(press Enter for default)" -ForegroundColor DarkGray
    $userChoice = Read-Host "PATH"
    $modsPath = if ([string]::IsNullOrWhiteSpace($userChoice)) { "$env:USERPROFILE\\AppData\\Roaming\\.minecraft\\mods" } else { $userChoice.Trim('"') }
}
Write-Host

if (-not (Test-Path $modsPath -PathType Container)) {
    Write-Host "Error: Directory does not exist or is not accessible." -ForegroundColor Red
    Write-Host "Path: $modsPath" -ForegroundColor Gray
    Write-Host
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

try {
    $jarFiles = Get-ChildItem -Path $modsPath -Filter *.jar -ErrorAction Stop
} catch {
    Write-Host "Error accessing directory: $_" -ForegroundColor Red
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

if ($jarFiles.Count -eq 0) {
    Write-Host "No JAR files found in: $modsPath" -ForegroundColor Yellow
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 0
}

$totalFiles = $jarFiles.Count
$fileWord = if ($totalFiles -eq 1) { "file" } else { "files" }
$totalBytes = ($jarFiles | Measure-Object -Property Length -Sum).Sum
$totalMB = [math]::Round($totalBytes / 1MB, 2)
$sortedBySize = $jarFiles | Sort-Object Length
$smallestFile = $sortedBySize[0]
$largestFile = $sortedBySize[-1]

Write-Host "Target directory confirmed: $modsPath" -ForegroundColor Green
Write-Host "Found $totalFiles JAR $fileWord (total: $totalMB MB)" -ForegroundColor DarkCyan
Write-Host "   Largest:  $($largestFile.Name) ($([math]::Round($largestFile.Length/1MB, 2)) MB)" -ForegroundColor Gray
Write-Host "   Smallest: $($smallestFile.Name) ($([math]::Round($smallestFile.Length/1KB, 1)) KB)" -ForegroundColor Gray
Write-Host

if ($mcProcess) {
    try {
        $startTime = $mcProcess[0].StartTime
        $uptime = (Get-Date) - $startTime
        Write-Host "Active Game Process:" -ForegroundColor DarkCyan
        Write-Host "   $($mcProcess[0].Name) (PID: $($mcProcess[0].Id)) started at $startTime" -ForegroundColor Gray
        Write-Host "   Session uptime: $($uptime.Hours)h $($uptime.Minutes)m $($uptime.Seconds)s" -ForegroundColor Gray
        Write-Host ""
    } catch { }
}

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$fastScannerSource = @'
using System;
using System.IO;
using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;
using System.Runtime.InteropServices;

public static class FastScanner {
    public static HashSet<string> PatternSet = new HashSet<string>(StringComparer.Ordinal);
    public static HashSet<string> MacroSet = new HashSet<string>(StringComparer.Ordinal);
    public static HashSet<string> ContentSet = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
    public static HashSet<string> ReflectionSet = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
    public static Regex FullwidthRegex = new Regex(@"[Ａ-Ｚａ-ｚ０-９]{2,}", RegexOptions.Compiled);
    public static Regex Base64Regex = new Regex(@"^[A-Za-z0-9+/]{24,}={0,2}$", RegexOptions.Compiled);

    public static void InitAll(string[] patterns, string[] macros, string[] content, string[] reflection) {
        PatternSet = new HashSet<string>(patterns ?? new string[0], StringComparer.Ordinal);
        MacroSet = new HashSet<string>(macros ?? new string[0], StringComparer.Ordinal);
        ContentSet = new HashSet<string>(content ?? new string[0], StringComparer.OrdinalIgnoreCase);
        ReflectionSet = new HashSet<string>(reflection ?? new string[0], StringComparer.OrdinalIgnoreCase);
    }

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr OpenProcess(int dwDesiredAccess, bool bInheritHandle, int dwProcessId);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool CloseHandle(IntPtr hObject);

    [DllImport("kernel32.dll")]
    public static extern int VirtualQueryEx(IntPtr hProcess, IntPtr lpAddress, out MEMORY_BASIC_INFORMATION lpBuffer, uint dwLength);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool ReadProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, [Out] byte[] lpBuffer, int dwSize, out IntPtr lpNumberOfBytesRead);

    [DllImport("psapi.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern uint GetMappedFileName(IntPtr hProcess, IntPtr lpv, [Out] StringBuilder lpFilename, uint nSize);

    [DllImport("psapi.dll", SetLastError = true)]
    public static extern bool EnumProcessModules(IntPtr hProcess, [Out] IntPtr[] lphModule, uint cb, out uint lpcbNeeded);

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern uint QueryDosDevice(string lpDeviceName, [Out] StringBuilder lpTargetPath, uint ucchMax);

    [DllImport("kernel32.dll", CharSet = CharSet.Ansi, SetLastError = true)]
    public static extern IntPtr GetProcAddress(IntPtr hModule, string procName);

    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern IntPtr GetModuleHandle(string lpModuleName);

    [StructLayout(LayoutKind.Sequential)]
    public struct MEMORY_BASIC_INFORMATION {
        public IntPtr BaseAddress;
        public IntPtr AllocationBase;
        public uint AllocationProtect;
        public IntPtr RegionSize;
        public uint State;
        public uint Protect;
        public uint Type;
    }

    public class MemoryScanReport {
        public List<string> MappedJars = new List<string>();
        public List<string> DiscoveredJarPaths = new List<string>();
        public List<string> GhostCheatSignatures = new List<string>();
        public List<string> UnloadedMods = new List<string>();
        public List<string> InjectedPEHeaders = new List<string>();
        public List<string> SuspiciousRWXRegions = new List<string>();
        public List<string> CheatConfigSnippets = new List<string>();
        public List<string> HookedExports = new List<string>();
        public bool JvmAttachListenerActive = false;
        public string AttachSocketPath = "";
        public List<string> UnlinkedModules = new List<string>();
        public List<string> GhostMixinHandlers = new List<string>();
        public List<string> CheatGUIElements = new List<string>();
        public List<string> MemoryNetworkEndpoints = new List<string>();
        public List<string> JvmInstrumentationTraces = new List<string>();
        public List<string> JNativeHookTraces = new List<string>();
    }

    private static Dictionary<string, string> DeviceToDriveMap = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

    static FastScanner() {
        try {
            foreach (DriveInfo d in DriveInfo.GetDrives()) {
                string driveLetter = d.Name.TrimEnd('\\');
                StringBuilder sb = new StringBuilder(512);
                if (QueryDosDevice(driveLetter, sb, (uint)sb.Capacity) > 0) {
                    DeviceToDriveMap[sb.ToString()] = driveLetter;
                }
            }
        } catch { }
    }

    private static string NormalizeDevicePath(string path) {
        if (string.IsNullOrEmpty(path)) return path;
        foreach (var kvp in DeviceToDriveMap) {
            if (path.StartsWith(kvp.Key, StringComparison.OrdinalIgnoreCase)) {
                return kvp.Value + path.Substring(kvp.Key.Length);
            }
        }
        return path;
    }

    private static readonly string[] CheatPackageSignatures = new string[] {
        "meteordevelopment", "doomsdayclient", "org/chainlibs", "vape/loader",
        "cc/novoline", "xyz/greaj", "dev/virel", "dev/krypton", "dev/gambleclient",
        "catlean", "prestigeclient", "asteria/client", "com/matt/forgehax",
        "net/wurstclient", "me/ionar/salhack", "me/earth/phobos", "dev/tigr/ares",
        "com/lambda", "liquidbounce", "fdpclient", "novoware", "hellclient",
        "org.jnativehook.GlobalScreen", "org/jnativehook", "JNativeHook"
    };

    private static readonly string[] CheatConfigKeywords = new string[] {
        "\"killaura\":", "\"aimassist\":", "\"autocrystal\":", "\"triggerbot\":",
        "\"targethud\":", "\"clickgui\":", "\"pingspoof\":", "\"fakelag\":",
        "\"selfdestruct\":", "\"bhop\":", "\"flight\":", "\"speedhack\":",
        "\"scaffold\":", "\"fastplace\":", "\"reach\":", "\"noslow\":",
        "[Module] KillAura", "[Module] AutoCrystal", "[Module] AimAssist",
        "[Module] TriggerBot", "[Module] AutoTotem", "[Module] Velocity"
    };

    private static readonly string[] MixinHandlerSignatures = new string[] {
        "handler$", "mixin$", "@Overwrite", "@Redirect", "@Inject",
        "@ModifyArg", "@ModifyVariable", "@WrapOperation", "@ModifyConstant"
    };

    private static readonly string[] CheatGUISignatures = new string[] {
        "ClickGUI", "Watermark", "ArrayList", "TargetHUD", "ColorPicker",
        "ConfigManager", "HudEditor", "KeybindManager", "ModuleList", "CategoryPanel"
    };

    private static readonly string[] NetworkEndpointSignatures = new string[] {
        "api.novaclient.lol", "novoware.eu", "hellclient.eu", "vape.gg",
        "intent.store", "discord.com/api/webhooks/", "127.0.0.1:",
        "java/net/ServerSocket", "java/net/Socket", "io/netty/channel/local"
    };

    private static readonly string[] JvmInstrumentationSignatures = new string[] {
        "java/lang/instrument/Instrumentation", "java.lang.instrument.Instrumentation",
        "redefineClasses", "retransformClasses", "Attach Listener",
        "com/sun/tools/attach", "sun.tools.attach"
    };

    private static readonly string[] JNativeHookMemorySignatures = new string[] {
        "org.jnativehook.GlobalScreen", "org/jnativehook/GlobalScreen",
        "org/jnativehook/NativeHookException", "org/jnativehook/keyboard/NativeKeyEvent",
        "org/jnativehook/mouse/NativeMouseEvent", "JNativeHook"
    };

    public static MemoryScanReport ScanProcessComprehensive(int processId, string modsDir) {
        MemoryScanReport result = new MemoryScanReport();
        HashSet<string> seenJars = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        HashSet<string> seenCheats = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        HashSet<string> seenConfigs = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        HashSet<string> seenMixins = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        HashSet<string> seenGUI = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        HashSet<string> seenEndpoints = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        HashSet<string> seenInstr = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        HashSet<string> seenJNH = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        List<IntPtr> mappedImageBases = new List<IntPtr>();

        if (processId <= 0) return result;

        try {
            string tempDir = Path.GetTempPath();
            string attachFile = Path.Combine(tempDir, string.Format(".java_pid{0}", processId));
            if (File.Exists(attachFile)) {
                result.JvmAttachListenerActive = true;
                result.AttachSocketPath = attachFile;
            }
        } catch { }

        string normMods = string.IsNullOrEmpty(modsDir) ? "" : modsDir.Replace('/', '\\').TrimEnd('\\');
        string normModsFwd = string.IsNullOrEmpty(modsDir) ? "" : modsDir.Replace('\\', '/').TrimEnd('/');
        string escapedDir = string.IsNullOrEmpty(normMods) ? "" : Regex.Escape(normMods);
        string escapedDirFwd = string.IsNullOrEmpty(normModsFwd) ? "" : Regex.Escape(normModsFwd);

        Regex jarRegexWin = string.IsNullOrEmpty(escapedDir) ? null : new Regex(escapedDir + @"\[a-zA-Z0-9_\-\.\+\(\)\@\#\$\%\^\& ]+\.jar", RegexOptions.IgnoreCase | RegexOptions.Compiled);
        Regex jarRegexFwd = string.IsNullOrEmpty(escapedDirFwd) ? null : new Regex(escapedDirFwd + @"/[a-zA-Z0-9_\-\.\+\(\)\@\#\$\%\^\& ]+\.jar", RegexOptions.IgnoreCase | RegexOptions.Compiled);
        Regex jarRegexUri = string.IsNullOrEmpty(escapedDirFwd) ? null : new Regex(@"(?:file:/+|jar:file:/+)" + escapedDirFwd + @"/[a-zA-Z0-9_\-\.\+\(\)\@\#\$\%\^\& ]+\.jar", RegexOptions.IgnoreCase | RegexOptions.Compiled);

        IntPtr hProcess = OpenProcess(0x0410, false, processId);
        if (hProcess == IntPtr.Zero) return result;

        try {
            long maxAddr = 0x7FFFFFFF0000;
            long currentAddr = 0;
            byte[] buffer = new byte[131072];

            while (currentAddr < maxAddr) {
                MEMORY_BASIC_INFORMATION mbi;
                int res = VirtualQueryEx(hProcess, (IntPtr)currentAddr, out mbi, (uint)Marshal.SizeOf(typeof(MEMORY_BASIC_INFORMATION)));
                if (res == 0) break;

                long baseAddr = mbi.BaseAddress.ToInt64();
                long regionSize = mbi.RegionSize.ToInt64();

                if (mbi.Type == 0x40000 || mbi.Type == 0x1000000) {
                    if (mbi.Type == 0x1000000 && mbi.BaseAddress == mbi.AllocationBase) {
                        mappedImageBases.Add((IntPtr)baseAddr);
                    }
                    StringBuilder sb = new StringBuilder(1024);
                    if (GetMappedFileName(hProcess, (IntPtr)baseAddr, sb, (uint)sb.Capacity) > 0) {
                        string mappedPath = NormalizeDevicePath(sb.ToString());
                        if (mappedPath.EndsWith(".jar", StringComparison.OrdinalIgnoreCase)) {
                            if (!string.IsNullOrEmpty(normMods) && mappedPath.StartsWith(normMods, StringComparison.OrdinalIgnoreCase)) {
                                if (seenJars.Add(mappedPath)) {
                                    result.MappedJars.Add(mappedPath);
                                    result.DiscoveredJarPaths.Add(mappedPath);
                                }
                            }
                        }
                    }
                }

                if (mbi.State == 0x1000 && mbi.Type == 0x20000) {
                    if (mbi.Protect == 0x40) {
                        if (regionSize >= 65536) {
                            IntPtr bytesRead;
                            byte[] headBuf = new byte[512];
                            if (ReadProcessMemory(hProcess, (IntPtr)baseAddr, headBuf, 512, out bytesRead)) {
                                if (headBuf[0] == 0x4D && headBuf[1] == 0x5A) {
                                    result.InjectedPEHeaders.Add(string.Format("Unbacked Injected PE/DLL binary at 0x{0:X} ({1} KB, PAGE_EXECUTE_READWRITE)", baseAddr, regionSize / 1024));
                                } else {
                                    result.SuspiciousRWXRegions.Add(string.Format("Private RWX memory region at 0x{0:X} ({1} KB)", baseAddr, regionSize / 1024));
                                }
                            }
                        }
                    }
                }

                if (mbi.State == 0x1000 && (mbi.Type == 0x20000 || mbi.Type == 0x40000) && ((mbi.Protect & 0x04) != 0 || (mbi.Protect & 0x40) != 0) && regionSize > 0 && regionSize <= 33554432) {
                    long chunkOffset = 0;
                    while (chunkOffset < regionSize) {
                        int toRead = (int)Math.Min(buffer.Length, regionSize - chunkOffset);
                        IntPtr bytesRead;
                        if (ReadProcessMemory(hProcess, (IntPtr)(baseAddr + chunkOffset), buffer, toRead, out bytesRead)) {
                            int actualRead = bytesRead.ToInt32();
                            if (actualRead > 10) {
                                string textAscii = Encoding.ASCII.GetString(buffer, 0, actualRead);
                                if (jarRegexWin != null) ExtractMatches(textAscii, jarRegexWin, jarRegexFwd, jarRegexUri, seenJars, result.DiscoveredJarPaths);
                                CheckCheatSigs(textAscii, CheatPackageSignatures, seenCheats, result.GhostCheatSignatures);
                                CheckConfigs(textAscii, CheatConfigKeywords, seenConfigs, result.CheatConfigSnippets);
                                CheckCheatSigs(textAscii, MixinHandlerSignatures, seenMixins, result.GhostMixinHandlers);
                                CheckCheatSigs(textAscii, CheatGUISignatures, seenGUI, result.CheatGUIElements);
                                CheckCheatSigs(textAscii, NetworkEndpointSignatures, seenEndpoints, result.MemoryNetworkEndpoints);
                                CheckCheatSigs(textAscii, JvmInstrumentationSignatures, seenInstr, result.JvmInstrumentationTraces);
                                CheckCheatSigs(textAscii, JNativeHookMemorySignatures, seenJNH, result.JNativeHookTraces);

                                string textUnicode = Encoding.Unicode.GetString(buffer, 0, actualRead);
                                if (jarRegexWin != null) ExtractMatches(textUnicode, jarRegexWin, jarRegexFwd, jarRegexUri, seenJars, result.DiscoveredJarPaths);
                                CheckCheatSigs(textUnicode, CheatPackageSignatures, seenCheats, result.GhostCheatSignatures);
                                CheckConfigs(textUnicode, CheatConfigKeywords, seenConfigs, result.CheatConfigSnippets);
                                CheckCheatSigs(textUnicode, MixinHandlerSignatures, seenMixins, result.GhostMixinHandlers);
                                CheckCheatSigs(textUnicode, CheatGUISignatures, seenGUI, result.CheatGUIElements);
                                CheckCheatSigs(textUnicode, NetworkEndpointSignatures, seenEndpoints, result.MemoryNetworkEndpoints);
                                CheckCheatSigs(textUnicode, JvmInstrumentationSignatures, seenInstr, result.JvmInstrumentationTraces);
                                CheckCheatSigs(textUnicode, JNativeHookMemorySignatures, seenJNH, result.JNativeHookTraces);
                            }
                        }
                        chunkOffset += Math.Max(1, toRead - 512);
                    }
                }
                long nextAddr = baseAddr + regionSize;
                if (nextAddr <= currentAddr) break;
                currentAddr = nextAddr;
            }

            CheckUnlinkedModules(hProcess, mappedImageBases, result.UnlinkedModules);
        } catch { }
        finally {
            CloseHandle(hProcess);
        }

        CheckApiHooks(processId, result.HookedExports);

        foreach (string jarPath in result.DiscoveredJarPaths) {
            try {
                string diskPath = jarPath.Replace('/', '\\');
                if (diskPath.StartsWith("file:\\", StringComparison.OrdinalIgnoreCase)) diskPath = diskPath.Substring(6).TrimStart('\\');
                if (diskPath.StartsWith("jar:file:\\", StringComparison.OrdinalIgnoreCase)) diskPath = diskPath.Substring(10).TrimStart('\\');
                int bangIdx = diskPath.IndexOf('!');
                if (bangIdx > 0) diskPath = diskPath.Substring(0, bangIdx);

                if (!File.Exists(diskPath)) {
                    result.UnloadedMods.Add(diskPath);
                }
            } catch { }
        }

        return result;
    }

    private static void CheckUnlinkedModules(IntPtr hProcess, List<IntPtr> imageBases, List<string> unlinkedList) {
        try {
            uint cbNeeded;
            IntPtr[] mods = new IntPtr[1024];
            if (EnumProcessModules(hProcess, mods, (uint)(mods.Length * IntPtr.Size), out cbNeeded)) {
                int count = (int)(cbNeeded / (uint)IntPtr.Size);
                HashSet<IntPtr> knownMods = new HashSet<IntPtr>();
                for (int i = 0; i < count && i < mods.Length; i++) {
                    if (mods[i] != IntPtr.Zero) knownMods.Add(mods[i]);
                }
                for (int i = 0; i < imageBases.Count; i++) {
                    IntPtr baseAddr = imageBases[i];
                    if (!knownMods.Contains(baseAddr)) {
                        StringBuilder sb = new StringBuilder(1024);
                        if (GetMappedFileName(hProcess, baseAddr, sb, (uint)sb.Capacity) > 0) {
                            string mapped = NormalizeDevicePath(sb.ToString());
                            if (!string.IsNullOrEmpty(mapped) && mapped.EndsWith(".dll", StringComparison.OrdinalIgnoreCase)) {
                                unlinkedList.Add(string.Format("Unlinked / Hidden DLL module at 0x{0:X} ({1})", baseAddr.ToInt64(), Path.GetFileName(mapped)));
                            }
                        }
                    }
                }
            }
        } catch { }
    }

    private static void CheckSingleHook(IntPtr hProcess, string moduleName, string procName, string desc, List<string> hookedList) {
        try {
            IntPtr hMod = GetModuleHandle(moduleName);
            if (hMod != IntPtr.Zero) {
                IntPtr pProc = GetProcAddress(hMod, procName);
                if (pProc != IntPtr.Zero) {
                    byte[] head = new byte[8];
                    IntPtr read;
                    if (ReadProcessMemory(hProcess, pProc, head, 8, out read)) {
                        if (head[0] == 0xE9 || head[0] == 0xE8 || head[0] == 0xEB || (head[0] == 0xFF && head[1] == 0x25)) {
                            hookedList.Add(string.Format("{0}!{1} has inline detour/JMP hook ({2})", moduleName, procName, desc));
                        }
                    }
                }
            }
        } catch { }
    }

    private static void CheckApiHooks(int pid, List<string> hookedList) {
        try {
            IntPtr hProcess = OpenProcess(0x0010, false, pid);
            if (hProcess == IntPtr.Zero) return;
            try {
                CheckSingleHook(hProcess, "opengl32.dll", "wglSwapBuffers", "Render overlay hijack", hookedList);
                CheckSingleHook(hProcess, "glfw3.dll", "glfwSetKeyCallback", "Keyboard input interceptor", hookedList);
                CheckSingleHook(hProcess, "glfw3.dll", "glfwSetCursorPosCallback", "Mouse aimbot interceptor", hookedList);
                CheckSingleHook(hProcess, "glfw3.dll", "glfwSetMouseButtonCallback", "AutoClicker trigger interceptor", hookedList);
                CheckSingleHook(hProcess, "glfw.dll", "glfwSetKeyCallback", "Keyboard input interceptor", hookedList);
                CheckSingleHook(hProcess, "glfw.dll", "glfwSetCursorPosCallback", "Mouse aimbot interceptor", hookedList);
                CheckSingleHook(hProcess, "glfw.dll", "glfwSetMouseButtonCallback", "AutoClicker trigger interceptor", hookedList);
                CheckSingleHook(hProcess, "user32.dll", "SetCursorPos", "Direct cursor manipulation hook", hookedList);
                CheckSingleHook(hProcess, "user32.dll", "GetAsyncKeyState", "Global key state polling hook", hookedList);
            } finally {
                CloseHandle(hProcess);
            }
        } catch { }
    }

    private static void ExtractMatches(string text, Regex win, Regex fwd, Regex uri, HashSet<string> seen, List<string> outList) {
        foreach (Match m in win.Matches(text)) {
            string val = m.Value.Replace('/', '\\');
            if (seen.Add(val)) outList.Add(val);
        }
        foreach (Match m in fwd.Matches(text)) {
            string val = m.Value.Replace('/', '\\');
            if (seen.Add(val)) outList.Add(val);
        }
        foreach (Match m in uri.Matches(text)) {
            string raw = m.Value;
            string clean = Regex.Replace(raw, @"^(?:file:/+|jar:file:/+)", "");
            clean = clean.Replace("%20", " ").Replace('/', '\\');
            int bang = clean.IndexOf('!');
            if (bang > 0) clean = clean.Substring(0, bang);
            if (seen.Add(clean)) outList.Add(clean);
        }
    }

    private static void CheckCheatSigs(string text, string[] sigs, HashSet<string> seen, List<string> outList) {
        for (int i = 0; i < sigs.Length; i++) {
            if (text.Contains(sigs[i])) {
                if (seen.Add(sigs[i])) outList.Add(sigs[i]);
            }
        }
    }

    private static void CheckConfigs(string text, string[] keywords, HashSet<string> seen, List<string> outList) {
        for (int i = 0; i < keywords.Length; i++) {
            if (text.Contains(keywords[i])) {
                if (seen.Add(keywords[i])) outList.Add(keywords[i]);
            }
        }
    }

    public static void ScanEntryName(string entryName, HashSet<string> patterns, HashSet<string> macros) {
        if (string.IsNullOrEmpty(entryName)) return;
        string fn = entryName;
        int lastSlash = fn.LastIndexOf('/');
        if (lastSlash >= 0) fn = fn.Substring(lastSlash + 1);
        if (fn.EndsWith(".class")) fn = fn.Substring(0, fn.Length - 6);
        if (PatternSet.Contains(fn)) patterns.Add(fn);
        if (MacroSet.Contains(fn)) macros.Add(fn);
    }

    public static List<string> ParseConstantPool(byte[] raw) {
        int dummy = 0;
        return ParseConstantPoolEx(raw, out dummy);
    }

    public static List<string> ParseConstantPoolEx(byte[] raw, out int majorVersion) {
        List<string> result = new List<string>();
        majorVersion = 0;
        if (raw == null || raw.Length < 10) return result;
        if (raw[0] != 0xCA || raw[1] != 0xFE || raw[2] != 0xBA || raw[3] != 0xBE) return result;
        majorVersion = (raw[6] << 8) | raw[7];
        int cpCount = (raw[8] << 8) | raw[9];
        int pos = 10;
        for (int i = 1; i < cpCount && pos < raw.Length; i++) {
            byte tag = raw[pos++];
            switch (tag) {
                case 1:
                    if (pos + 1 >= raw.Length) return result;
                    int len = (raw[pos] << 8) | raw[pos + 1];
                    pos += 2;
                    if (len > 0 && pos + len <= raw.Length) {
                        try {
                            result.Add(Encoding.UTF8.GetString(raw, pos, len));
                        } catch { }
                    }
                    pos += len;
                    break;
                case 7: case 8: case 16: case 19: case 20: pos += 2; break;
                case 3: case 4: case 9: case 10: case 11: case 12: case 17: case 18: pos += 4; break;
                case 5: case 6: pos += 8; i++; break;
                case 15: pos += 3; break;
                default: return result;
            }
        }
        return result;
    }

    public static double CalcEntropy(byte[] data) {
        if (data == null || data.Length == 0) return 0.0;
        int[] freq = new int[256];
        for (int i = 0; i < data.Length; i++) freq[data[i]]++;
        double ent = 0.0;
        double len = (double)data.Length;
        for (int i = 0; i < 256; i++) {
            if (freq[i] > 0) {
                double p = (double)freq[i] / len;
                ent -= p * Math.Log(p, 2);
            }
        }
        return Math.Round(ent, 2);
    }

    public static void ScanClassComprehensive(
        byte[] raw,
        HashSet<string> patterns,
        HashSet<string> macros,
        HashSet<string> content,
        HashSet<string> fullwidth,
        HashSet<string> encodedHits,
        ref int reflectionScore,
        ref int highEntropyCount,
        Dictionary<string, bool> combinedHeuristics
    ) {
        if (raw == null || raw.Length < 10) return;
        if (raw.Length > 500) {
            double ent = CalcEntropy(raw);
            if (ent > 7.4) highEntropyCount++;
        }

        int dummy = 0;
        List<string> cp = ParseConstantPoolEx(raw, out dummy);
        if (cp.Count == 0) return;

        bool hasYawPitch=false,hasLookOnGround=false,hasSetYaw=false;
        bool hasDamageUtil=false,hasExplosion=false,hasVec3d=false;
        bool hasVelocityPacket=false,hasVelocityMutate=false;
        bool hasBlockHitResult=false,hasDirectionValues=false;
        bool hasNettyHandler=false,hasGLFWSetKey=false;
        bool hasCooldownField=false;
        bool hasBoxExpand=false,hasReachCheck=false;
        bool hasRandomCPS=false,hasMouseDispatch=false;
        bool hasCrosshairTarget=false,hasDoAttack=false;
        bool hasTotemItem=false,hasSlotSwap=false;
        bool hasActionPackets=false,hasOnGroundSpoof=false;
        bool hasPacketQueue=false,hasPotItem=false;
        bool hasTrackedPos=false,hasWebhook=false,hasUnsafeMem=false;
        bool hasDeleteCommand=false,hasDeleteOnExit=false,hasShutdownHook=false;
        bool hasFreeLook=false,hasAutoWeb=false,hasAutoMace=false;
        bool hasCriticalsDesync=false,hasFastBow=false,hasSpinBot=false;
        bool hasAnchorItem=false,hasGlowstoneItem=false,hasInteractBlock=false;
        bool hasEntityRenderer=false,hasBoxMutation=false;
        bool hasSurroundOffset=false,hasObsidianBlock=false;
        bool hasArmorEval=false,hasArmorSlot=false;
        bool hasHealthCheck=false,hasGappleItem=false;
        bool hasZeroMultiply=false,hasElytraContext=false,hasFallDistance=false;
        bool hasClimbable=false,hasStepValue=false,hasVehicleContext=false;
        bool hasUsingItem=false,hasSpeedOverride=false,hasTrigMath=false;
        bool hasOrbitParam=false,hasCollisionMethod=false,hasAirBelow=false;
        bool hasScreenPacket=false,hasCancelAction=false,hasBlockOcclusion=false;
        bool hasRenderOverride=false,hasTotemSlotSwap=false,hasStatusEffects=false;
        bool hasNegativeEffect=false,hasBowItem=false,hasBowCharge=false;
        bool hasRandomModule=false,hasYawPitchAngle=false;

        for (int i = 0; i < cp.Count; i++) {
            string s = cp[i];
            if (string.IsNullOrEmpty(s)) continue;

            if (PatternSet.Contains(s)) patterns.Add(s);
            if (MacroSet.Contains(s)) macros.Add(s);
            if (ContentSet.Contains(s)) content.Add(s);
            if (ReflectionSet.Contains(s)) reflectionScore += 5;

            MatchCollection fwm = FullwidthRegex.Matches(s);
            for (int m = 0; m < fwm.Count; m++) fullwidth.Add(fwm[m].Value);

            if (s.Length >= 24 && s.Length <= 512 && Base64Regex.IsMatch(s)) {
                try {
                    byte[] dec = Convert.FromBase64String(s);
                    if (dec.Length >= 8) {
                        string decStr = Encoding.UTF8.GetString(dec);
                        if (PatternSet.Contains(decStr) || ContentSet.Contains(decStr)) {
                            encodedHits.Add(decStr);
                        }
                    }
                } catch { }
            }

            if (s.Contains("PlayerMoveC2SPacket$LookAndOnGround") || s.Contains("class_2830")) hasLookOnGround = true;
            if (s.Contains("setYaw") || s.Contains("method_36456") || s.Contains("changeLookDirection")) hasSetYaw = true;
            if (s.Contains("DamageUtil") || s.Contains("getDamageLeft") || s.Contains("class_3584")) hasDamageUtil = true;
            if (s.Contains("Explosion") || s.Contains("class_1927") || s.Contains("createExplosion")) hasExplosion = true;
            if (s.Contains("Vec3d") || s.Contains("class_243") || s.Contains("squaredDistanceTo")) hasVec3d = true;
            if (s.Contains("EntityVelocityUpdateS2CPacket") || s.Contains("class_2743") || s.Contains("ExplosionS2CPacket")) hasVelocityPacket = true;
            if (s.Contains("setVelocity") || s.Contains("method_18799") || s.Contains("field_1350") || s.Contains("field_1351") || s.Contains("field_1352")) hasVelocityMutate = true;
            if (s.Contains("BlockHitResult") || s.Contains("class_3965") || s.Contains("getSide")) hasBlockHitResult = true;
            if (s.Contains("Direction.values") || s.Contains("field_11033") || s.Contains("class_2350")) hasDirectionValues = true;
            if (s.Contains("ChannelDuplexHandler") || s.Contains("channelRead") || s.Contains("write(Lio/netty/channel/ChannelHandlerContext")) hasNettyHandler = true;
            if (s.Contains("glfwSetKeyCallback") || s.Contains("glfwSetMouseButtonCallback") || s.Contains("glfwSetCursorPosCallback")) hasGLFWSetKey = true;
            if (s.Contains("itemUseCooldown") || s.Contains("field_3756") || s.Contains("blockBreakingCooldown") || s.Contains("field_3755")) hasCooldownField = true;
            if (s.Contains("expand") || s.Contains("method_1009") || s.Contains("method_1012") || s.Contains("stretch")) hasBoxExpand = true;
            if (s.Contains("getExtendedReach") || s.Contains("getSquaredDistance") || s.Contains("getReachDistance") || s.Contains("getTargetingMargin")) hasReachCheck = true;
            if (s.Contains("nextGaussian") || s.Contains("ThreadLocalRandom") || s.Contains("getCpsRandom")) hasRandomCPS = true;
            if (s.Contains("onMouseButton") || s.Contains("method_1607") || s.Contains("invokeDoAttack") || s.Contains("invokeDoItemUse")) hasMouseDispatch = true;
            if (s.Contains("crosshairTarget") || s.Contains("field_1765") || s.Contains("targetedEntity") || s.Contains("field_1692")) hasCrosshairTarget = true;
            if (s.Contains("doAttack") || s.Contains("method_1536") || s.Contains("attackEntity") || s.Contains("method_2918")) hasDoAttack = true;
            if (s.Contains("TOTEM_OF_UNDYING") || s.Contains("field_8288") || s.Contains("Items.field_8288")) hasTotemItem = true;
            if (s.Contains("quickMove") || s.Contains("method_2906") || s.Contains("pickItem") || s.Contains("method_7335")) hasSlotSwap = true;
            if (s.Contains("PlayerActionC2SPacket") || s.Contains("class_2846") || s.Contains("START_DESTROY_BLOCK")) hasActionPackets = true;
            if (s.Contains("onGround") || s.Contains("field_15467") || s.Contains("setOnGround")) hasOnGroundSpoof = true;
            if (s.Contains("ConcurrentLinkedQueue") || s.Contains("ArrayDeque") || s.Contains("packetQueue")) hasPacketQueue = true;
            if (s.Contains("SPLASH_POTION") || s.Contains("LINGERING_POTION") || s.Contains("field_8436")) hasPotItem = true;
            if (s.Contains("prevX") || s.Contains("prevY") || s.Contains("prevZ") || s.Contains("lastRenderX")) hasTrackedPos = true;
            if (s.Contains("api.novaclient.lol") || s.Contains("discord.com/api/webhooks") || s.Contains("webhook.txt")) hasWebhook = true;
            if (s.Contains("sun/misc/Unsafe") || s.Contains("allocateMemory") || s.Contains("putAddress") || s.Contains("defineAnonymousClass")) hasUnsafeMem = true;
            if (s.Contains("cmd.exe /c timeout & del") || s.Contains("cmd /c del") || s.Contains("cmd.exe /c ping 127.0.0.1 & del")) hasDeleteCommand = true;
            if (s.Contains("deleteOnExit") || s.Contains("java/io/File.deleteOnExit")) hasDeleteOnExit = true;
            if (s.Contains("addShutdownHook") || s.Contains("Runtime.getRuntime().addShutdownHook")) hasShutdownHook = true;
            if (s.Contains("Camera") || s.Contains("class_4184") || s.Contains("setRotation") || s.Contains("thirdPerson")) hasFreeLook = true;
            if (s.Contains("COBWEB") || s.Contains("field_10343") || s.Contains("Blocks.field_10343")) hasAutoWeb = true;
            if (s.Contains("MACE") || s.Contains("MaceItem") || s.Contains("heavy_core") || s.Contains("wind_burst")) hasAutoMace = true;
            if (s.Contains("fallDistance") || s.Contains("field_6017") || s.Contains("isFalling")) hasFallDistance = true;
            if (s.Contains("PlayerMoveC2SPacket$PositionAndOnGround") || s.Contains("class_2829")) hasCriticalsDesync = true;
            if (s.Contains("RESPAWN_ANCHOR") || s.Contains("field_23151") || s.Contains("Blocks.field_23151")) hasAnchorItem = true;
            if (s.Contains("GLOWSTONE") || s.Contains("field_10540") || s.Contains("Blocks.field_10540")) hasGlowstoneItem = true;
            if (s.Contains("interactBlock") || s.Contains("method_2896") || s.Contains("processRightClickBlock")) hasInteractBlock = true;
            if (s.Contains("LivingEntityRenderer") || s.Contains("class_922") || s.Contains("getRenderType")) hasEntityRenderer = true;
            if (s.Contains("setBoundingBox") || s.Contains("method_5857") || s.Contains("boundingBox")) hasBoxMutation = true;
            if (s.Contains("OBSIDIAN") || s.Contains("field_10542") || s.Contains("Blocks.field_10542")) hasObsidianBlock = true;
            if (s.Contains("OFFSETS") || s.Contains("SURROUND") || s.Contains("HOLE_OFFSETS") || s.Contains("SURROUND_OFFSETS")) hasSurroundOffset = true;
            if (s.Contains("ArmorItem") || s.Contains("class_1738") || s.Contains("getProtection")) hasArmorEval = true;
            if (s.Contains("getStack") || s.Contains("armorInventory") || s.Contains("EquipmentSlot")) hasArmorSlot = true;
            if (s.Contains("getHealth") || s.Contains("method_6032") || s.Contains("getAbsorptionAmount")) hasHealthCheck = true;
            if (s.Contains("ENCHANTED_GOLDEN_APPLE") || s.Contains("GOLDEN_APPLE") || s.Contains("field_8367")) hasGappleItem = true;
            if (s.Contains("multiply") || s.Contains("horizontalFactor") || s.Contains("verticalFactor") || s.Contains("hRatio") || s.Contains("vRatio")) hasZeroMultiply = true;
            if (s.Contains("elytra") || s.Contains("ELYTRA") || s.Contains("field_7769") || s.Contains("isFallFlying")) hasElytraContext = true;
            if (s.Contains("isClimbing") || s.Contains("LADDER") || s.Contains("VINE") || s.Contains("SCAFFOLDING")) hasClimbable = true;
            if (s.Contains("stepHeight") || s.Contains("maxUpStep")) hasStepValue = true;
            if (s.Contains("hasVehicle") || s.Contains("getRootVehicle") || s.Contains("BoatEntity") || s.Contains("MinecartEntity") || s.Contains("HorseEntity")) hasVehicleContext = true;
            if (s.Contains("isUsingItem") || s.Contains("getItemUseSlowdown")) hasUsingItem = true;
            if (s.Contains("setMovementSpeed") || s.Contains("movementInput") || s.Contains("slowdownMultiplier")) hasSpeedOverride = true;
            if (s.Contains("Math.cos") || s.Contains("Math.sin") || s.Contains("StrictMath.cos")) hasTrigMath = true;
            if (s.Contains("strafe") || s.Contains("orbit") || s.Contains("circleSpeed")) hasOrbitParam = true;
            if (s.Contains("adjustMovementForCollisions") || s.Contains("clipAtLedge")) hasCollisionMethod = true;
            if (s.Contains("isAir") || s.Contains("world.isAir") || s.Contains("isReplaceable")) hasAirBelow = true;
            if (s.Contains("CloseHandledScreenC2SPacket") || s.Contains("OpenScreenS2CPacket")) hasScreenPacket = true;
            if (s.Contains("ci.cancel") || s.Contains("CallbackInfo") || s.Contains("cancel")) hasCancelAction = true;
            if (s.Contains("shouldDrawSide") || s.Contains("getRenderType") || s.Contains("isOpaqueFullCube") || s.Contains("isSideInvisible")) hasBlockOcclusion = true;
            if (s.Contains("INVISIBLE") || s.Contains("CUTOUT") || s.Contains("TRANSLUCENT") || s.Contains("ci.setReturnValue")) hasRenderOverride = true;
            if (s.Contains("SlotActionType.SWAP") && s.Contains("clickSlot")) hasTotemSlotSwap = true;
            if (s.Contains("StatusEffectInstance") || s.Contains("StatusEffects")) hasStatusEffects = true;
            if (s.Contains("BLINDNESS") || s.Contains("DARKNESS") || s.Contains("NAUSEA") || s.Contains("LEVITATION") || s.Contains("MINING_FATIGUE")) hasNegativeEffect = true;
            if (s.Contains("BOW") || s.Contains("field_8255") || s.Contains("BowItem")) hasBowItem = true;
            if (s.Contains("useTicks") || s.Contains("getMaxUseTime") || s.Contains("chargeTime")) hasBowCharge = true;
            if (s.Contains("Random") || s.Contains("Math.random")) hasRandomModule = true;
            if (s.Contains("yaw") || s.Contains("pitch") || s.Contains("headYaw")) hasYawPitchAngle = true;
        }

        if (hasYawPitch && hasLookOnGround && hasSetYaw) combinedHeuristics["SilentAim"] = true;
        if (hasDamageUtil && hasExplosion && hasVec3d) combinedHeuristics["CrystalMath"] = true;
        if (hasVelocityPacket && hasVelocityMutate) combinedHeuristics["VelocitySpoof"] = true;
        if (hasBlockHitResult && hasDirectionValues) combinedHeuristics["ScaffoldMath"] = true;
        if (hasNettyHandler) combinedHeuristics["NettyIntercept"] = true;
        if (hasGLFWSetKey) combinedHeuristics["GLFWInputHook"] = true;
        if (hasCooldownField) combinedHeuristics["CooldownMod"] = true;
        if (hasBoxExpand && hasReachCheck) combinedHeuristics["ReachHitbox"] = true;
        if (hasRandomCPS && hasMouseDispatch) combinedHeuristics["AutoClicker"] = true;
        if (hasCrosshairTarget && hasDoAttack && !hasRandomCPS) combinedHeuristics["TriggerBot"] = true;
        if (hasTotemItem && hasSlotSwap) combinedHeuristics["AutoTotem"] = true;
        if (hasCooldownField) combinedHeuristics["FastPlace"] = true;
        if (hasActionPackets) combinedHeuristics["PacketMine"] = true;
        if (hasOnGroundSpoof) combinedHeuristics["NoFall"] = true;
        if (hasPacketQueue) combinedHeuristics["Blink"] = true;
        if (hasPotItem) combinedHeuristics["AutoPot"] = true;
        if (hasTrackedPos) combinedHeuristics["Backtrack"] = true;
        if (hasWebhook) combinedHeuristics["WebhookExfil"] = true;
        if (hasUnsafeMem) combinedHeuristics["MemoryScrub"] = true;
        if (hasDeleteCommand) combinedHeuristics["SelfDestruct_Cmd"] = true;
        if (hasDeleteOnExit) combinedHeuristics["SelfDestruct_Exit"] = true;
        if (hasShutdownHook) combinedHeuristics["SelfDestruct_Hook"] = true;
        if (hasFreeLook) combinedHeuristics["FreeLook"] = true;
        if (hasAutoWeb) combinedHeuristics["AutoWeb"] = true;
        if (hasAutoMace) combinedHeuristics["AutoMace"] = true;
        if (hasCriticalsDesync) combinedHeuristics["CriticalsDesync"] = true;
        if (hasFastBow) combinedHeuristics["FastBow"] = true;
        if (hasSpinBot) combinedHeuristics["SpinBot"] = true;
        if (hasAnchorItem && hasGlowstoneItem && hasInteractBlock) combinedHeuristics["AutoAnchor"] = true;
        if (hasEntityRenderer && hasBoxMutation && hasBoxExpand) combinedHeuristics["HitboxOverride"] = true;
        if (hasSurroundOffset && hasObsidianBlock && hasInteractBlock) combinedHeuristics["AutoSurround"] = true;
        if (hasObsidianBlock && hasActionPackets && hasSurroundOffset) combinedHeuristics["AutoCity"] = true;
        if (hasArmorEval && hasArmorSlot) combinedHeuristics["AutoArmor"] = true;
        if (hasHealthCheck && hasGappleItem) combinedHeuristics["AutoEat"] = true;
        if (hasVelocityPacket && hasZeroMultiply) combinedHeuristics["AntiKB"] = true;
        if (hasElytraContext && hasYawPitch && hasFallDistance) combinedHeuristics["ElytraFly"] = true;
        if (hasClimbable && hasStepValue) combinedHeuristics["FastLadder"] = true;
        if (hasVehicleContext && hasYawPitch && hasFallDistance) combinedHeuristics["BoatFly"] = true;
        if (hasUsingItem && hasSpeedOverride) combinedHeuristics["NoSlowdown"] = true;
        if (hasTrigMath && hasOrbitParam) combinedHeuristics["TargetStrafe"] = true;
        if (hasCollisionMethod && hasAirBelow) combinedHeuristics["SafeWalk"] = true;
        if (hasScreenPacket && hasCancelAction) combinedHeuristics["FakeInvScreen"] = true;
        if (hasBlockOcclusion && hasRenderOverride) combinedHeuristics["XRay"] = true;
        if (hasTotemSlotSwap && hasTotemItem) combinedHeuristics["AutoTotemDesync"] = true;
        if (hasStatusEffects && hasNegativeEffect) combinedHeuristics["AntiBlindness"] = true;
        if (hasBowItem && hasBowCharge) combinedHeuristics["FastBowTruncated"] = true;
        if (hasRandomModule && hasYawPitchAngle && hasLookOnGround) combinedHeuristics["AntiAimRandom"] = true;
    }

    public static string[] CheckZipIntegrity(string filePath) {
        List<string> anomalies = new List<string>();
        if (!File.Exists(filePath)) return anomalies.ToArray();
        try {
            FileInfo fi = new FileInfo(filePath);
            long fileLength = fi.Length;
            if (fileLength < 22) return anomalies.ToArray();

            using (FileStream fs = new FileStream(filePath, FileMode.Open, FileAccess.Read, FileShare.Read)) {
                byte[] buffer = new byte[Math.Min(fileLength, 65536)];
                fs.Seek(Math.Max(0, fileLength - buffer.Length), SeekOrigin.Begin);
                int read = fs.Read(buffer, 0, buffer.Length);

                int eocdOffset = -1;
                for (int i = read - 22; i >= 0; i--) {
                    if (buffer[i] == 0x50 && buffer[i+1] == 0x4B && buffer[i+2] == 0x05 && buffer[i+3] == 0x06) {
                        eocdOffset = i;
                        break;
                    }
                }

                if (eocdOffset >= 0) {
                    long absoluteEocd = (fileLength - read) + eocdOffset;
                    int commentLength = buffer[eocdOffset + 20] | (buffer[eocdOffset + 21] << 8);
                    long expectedEnd = absoluteEocd + 22 + commentLength;
                    if (fileLength > expectedEnd) {
                        long trailingBytes = fileLength - expectedEnd;
                        anomalies.Add(string.Format("Hidden trailing overlay data: {0} bytes appended after ZIP End-of-Central-Directory", trailingBytes));
                    }

                    uint cdOffset = (uint)(buffer[eocdOffset + 16] | (buffer[eocdOffset + 17] << 8) | (buffer[eocdOffset + 18] << 16) | (buffer[eocdOffset + 19] << 24));
                    if (cdOffset > fileLength) {
                        anomalies.Add("Corrupt ZIP Central Directory pointer points beyond file boundary");
                    }
                }
            }
        } catch { }
        return anomalies.ToArray();
    }
}

public static class CurseForgeHasher {
    public static long ComputeHash(string filePath) {
        try {
            byte[] raw = File.ReadAllBytes(filePath);
            using (var ms = new MemoryStream()) {
                foreach (byte b in raw) {
                    if (b != 9 && b != 10 && b != 13 && b != 32) ms.WriteByte(b);
                }
                byte[] data = ms.ToArray();
                return MurmurHash2(data, data.Length, 1);
            }
        } catch { return 0; }
    }
    private static long MurmurHash2(byte[] data, int length, uint seed) {
        uint m = 0x5bd1e995;
        int r = 24;
        uint h = seed ^ (uint)length;
        int i = 0;
        while (length >= 4) {
            uint k = (uint)(data[i] | (data[i+1] << 8) | (data[i+2] << 16) | (data[i+3] << 24));
            k *= m; k ^= k >> r; k *= m;
            h *= m; h ^= k;
            i += 4; length -= 4;
        }
        switch (length) {
            case 3: h ^= (uint)data[i+2] << 16; goto case 2;
            case 2: h ^= (uint)data[i+1] << 8; goto case 1;
            case 1: h ^= data[i]; h *= m; break;
        }
        h ^= h >> 13; h *= m; h ^= h >> 15;
        return h;
    }
}
'@
Add-Type -TypeDefinition $fastScannerSource


function Show-Divider {
    param([string]$Char = "─", [int]$Width = 77, [ConsoleColor]$Color = "DarkCyan")
    Write-Host ($Char * $Width) -ForegroundColor $Color
}

function Measure-Entropy {
    param([byte[]]$Data)
    return [FastScanner]::CalcEntropy($Data)
}

function Get-FileDigest {
    param([string]$Target)
    $sha1 = (Get-FileHash -Path $Target -Algorithm SHA1).Hash
    $sha256 = (Get-FileHash -Path $Target -Algorithm SHA256).Hash
    $sha512 = (Get-FileHash -Path $Target -Algorithm SHA512).Hash
    $cf = [CurseForgeHasher]::ComputeHash($Target)
    return @{
        SHA1    = $sha1
        SHA256  = $sha256
        SHA512  = $sha512
        Murmur2 = $cf
    }
}

$script:reflectionIndicators = @(
    "java/lang/reflect/Method", "java/lang/reflect/Field",
    "java/lang/reflect/Constructor", "setAccessible",
    "getDeclaredMethod", "getDeclaredField", "getDeclaredConstructor",
    "java/lang/ClassLoader", "defineClass", "loadClass",
    "URLClassLoader", "java/lang/invoke/MethodHandles",
    "java/lang/invoke/MethodHandle", "java.lang.instrument",
    "java/lang/ProcessBuilder", "java/lang/Runtime",
    "forName", "newInstance", "getMethod", "invoke",
    "java/lang/reflect/Proxy", "InvocationHandler",
    "retransformClasses", "redefineClasses",
    "invokedynamic", "BootstrapMethods",
    "java/lang/instrument/Instrumentation", "premain", "agentmain",
    "sun/misc/Unsafe", "putAddress", "allocateMemory", "freeMemory", "getUnsafe",
    "jdk/internal/misc/Unsafe", "java/lang/invoke/LambdaMetafactory"
)

$script:cheatDomains = @(
    "novoware.eu", "hellclient.eu",
    "doomsdayclient.com", "prestigeclient.vip", "vape.gg", "intent.store",
    "riseclient.com", "astolfo.club", "dqrkis.xyz", "198macros.com",
    "novaclient.lol", "speckey.shop", "thevaultofficial.vercel.app",
    "catbox.moe", "pixeldrain.com", "anonfiles.com", "gofile.io",
    "file.io", "transfer.sh", "rentry.co", "paste.ee", "hastebin.com",
    "ghostbin.co", "0x0.st", "uploadfiles.io", "bayfiles.com", "letsupload.io",
    "teknik.io", "uguu.se", "tmpfiles.org", "filechan.org", "put.re",
    "send.vis.ee", "x0.at", "discord.com/api/webhooks/", "api.novaclient.lol",
    "pastebin.com/raw/", "liquidbounce.net", "fdpclient.cn", "aristois.net",
    "rusherhack.org", "futureclient.net", "konasclient.com", "sigma-client.com",
    "tenacity.dev", "moonclient.xyz", "augustusclient.com", "azuraclient.xyz",
    "entropy.club", "drip.gg", "slinky.gg", "haruclient.com", "antic.rip",
    "opai.club", "22qqclient.com", "pandaware.vip", "skilledclient.xyz",
    "impactclient.net", "wurstclient.net", "bleachhack.org",
    "mathaxclient.xyz", "meteorhack.com", "thunderhack.net"
)

$script:flaggedIdentifiers = @(
    "AimAssist", "AnchorTweaks", "AutoAnchor", "AutoCrystal", "AutoDoubleHand",
    "AutoHitCrystal", "AutoPot", "AutoTotem", "AutoArmor", "InventoryTotem", "LegitTotem",
    "PingSpoof", "SelfDestruct", "ShieldBreaker", "TriggerBot", "AxeSpam",
    "FastPlace", "WalskyOptimizer", "WalksyOptimizer", "walsky.optimizer", "WalksyCrystalOptimizerMod",
    "ShieldDisabler", "SilentAim", "Totem Hit", "Wtap", "FakeLag",
    "dev.virel", "orchard", "BlockESP", "dev.krypton", "dev/krypton", "skid.krypton", "skid/krypton",
    "AntiMissClick", "LagReach", "PopSwitch", "SprintReset", "ChestSteal", "AntiBot",
    "ElytraSwap", "AirAnchor", "jnativehook",
    "FakeInv", "HoverTotem", "AutoClicker", "AutoFirework", "PackSpoof", "Antiknockback", "catlean",
    "AuthBypass", "Asteria", "Prestige", "AutoEat", "AutoMine", "MaceSwap",
    "StunSlam", "SafeAnchor", "DoubleAnchor", "AutoTPA", "BaseFinder", "Xenon", "gypsy",
    "AutoPotRefill", "KeyPearl", "AutoNethPot", "AutoDtap", "AnchorAction",
    "org.chainlibs.module.impl.modules.Crystal.Y", "org.chainlibs.module.impl.modules.Crystal.bF",
    "org.chainlibs.module.impl.modules.Crystal.bM", "org.chainlibs.module.impl.modules.Crystal.bY",
    "org.chainlibs.module.impl.modules.Crystal.bq", "org.chainlibs.module.impl.modules.Crystal.cv",
    "org.chainlibs.module.impl.modules.Crystal.o", "org.chainlibs.module.impl.modules.Blatant.I",
    "org.chainlibs.module.impl.modules.Blatant.bR", "org.chainlibs.module.impl.modules.Blatant.bx",
    "org.chainlibs.module.impl.modules.Blatant.cj", "org.chainlibs.module.impl.modules.Blatant.dk",
    "imgui.gl3", "imgui.glfw", "BowAim", "Criticals", "Fakenick", "FakeItem",
    "invsee", "ItemExploit", "Hellion", "hellion", "LicenseCheckMixin",
    "ClientPlayerInteractionManagerAccessor", "ClientPlayerEntityMixim",
    "dev.gambleclient", "obfuscatedAuth", "phantom-refmap.json", "xyz.greaj",
    "SmartCrit", "AutoBlock", "ComboMode", "TargetPriority", "NoSwingDelay",
    "AutoWeaponSwitch", "CritHelper", "SprintHit", "AutoCombo", "SwingRange",
    "AutoShield", "ShieldSwitch", "AxeSwitch", "SwordBlock", "AutoGapple",
    "GappleSwap", "TotemPopListener", "PopCounter", "SmartTotem",
    "OffhandManager", "SlotSwapper", "CrystalPredict",
    "CrystalOptimize", "AnchorCalc", "DamageCalc", "PlacementHelper",
    "BreakHelper", "MultiPlace", "SpeedPlace",
    "ElytraBoost", "RocketBoost", "LongJump", "HighJump", "AirStuck",
    "VClip", "HClip", "FakeTP", "TeleportExploit", "SpeedMine",
    "FastEat", "NoSlowdown", "AntiVoid", "EntitySpeed", "BoatSpeed",
    "AirWalk", "TimerExploit", "Chams", "GlowESP",
    "HealthDisplay", "ArmorDisplay", "PotionDisplay", "TotemDisplay",
    "NoWeather", "NoFog", "CameraClip", "FreeLook", "ClickGUI",
    "HudEditor", "TargetHUD", "SequenceSpoof", "PositionSpoof", "RotationSpoof",
    "GroundSpoof", "VelocityCancel", "VelocityModify", "KBModifier",
    "NoRotate", "AntiAim", "Desync", "ServerCrasher",
    "BypassManager", "FlagDetector", "AntiCheatDetect", "BrandSpoof", "ChannelSpoof",
    "CWHack", "CW-Hack", "PlatiniumClient", "OnyxClient", "PuggerClient",
    "Francium", "FranciumClient", "Pugware", "PugwareClient",
    "VirginsPremium", "GrandlineVirgin", "Grandline-Virgin-V2",
    "XenomClient", "AspirahArgoon", "Aspirah-Ar-Goon",
    "MeraPrivateClient", "MeraClient", "ScrimsClient", "ZorimClient", "VoltClient", "Volt-V2",
    "VrilClient", "OsmiunClient", "ZenithClient", "LVClient",
    "LucidArgoon", "Lucid-Argoon", "SystemClient", "CymerClient",
    "3Q1PotClient", "3Q1Pot", "3qi-pot", "GardeniaClient", "SakurwaClient",
    "SilkClient", "ZoomiesClient", "NiggaHackClient", "NiggaHack",
    "NyrexClient", "RemnantClient", "4EClient", "4E-Client",
    "AchillesClient", "Achilles", "MistClient",
    "Novoware", "NovowareClient", "novoware", "novowareclient", "novoware.eu",
    "HellClient", "hellclient", "Hell-Client", "HellClientV2", "hellclient.eu",
    "OpaiClient", "Opai", "22qqClient", "22qq",
    "RavenB+", "RavenB3", "RavenB2", "RavenB1", "RavenNPlus", "RavenBS",
    "RavenXD", "RavenWeave", "RavenM+", "RavenK+", "RavenFX", "RavenApex",
    "RavenPlus", "RavenCommunity", "RavenEX", "RavenCarbon", "RavenNext",
    "RavenReborn", "RavenCE", "RavenFabric", "RavenLite", "raven-b-plus", "raven-b3",
    "Kura", "KuraClient", "Sunset", "SunsetClient", "Exos", "ExosClient",
    "Pulsar", "PulsarClient", "Cosmic", "CosmicClient", "Itami", "ItamiClient",
    "Lowkey", "LowkeyClient", "Whiteout", "WhiteoutClient",
    "BreezeClient", "breezeclient", "CaneClient", "CaneMod",
    "Mango", "MangoClient", "Teaspoon", "TeaspoonClient",
    "Coil", "CoilClient", "Tuke", "TukeClient",
    "Yukawa", "YukawaClient", "Kurium", "KuriumClient",
    "LWFH", "Greaj", "pw.cinque", "PW Cinque",
    "HCSCRCrystalOptimizer", "HCSCR", "CrystalOptimizerHitsOnly",
    "FlashCrystalOptimizer", "HerosAnchorOptimizer",
    "ClientSidedCrystals",
    "GrimBypass", "VulcanBypass", "MatrixBypass", "AACBypass",
    "VerusDisabler", "IntaveBypass", "WatchdogBypass", "SpartanBypass",
    "KarhuBypass", "PolarBypass", "GrimDisabler",
    "GrimVelocity", "GrimSpeed", "GrimFly", "GrimScaffold", "GrimKillAura",
    "GrimStep", "GrimNoFall", "GrimSprint", "GrimTimer", "GrimPhase",
    "GrimCombat", "GrimRaycastSpoof", "GrimPostCycle", "GrimTransactionSpoof",
    "GrimPingSpoof", "GrimCancelTransaction", "GrimReach", "GrimStrafe",
    "GrimAutoBlock", "GrimElytra", "GrimBoatFly",
    "VulcanFly", "VulcanSpeed", "VulcanKillAura", "VulcanScaffold", "VulcanDisabler",
    "VulcanStep", "VulcanNoFall", "VulcanTimer", "VulcanPhase", "VulcanVelocity",
    "VulcanCombat", "VulcanFastClimb", "VulcanGlide", "VulcanAirStuck",
    "VulcanAutoBlock", "VulcanReachBypass", "VulcanStrafe", "VulcanElytra",
    "MatrixSpeed", "MatrixFly", "MatrixKillAura", "MatrixScaffold", "MatrixDisabler",
    "MatrixPhase", "MatrixStep", "MatrixNoSlow", "MatrixRaycast", "MatrixTimer",
    "MatrixElytraFly", "MatrixBoatFly", "MatrixVelocity", "MatrixCombat",
    "PolarDisabler", "PolarFly", "PolarSpeed", "PolarKillAura", "PolarScaffold",
    "PolarStep", "PolarVelocity", "PolarTimer", "PolarPhase", "PolarNoFall", "PolarCombat",
    "KarhuSpeed", "KarhuFly", "KarhuKillAura", "KarhuScaffold", "KarhuDisabler",
    "KarhuStep", "KarhuVelocity", "KarhuTimer", "KarhuPhase", "KarhuNoFall",
    "IntaveFly", "IntaveSpeed", "IntaveKillAura", "IntaveScaffold", "IntaveDisabler",
    "IntaveStep", "IntaveVelocity", "IntaveTimer", "IntaveNoFall", "IntaveCombat",
    "VerusFly", "VerusSpeed", "VerusCombat", "VerusScaffold", "VerusDisabler",
    "VerusStep", "VerusVelocity", "VerusTimer", "VerusNoFall", "VerusGlide",
    "WatchdogFly", "WatchdogSpeed", "WatchdogKillAura", "WatchdogScaffold", "WatchdogDisabler",
    "WatchdogStep", "WatchdogVelocity", "WatchdogTimer", "WatchdogNoFall",
    "SpartanFly", "SpartanSpeed", "SpartanKillAura", "SpartanScaffold", "SpartanDisabler",
    "SpartanStep", "SpartanVelocity", "SpartanTimer", "SpartanNoFall",
    "AACFly", "AACSpeed", "AACKillAura", "AACScaffold", "AACDisabler",
    "AACStep", "AACVelocity", "AACTimer", "AACNoFall", "AACPhase",
    "NCPSpeed", "NCPFly", "NCPKillAura", "NCPScaffold", "NCPDisabler",
    "NCPStep", "NCPVelocity", "NCPTimer", "NCPNoFall", "NCPLongJump",
    "WurstClient", "net.wurstclient", "LambdaClient", "com.lambda",
    "SalHack", "me.ionar.salhack", "PhobosClient", "me.earth.phobos",
    "AresClient", "dev.tigr.ares", "HuzuniClient", "JigsawClient",
    "WolframClient", "ForgeHax", "com.matt.forgehax",
    "meteordevelopment", "meteorclient", "MeteorClient", "meteor-client",
    "meteordevelopment.meteorclient", "meteordevelopment/orbit",
    "BleachHack", "bleachhack", "org.bleachhack", "BleachHackMod",
    "Mathax", "mathaxclient", "xyz.mathax", "MathaxClient",
    "Aristois", "aristois", "com.aristois", "AristoisMod",
    "LiquidBounce", "liquidbounce", "net.ccbluex.liquidbounce", "ccbluex",
    "FDPClient", "fdpclient", "fdp-client", "FDPClientMod",
    "CrossSine", "NightX", "NightSky", "SkidBounce", "LiquidBounce+",
    "Inertia", "inertiaclient", "InertiaClient", "dev.inertia",
    "3arthh4ck", "earthhack", "EarthHack", "me.earth.earthhack",
    "RusherHack", "rusherhack", "org.rusherhack", "RusherHackClient",
    "FutureClient", "futureclient", "com.futureclient", "FutureHack",
    "KonasCached", "KonasClient", "me.konas",
    "Wurst", "net.wurstclient.wurst", "WurstPlus2", "WurstPlus3",
    "KamiBlue", "me.zeroeightsix.kami", "org.kamismash", "Kami",
    "GrimClient", "grim client", "grimclient",
    "Novoline", "novoline", "cc/novoline", "net.novoline",
    "RiseClient", "rise.today",
    "Tenacity", "tenacityclient", "TenacityClient", "dev.tenacity",
    "Astolfo", "astolfo", "AstolfoClient", "astolfo.club",
    "MoonClient", "cc.moon", "dev.augustus", "AugustusClient",
    "ExhibitionClient", "cc.exhibition", "AzuraClient", "dev.azura",
    "SkilledClient", "PandawareClient",
    "DoomsdayClient", "doomsdayclient", "doomsday.jar",
    "NovaClient", "novaclient", "api.novaclient.lol",
    "PrestigeClient", "prestigeclient", "prestigeclient.vip",
    "GypsyClient", "XenonClient", "VirginClient", "CatleanClient",
    "ArgonClient", "AsteriaClient", "Dqrkis Client", "dqrkis.xyz",
    "AbyssClient", "dev.abyss", "DripClient", "dev.drip",
    "SlinkyClient", "EntropyClient", "dev.entropy", "HaruClient",
    "DreamClient", "KarmaClient", "AnticClient", "CryptClient",
    "HanabiClient", "RageClient", "AutumnClient", "PhantomClient",
    "ThunderHack", "thunderhacked", "ThunderHacked", "ThunderHackRecode", "CoffeeClient",
    "CornosClient", "RemixClient", "FlavorClient", "MintClient",
    "AzuriteClient", "SigmaClient", "info.sigmaclient", "WinterClient",
    "FluxClient", "flux.gg", "ZerodayClient", "SolarClient",
    "vape.gg", "vapeclient", "VapeClient", "VapeLite",
    "IntentClient", "intent.store", "NovoClient",
    "ImpactClient", "impactclient", "com.impactclient", "Seppuku", "Osiris", "Gamesense",
    "Catalyst", "Kino", "Pyro", "Wolfram",
    "NullPoint", "Tensor", "Postman", "Cosmos", "OyVey",
    "LiquidCloud", "Envy", "EnvyClient", "Hades", "HadesClient",
    "Nursultan", "NursultanClient", "Akrien", "AkrienClient",
    "ExpensiveClient", "CelestialClient", "NeverHook", "DeadCode",
    "WildClient", "MidnightClient",
    "PhobosGonzo", "PhobosMelted", "PhobosOzark",
    "KillAura", "ClickAura", "MultiAura", "ForceField", "LegitAura",
    "AimBot", "AutoAim", "AimLock", "HeadSnap",
    "CrystalAura", "AnchorAura", "AnchorFill", "AnchorPlace",
    "BedAura", "AutoBed", "BedBomb", "BedPlace",
    "BowAimbot", "BowSpam", "AutoBow", "AutoCrit", "CritBypass",
    "ReachHack", "ExtendReach", "LongReach", "HitboxExpand",
    "AntiKB", "NoKnockback", "VelocitySpoof", "KBReduce",
    "OffhandTotem", "TotemSwitch", "AutoWeapon", "AutoCity", "SelfTrap",
    "HoleFiller", "AntiSurround", "AntiBurrow", "WTap", "TargetStrafe",
    "AutoGap", "AutoPearl", "FlyHack", "PacketFly",
    "SpeedHack", "BHop", "BunnyHop", "AntiFall", "NoFallDamage", "SafeFall",
    "StepHack", "FastClimb", "AutoStep", "HighStep", "WaterWalk", "LiquidWalk",
    "WallHack", "ElytraSpeed", "InstantElytra", "ScaffoldWalk", "FastBridge",
    "Nuker", "InstantBreak", "GhostHand", "PlaceAssist", "AirPlace",
    "PlayerESP", "MobESP", "ItemESP", "StorageESP", "ChestESP", "Tracers", "NameTagsHack",
    "XRayHack", "OreFinder", "CaveFinder", "OreESP", "NewChunks", "TunnelFinder",
    "DoubleClicker", "ChestStealer", "InvManager", "InvMovebypass",
    "FakeLatency", "FakePing", "SpoofRotation", "SpeedTimer",
    "PacketMine", "PacketCancel", "PacketDupe", "PacketSpam", "PacketLogger",
    "SessionStealer", "TokenLogger", "TokenGrabber", "DiscordToken",
    "RemoteAccess", "ReverseShell", "Backdoor", "KeyLogger",
    "StashFinder", "TrailFinder", "client-refmap.json", "cheat-refmap.json",
    "HWIDAuth", "HWIDCheck", "LicenseAuth", "LicenseCheck",
    "TellyBridge", "JesusWalk", "SpiderWall", "StrafeSpeed",
    "BedNuker", "CrystalNuker", "BacktrackModule",
    "PearlClip", "BoatAura",
    "JDWP.VirtualMachine.AllModules",
    "AutoBreach", "SpearSwap", "AutoMace", "CrystalPredict", "CrystalOptimize",
    "BowAim", "AutoCrit", "SmartCrit", "ReachHack",
    "FakePlayerModule", "BoatFly",
    "EntityControl", "AntiCactus", "TowerScaffold",
    "org.chainlibs.module.impl.modules", "com/alan/clients",
    "wtf/moonlight", "today/opai", "net/minecraft/injection",
    "CameraClipBypass", "TimeChanger", "WeatherChanger", "DiscordWebhookLogger",
    "TokenStealer", "PasswordGrabber", "HWIDCheckAuth", "LicenseKeyAuth", "SelfDestructClean",
    "DripLite", "SlinkyMod", "HaruLite", "Augustus", "ItamiGhost", "LowkeyV2", "WhiteoutV2",
    "MangoGhost", "KuriumClient", "YukawaClient", "TeaspoonClient", "CoilClient", "TukeClient",
    "VeloClient", "AmethystClient", "OnyxGhost", "PugwareClient", "FranciumGhost", "GrandlineClient",
    "AspirahClient", "MeraClient", "ScrimsClient", "ZorimClient", "VoltClient", "VrilClient",
    "OsmiunClient", "ZenithClient", "CymerClient", "GardeniaClient", "SakurwaClient", "SilkClient",
    "ZoomiesClient", "NyrexClient", "RemnantClient", "4EClient", "AchillesClient", "MistClient",
    "CWClient", "Crystalware", "CrystalwareClient", "GrimOptimizer", "LWFHAuto", "AnchorPredict",
    "PopPredictor", "CrystalPlaceDelay", "HitCrystalOptimizer", "FastCrystalMod", "AutoDoubleHandMod",
    "ShieldBreakerMod", "AxeSwapMod", "MaceSwapMod", "SpearSwapMod", "WebMacroMod", "AutoTotemMod",
    "AnchorMacroMod", "StunSlamMod", "JDWPAgent", "NativeInjector", "PipeBridge", "NamedPipeClient",
    "DynamicSynthesizer", "MemoryScrubber", "BytecodePatcher",
    "MaceFallMultiplier", "WindChargeLauncher", "BreezeRodSwitcher", "CrafterPacketSpam", "MaceSmashHelper",
    "WindChargeBurst", "SpearChargeSpoof", "AutoCrafterDupe", "MaceDamageCalculator", "WindChargeBoost",
    "MaceComboTiming", "BreezeRodSwitch"
)

$script:macroIdentifiers = @(
    "CPvPMacros", "cpvpmacros", "ClickCrystals", "clickcrystals",
    "CrystalMacroMod", "AutoInventoryTotem", "AnchorExplorer",
    "AirAnchorMacro", "FastXPMacro", "NoBounce", "FastCrystal",
    "198Macro", "Macro198", "198macros", "WebMacro", "AutoWeb", "AntiWeb",
    "DoubleHand", "AutoDoubleHand", "RefillTotem", "HotbarManager",
    "DtapMacro", "AutoDtap", "KeyPearl", "LootYeeter", "AutoPotRefill",
    "AutoGlowstone", "FastAnchorPlace", "AutoTotemSwap", "InventoryRefillMacro",
    "FastDropper", "AutoDisconnectMacro", "QuickSlotMacro", "ArmorSwapMacro",
    "WindChargeAuto", "MaceComboMacro", "CrafterSpamMacro", "AutoFireworkSwap",
    "PearlRefillMacro", "TotemRefillMacro", "ShieldMacro", "ElytraMacro",
    "SwordBlockMacro", "AxeSpamMacro", "BowSpamMacro", "CrossbowAutoLoad"
)

$script:flaggedContent = @(
    "AutoCrystal", "autocrystal", "auto crystal", "cw crystal", "JDWP.VirtualMachine.AllModules",
    "dontPlaceCrystal", "dontBreakCrystal", "dev.virel", "orchard",
    "AutoHitCrystal", "autohitcrystal", "canPlaceCrystalServer",
    "AutoAnchor", "autoanchor", "auto anchor", "DoubleAnchor",
    "HasAnchor", "anchortweaks", "anchor macro", "safe anchor", "safeanchor",
    "SafeAnchor", "AirAnchor", "anchorMacro", "AutoTotem", "autototem", "auto totem",
    "InventoryTotem", "inventorytotem", "HoverTotem", "hover totem", "legittotem",
    "AutoPot", "autopot", "auto pot", "AutoPotRefill",
    "preventSwordBlockBreaking", "preventSwordBlockAttack",
    "ShieldDisabler", "ShieldBreaker", "Breaking shield with axe...",
    "AutoDoubleHand", "autodoublehand", "auto double hand",
    "AutoClicker", "Failed to switch to mace after axe!", "AutoMace", "MaceSwap", "SpearSwap",
    "StunSlam", "JumpReset", "axespam", "findKnockbackSword", "attackRegisteredThisClick",
    "AimAssist", "aimassist", "aim assist", "triggerbot", "trigger bot",
    "Silent Rotations", "SilentRotations", "FakeInv", "swapBackToOriginalSlot",
    "FakeLag", "pingspoof", "ping spoof", "fakePunch", "Fake Punch",
    "mace_swap", "quick_strike", "macro_198", "stun_slam", "safe_anchor", "double_anchor",
    "walksy_optimizer", "key_pearl", "aim_assist", "auto_neth_pot", "auto_dtap", "trigger_bot", "auto_web",
    "DOUBLE_ESCAPE", "DOUBLE_RIGHTCLICK_FIRST", "DOUBLE_RIGHTCLICK_SECOND",
    "POST_CYCLE_DELAY", "PLACE_OBI", "WAIT_OBI", "PLACE_CRYSTAL", "BREAK_CRYSTAL",
    "ROTATING_DOWN", "ROTATING_BACK", "REFILLING", "PLANTING", "BONEMEALING",
    "AnchorAction", "Places two anchors for massive damage", "REOFFHAND_TOTEM",
    "webmacro", "web macro", "AntiWeb", "AutoWeb", "lvstrng", "dqrkis", "selfdestruct", "self destruct",
    "WalksyCrystalOptimizerMod", "WalksyOptimizer", "WalskyOptimizer", "autoCrystalPlaceClock",
    "AutoFirework", "ElytraSwap",
    "PackSpoof", "Antiknockback", "catlean", "AuthBypass", "obfuscatedAuth", "LicenseCheckMixin",
    "BaseFinder", "invsee", "ItemExploit", "FreezePlayer", "KeyPearl", "LootYeeter",
    "FastPlace", "AutoBreach", "setBlockBreakingCooldown", "getBlockBreakingCooldown",
    "setItemUseCooldown", "invokeDoAttack", "invokeDoItemUse", "invokeOnMouseButton",
    "onPushOutOfBlocks", "onIsGlowing", "POT_CHEATS", "Dqrkis Client", "Entity.isGlowing",
    "No Count Glitch", "No Bounce", "NoBounce", "Stop On Kill", "damagetick",
    "Glowstone Delay", "Explode Delay", "Reach Distance", "Strict One-Tick",
    "KillAura", "ClickAura", "MultiAura", "ForceField", "LegitAura",
    "AimBot", "AutoAim", "SilentAim", "CrystalAura", "AnchorAura", "BedAura",
    "AutoCrit", "CritBypass", "ReachHack", "AntiKB", "NoKnockback", "GrimVelocity",
    "OffhandTotem", "AutoWeapon", "WTap", "TargetStrafe", "AutoGap", "AutoPearl",
    "FlyHack", "PacketFly", "SpeedHack", "BHop", "AntiFall", "NoFallDamage",
    "StepHack", "WaterWalk", "NoSlowdown", "WallHack", "ScaffoldWalk",
    "Nuker", "InstantBreak", "PlaceAssist", "PlayerESP", "Tracers", "XRayHack",
    "DoubleClicker", "ChestStealer", "InvManager",
    "GrimBypass", "VulcanBypass", "MatrixBypass", "PolarBypass", "KarhuBypass",
    "VerusDisabler", "IntaveBypass", "WatchdogBypass", "SpartanBypass",
    "PacketMine", "PacketCancel", "PacketDupe", "SelfDestruct", "StashFinder",
    "client-refmap.json", "cheat-refmap.json",
    "aHR0cDovL2FwaS5ub3ZhY2xpZW50LmxvbC93ZWJob29rLnR4dA==",
    "meteordevelopment", "cc/novoline", "com/alan/clients", "wtf/moonlight",
    "me/zeroeightsix/kami", "net/ccbluex", "today/opai", "net/minecraft/injection",
    "org/chainlibs/module/impl/modules", "xyz/greaj", "pw/cinque",
    "vape.gg", "vapeclient", "VapeClient", "VapeLite", "intent.store", "riseclient.com",
    "meteor-client", "meteorclient", "meteordevelopment.meteorclient",
    "liquidbounce", "fdp-client", "aristois", "impactclient", "azura",
    "pandaware", "moonClient", "astolfo", "futureClient", "konas", "rusherhack",
    "dev.krypton", "dev/krypton", "skid.krypton", "VirginClient", "catlean",
    "ArgonClient", "Asteria", "Prestige", "prestigeclient.vip", "gypsy", "Xenon",
    "phantom-refmap.json", "dqrkis.xyz",
    "GrimVelocity", "GrimSpeed", "GrimFly", "GrimScaffold", "GrimDisabler", "GrimKillAura",
    "VulcanFly", "VulcanSpeed", "VulcanKillAura", "VulcanScaffold", "VulcanDisabler",
    "MatrixSpeed", "MatrixFly", "MatrixKillAura", "MatrixScaffold", "MatrixDisabler",
    "PolarDisabler", "PolarFly", "PolarSpeed", "PolarKillAura", "PolarScaffold",
    "KarhuSpeed", "KarhuFly", "KarhuKillAura", "KarhuScaffold", "KarhuDisabler",
    "VerusFly", "VerusSpeed", "VerusCombat", "VerusScaffold", "VerusDisabler",
    "IntaveFly", "IntaveSpeed", "IntaveKillAura", "IntaveScaffold", "IntaveDisabler",
    "WatchdogFly", "WatchdogSpeed", "WatchdogKillAura", "WatchdogScaffold", "WatchdogDisabler",
    "SpartanFly", "SpartanSpeed", "SpartanKillAura", "SpartanScaffold", "SpartanDisabler",
    "AACFly", "AACSpeed", "AACKillAura", "AACScaffold", "AACDisabler",
    "NCPSpeed", "NCPFly", "NCPKillAura", "NCPScaffold", "NCPDisabler",
    "HWIDAuth", "HWIDCheck", "LicenseAuth",
    "TellyBridge", "JesusWalk", "SpiderWall", "StrafeSpeed",
    "BedNuker", "CrystalNuker", "BacktrackModule", "PearlClip",
    "BoatAura",
    "cmd.exe /c timeout & del", "cmd /c del", "powershell -command remove-item",
    "cmd.exe /c ping 127.0.0.1 & del", "taskkill /f /im javaw.exe & del",
    "powershell -c remove-item", "start /b cmd /c del",
    "ＡｕｔｏＣｒｙｓｔａｌ", "Ａｕｔｏ Ｃｒｙｓｔａｌ", "ＡｕｔｏＨｉｔＣｒｙｓｔａｌ",
    "ＡｕｔｏＡｎｃｈｏｒ", "Ａｕｔｏ Ａｎｃｈｏｒ", "ＤｏｕｂｌｅＡｎｃｈｏｒ",
    "ＳａｆｅＡｎｃｈｏｒ", "Ａｎｃｈｏｒ Ｍａｃｒｏ", "ＡｕｔｏＴｏｔｅｍ",
    "ＨｏｖｅｒＴｏｔｅｍ", "ＩｎｖｅｎｔｏｒｙＴｏｔｅｍ", "ＡｕｔｏＰｏｔ",
    "ＡｕｔｏＡｒｍｏｒ", "ＳｈｉｅｌｄＤｉｓａｂｌｅｒ", "ＡｕｔｏＤｏｕｂｌｅＨａｎｄ",
    "ＡｕｔｏＣｌｉｃｋｅｒ", "ＡｕｔｏＭａｃｅ", "ＭａｃｅＳｗａｐ",
    "Ｓｔｕｎ Ｓｌａｍ", "ＡｉｍＡｓｓｉｓｔ", "ＴｒｉｇｇｅｒＢｏｔ",
    "Ｓｉｌｅｎｔ Ｒｏｔａｔｉｏｎｓ", "ＦａｋｅＬａｇ", "Ｆａｋｅ Ｐｕｎｃｈ",
    "Ａｎｔｉ Ｗｅｂ", "ＡｕｔｏＷｅｂ", "Ｗａｌｋｓｙ Ｏｐｔｉｍｉｚｅｒ",
    "ＥｌｙｔｒａＳｗａｐ", "Ｆｒｅｅｃａｍ", "Ｎｏ Ｃｌｉｐ",
    "ＫｅｙＰｅａｒｌ", "Ｌｏｏｔ Ｙｅｅｔｅｒ", "Ｆａｓｔ Ｐｌａｃｅ",
    "Ａｕｔｏ Ｂｒｅａｃｈ", "ＳｍａｒｔＣｒｉｔ", "ＡｕｔｏＢｌｏｃｋ",
    "ＣｏｍｂｏＭｏｄｅ", "ＫｉｌｌＡｕｒａ", "ＣｌｉｃｋＡｕｒａ",
    "ＭｕｌｔｉＡｕｒａ", "ＦｏｒｃｅＦｉｅｌｄ", "ＣｒｙｓｔａｌＡｕｒａ",
    "ＡｎｃｈｏｒＡｕｒａ", "ＢｅｄＡｕｒａ", "ＮｏＦａｌｌ",
    "ＳｐｅｅｄＨａｃｋ", "ＦｌｙＨａｃｋ", "ＮｏＳｌｏｗ",
    "ＥＳＰ", "Ｔｒａｃｅｒｓ", "Ｃｈａｍｓ", "ＸＲａｙ", "Ｆｕｌｌｂｒｉｇｈｔ",
    "Ｎｕｋｅｒ", "Ｓｃａｆｆｏｌｄ", "ＦａｓｔＢｒｅａｋ", "ＰａｃｋｅｔＦｌｙ",
    "Ｄｉｓａｂｌｅｒ", "ＶｅｌｏｃｉｔｙＳｐｏｏｆ", "ＡｕｔｏＰｅａｒｌ",
    "ＡｕｔｏＧａｐ", "ＡｕｔｏＳｗｏｒｄ", "Ｂｕｒｒｏｗ", "ＳｅｌｆＴｒａｐ",
    "ＨｏｌｅＦｉｌｌｅｒ", "ＷＴａｐ", "ＡｎｔｉＡＦＫ", "ＣｈｅｓｔＳｔｅａｌｅｒ",
    "Ｍｅｔｅｏｒ", "ＢｌｅａｃｈＨａｃｋ", "Ｌｉｑｕｉｄ Ｂｏｕｎｃｅ",
    "Ｗｕｒｓｔ", "Ａｒｉｓｔｏｉｓ", "Ｍａｔｈａｘ", "Ｉｍｐａｃｔ",
    "Ｎｏｖｏｌｉｎｅ", "Ｒｉｓｅ", "Ｔｅｎａｃｉｔｙ", "Ａｓｔｏｌｆｏ",
    "Ｆｕｔｕｒｅ", "Ｋｏｎａｓ", "Ｒｕｓｈｅｒ Ｈａｃｋ", "ＳｃａｆｆｏｌｄＷａｌｋ",
    "ＡｉｒＰｌａｃｅ", "ＰａｃｋｅｔＭｉｎｅ", "ＰａｃｋｅｔＣａｎｃｅｌ",
    "ＢａｃｋＴｒａｃｋ", "ＰｅａｒｌＣｌｉｐ", "ＦｒｅｅＣａｍ",
    "ＪｅｓｕｓＷａｌｋ", "ＴｏｗｅｒＳｃａｆｆｏｌｄ", "ＢｏａｔＦｌｙ",
    "ＢｏａｔＡｕｒａ", "ＦａｋｅＰｌａｙｅｒ", "ＥｎｔｉｔｙＣｏｎｔｒｏｌ",
    "ＡｎｔｉＣａｃｔｕｓ", "ＡｕｔｏＤｉｓｃｏｎｎｅｃｔ", "ＡｕｔｏＬｅａｖｅ",
    "Novoware", "NovowareClient", "novowareclient", "novoware.eu",
    "HellClient", "hellclient", "hellclient.eu",
    "OpaiClient", "22qqClient",
    "CWHack", "PlatiniumClient", "OnyxClient", "PuggerClient",
    "FranciumClient", "PugwareClient", "VirginsPremium", "GrandlineVirgin",
    "AspirahArgoon", "MeraPrivateClient", "ScrimsClient", "ZorimClient", "VoltClient",
    "VrilClient", "OsmiunClient", "ZenithClient", "CymerClient",
    "3Q1PotClient", "GardeniaClient", "SakurwaClient", "SilkClient", "ZoomiesClient",
    "NiggaHackClient", "NyrexClient", "RemnantClient", "4EClient", "AchillesClient", "MistClient",
    "RavenB+", "RavenB3", "RavenWeave", "RavenFabric",
    "KuraClient", "ExosClient", "PulsarClient", "CosmicClient", "ItamiClient",
    "LowkeyClient", "WhiteoutClient", "BreezeClient", "MangoClient",
    "HCSCRCrystalOptimizer", "FlashCrystalOptimizer", "HerosAnchorOptimizer",
    "ClientSidedCrystals", "AirAnchorMacro",
    "ＷｉｎｄＣｈａｒｇｅ", "ＭａｃｅＳｗａｐ", "ＢｒｅｅｚｅＲｏｄ", "ＣｒａｆｔｅｒＳｐａｍ", "ＡｕｔｏＣｒａｆｔｅｒ",
    "ＭａｃｅＤａｍａｇｅ", "ＳｐｅａｒＣｈａｒｇｅ", "ＡｎｃｈｏｒＰｒｅｄｉｃｔ", "ＰｏｐＰｒｅｄｉｃｔ"
)

$script:knownModIdentities = @{
    "sodium"        = @{ id = "sodium";        pkg = "me.jellysquid" }
    "lithium"       = @{ id = "lithium";       pkg = "me.jellysquid" }
    "iris"          = @{ id = "iris";          pkg = "net.irisshaders" }
    "fabric-api"    = @{ id = "fabric-api";    pkg = "net.fabricmc" }
    "fabric-language-kotlin" = @{ id = "fabric-language-kotlin"; pkg = "net.fabricmc" }
    "modmenu"       = @{ id = "modmenu";       pkg = "com.terraformersmc" }
    "optifine"      = @{ id = "optifine";      pkg = "net.optifine" }
    "phosphor"      = @{ id = "phosphor";      pkg = "me.jellysquid" }
    "starlight"     = @{ id = "starlight";     pkg = "ca.spottedleaf" }
    "indium"        = @{ id = "indium";        pkg = "link.infra" }
    "continuity"    = @{ id = "continuity";    pkg = "me.pepperbell" }
    "entityculling" = @{ id = "entityculling"; pkg = "dev.tr7zw" }
    "ferrite-core"  = @{ id = "ferrite-core";  pkg = "ferritecore" }
    "ferritecore"   = @{ id = "ferritecore";   pkg = "ferritecore" }
    "memoryleakfix" = @{ id = "memoryleakfix"; pkg = "forkiesassist" }
    "immediatelyfast" = @{ id = "immediatelyfast"; pkg = "net.raphimc" }
    "krypton"       = @{ id = "krypton";       pkg = "me.steinborn" }
    "mousetweaks"   = @{ id = "mousetweaks";   pkg = "yalter" }
    "cloth-config"  = @{ id = "cloth-config";  pkg = "me.shedaniel" }
    "appleskin"     = @{ id = "appleskin";     pkg = "squeek502" }
    "xaeros-minimap" = @{ id = "xaeros-minimap"; pkg = "xaero" }
    "xaeros-worldmap" = @{ id = "xaeros-worldmap"; pkg = "xaero" }
    "journeymap"    = @{ id = "journeymap";    pkg = "journeymap" }
    "rei"           = @{ id = "rei";           pkg = "me.shedaniel" }
    "jei"           = @{ id = "jei";           pkg = "mezz.jei" }
    "emi"           = @{ id = "emi";           pkg = "dev.emi" }
    "create"        = @{ id = "create";        pkg = "com.simibubi" }
    "wthit"         = @{ id = "wthit";         pkg = "mcp.mobius" }
    "jade"          = @{ id = "jade";          pkg = "snownee" }
    "badpackets"    = @{ id = "badpackets";    pkg = "lol.bai" }
    "architectury"  = @{ id = "architectury";  pkg = "dev.architectury" }
    "replaymod"     = @{ id = "replaymod";     pkg = "com.replaymod" }
    "tweakeroo"     = @{ id = "tweakeroo";     pkg = "fi.dy.masa" }
    "litematica"    = @{ id = "litematica";    pkg = "fi.dy.masa" }
    "malilib"       = @{ id = "malilib";       pkg = "fi.dy.masa" }
    "minihud"       = @{ id = "minihud";       pkg = "fi.dy.masa" }
    "itemscroller"  = @{ id = "itemscroller";  pkg = "fi.dy.masa" }
    "no-chat-reports" = @{ id = "no-chat-reports"; pkg = "com.aizistral" }
    "voicechat"     = @{ id = "voicechat";     pkg = "de.maxhenkel" }
    "plasmo-voice"  = @{ id = "plasmo-voice";  pkg = "su.plo" }
    "lambdynamiclights" = @{ id = "lambdynamiclights"; pkg = "dev.lambdaurora" }
    "dynamic-fps"   = @{ id = "dynamic-fps";   pkg = "juliand665" }
    "debugify"      = @{ id = "debugify";      pkg = "dev.isxander" }
    "zoomify"       = @{ id = "zoomify";       pkg = "dev.isxander" }
    "ok-zoomer"     = @{ id = "ok-zoomer";     pkg = "io.github.ennui" }
    "c2me"          = @{ id = "c2me";          pkg = "com.ishland" }
    "noxesium"      = @{ id = "noxesium";      pkg = "com.noxcrew" }
    "modernfix"     = @{ id = "modernfix";     pkg = "com.embeddedt" }
    "spark"         = @{ id = "spark";         pkg = "me.lucko" }
    "carpet"        = @{ id = "carpet";        pkg = "carpet" }
    "inventoryprofilesnext" = @{ id = "inventoryprofilesnext"; pkg = "fi.dy.masa" }
    "libipn"        = @{ id = "libipn";        pkg = "org.anti_ad" }
    "custom-crosshair" = @{ id = "custom-crosshair"; pkg = "sparkless" }
    "cit-resewn"    = @{ id = "cit-resewn";    pkg = "shsupercm" }
    "sodium-extra"  = @{ id = "sodium-extra";  pkg = "me.flashyreese" }
    "reeses-sodium-options" = @{ id = "reeses-sodium-options"; pkg = "me.flashyreese" }
    "skinlayers3d"  = @{ id = "skinlayers3d";  pkg = "dev.tr7zw" }
    "viafabric"     = @{ id = "viafabric";     pkg = "com.viaversion" }
    "viabackwards"  = @{ id = "viabackwards";  pkg = "com.viaversion" }
    "axiom"         = @{ id = "axiom";         pkg = "com.moulberry" }
    "controlify"    = @{ id = "controlify";    pkg = "dev.isxander" }
    "better-runtime-resource-pack" = @{ id = "better-runtime-resource-pack"; pkg = "io.github.shedaniel" }
    "yosbr"         = @{ id = "yosbr";         pkg = "com.shedaniel" }
    "midnightlib"   = @{ id = "midnightlib";   pkg = "eu.midnightdust" }
    "puzzle"        = @{ id = "puzzle";        pkg = "eu.midnightdust" }
    "fabric-language-scala" = @{ id = "fabric-language-scala"; pkg = "net.fabricmc" }
    "owo-lib"       = @{ id = "owo-lib";       pkg = "io.wispforest" }
    "marlow"        = @{ id = "marlows-crystal-optimizer"; pkg = "marlow" }
    "marlow-crystal-optimizer" = @{ id = "marlows-crystal-optimizer"; pkg = "marlow" }
    "marlows-crystal-optimizer" = @{ id = "marlows-crystal-optimizer"; pkg = "marlow" }
    "crystal-optimizer" = @{ id = "marlows-crystal-optimizer"; pkg = "marlow" }
}

$script:identifierMatcher = [regex]::new(
    '(?<![A-Za-z0-9_])(' + ($script:flaggedIdentifiers -join '|') + ')(?![A-Za-z0-9_])',
    [System.Text.RegularExpressions.RegexOptions]::Compiled
)

$script:macroMatcher = [regex]::new(
    '(?<![A-Za-z0-9_])(' + ($script:macroIdentifiers -join '|') + ')(?![A-Za-z0-9_])',
    [System.Text.RegularExpressions.RegexOptions]::Compiled
)

$script:contentLookup = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($s in $script:flaggedContent) { [void]$script:contentLookup.Add($s) }



$script:wideCharMatcher = [regex]::new(
    "[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]{2,}",
    [System.Text.RegularExpressions.RegexOptions]::Compiled
)

function Test-CheatArchitecture {
    param($ArchiveData)
    $archScore = 0
    $signals = [System.Collections.Generic.List[string]]::new()
    $allCpStrings = [System.Collections.Generic.List[string]]::new()

    foreach ($k in $ArchiveData.ClassBytes.Keys) {
        if ($k -match '\.class$') {
            $cp = [FastScanner]::ParseConstantPool($ArchiveData.ClassBytes[$k])
            foreach ($s in $cp) { [void]$allCpStrings.Add($s) }
        }
    }

    $hasCombatCat = $false
    $hasExploitCat = $false
    $hasMovementCat = $false
    $hasRenderCat = $false

    $modTokens = 0
    $combatKeyTokens = 0
    $hudTokens = 0
    $prefixTokens = 0
    $settingTokens = 0
    $friendTokens = 0
    $eventTokens = 0

    foreach ($s in $allCpStrings) {
        if ($s -eq "COMBAT")   { $hasCombatCat = $true }
        if ($s -eq "EXPLOIT")  { $hasExploitCat = $true }
        if ($s -eq "MOVEMENT") { $hasMovementCat = $true }
        if ($s -eq "RENDER")   { $hasRenderCat = $true }
        if ($s -match "^(toggleModule|registerModule)$" -and ($s -match "KillAura|AutoCrystal|Aimbot|TriggerBot|Freecam")) { $modTokens++ }
        if ($s -match "KillAura|AutoCrystal|Aimbot|TriggerBot|AnchorAura|CrystalAura") {
            if ($s -match "glfwSetKeyCallback|onKeyPress") { $combatKeyTokens++ }
        }
        if ($s -match "BooleanSetting|ModeSetting|NumberSetting|SliderSetting|KeybindSetting") { $settingTokens++ }
        if ($s -match "addFriend|removeFriend|isFriend|friendList|enemyList") { $friendTokens++ }
        if ($s -match "PacketEvent|MotionEvent|LivingUpdateEvent") { $eventTokens++ }
    }

    if ($modTokens -ge 1) { $archScore += 30; [void]$signals.Add("Module Manager Architecture (+30)") }
    if ($combatKeyTokens -ge 1) { $archScore += 25; [void]$signals.Add("Direct Combat Keybind Toggle (+25)") }
    if ($hasCombatCat -and $hasExploitCat -and ($hasMovementCat -or $hasRenderCat)) { $archScore += 20; [void]$signals.Add("Module Category Enum System (+20)") }
    if ($settingTokens -ge 3) { $archScore += 20; [void]$signals.Add("Hack Module Setting Hierarchy (+20)") }
    if ($friendTokens -ge 1) { $archScore += 15; [void]$signals.Add("Target Friend/Enemy List Manager (+15)") }
    if ($eventTokens -ge 2) { $archScore += 20; [void]$signals.Add("Combat Event Bus Subsystem (+20)") }

    return @{ Score = $archScore; Signals = $signals }
}

function Get-MixinTargetProfile {
    param($ArchiveData)
    $categories = @{
        Combat    = $false
        Packets   = $false
        Movement  = $false
        Rendering = $false
        Input     = $false
    }
    foreach ($k in $ArchiveData.ClassBytes.Keys) {
        if ($k -match 'mixins?\.json$') {
            $txt = [System.Text.Encoding]::UTF8.GetString($ArchiveData.ClassBytes[$k])
            if ($txt -match 'ClientPlayerEntity|ClientPlayerInteractionManager|LivingEntity|PlayerEntity') { $categories.Combat = $true }
            if ($txt -match 'ClientPlayNetworkHandler|ClientConnection|NetworkHandler') { $categories.Packets = $true }
            if ($txt -match 'Entity|LivingEntity|PlayerEntity') { $categories.Movement = $true }
            if ($txt -match 'GameRenderer|WorldRenderer|InGameHud|LivingEntityRenderer|EntityRenderer') { $categories.Rendering = $true }
            if ($txt -match 'Mouse|Keyboard|MinecraftClient|KeyboardInput') { $categories.Input = $true }
        }
    }
    $hitCount = 0
    foreach ($c in $categories.Keys) { if ($categories[$c]) { $hitCount++ } }
    return @{ HitCount = $hitCount; Categories = $categories; IsSuspiciousCluster = ($hitCount -ge 3) }
}

[FastScanner]::InitAll($script:flaggedIdentifiers, $script:macroIdentifiers, $script:flaggedContent, $reflectionIndicators)




$script:fwCheatPool = @($script:flaggedContent | Where-Object {
    $_ -cmatch '[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]'
})

function Start-USNAnalysis {
    param([string]$ModsDir, [object]$GameStartTime = $null)
    $alerts = [System.Collections.Generic.List[string]]::new()
    $vol = (Get-Item $ModsDir).PSDrive.Name + ":"
    try {
        $driveLetter = (Get-Item $ModsDir).PSDrive.Name
        $volInfo = Get-Volume -DriveLetter $driveLetter -ErrorAction SilentlyContinue
        if ($volInfo -and $volInfo.FileSystem -match "FAT|exFAT") {
            [void]$alerts.Add("VOLUME WARNING: Mods folder is on $($volInfo.FileSystem) filesystem without USN Journal support")
            return $alerts
        }
    } catch { }

    try {
        $histPath = (Get-PSReadLineOption -ErrorAction SilentlyContinue).HistorySavePath
        if (-not $histPath -or -not (Test-Path $histPath)) {
            $histPath = "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
        }
        if (Test-Path $histPath) {
            $histLines = Get-Content -Path $histPath -Tail 200 -ErrorAction SilentlyContinue
            foreach ($line in $histLines) {
                if ($line -match "fsutil\s+usn\s+deletejournal" -or $line -match "Clear-EventLog" -or $line -match "wevtutil\s+cl") {
                    [void]$alerts.Add("COMMAND HISTORY TRACE: Evidence of anti-forensic log/journal clearing ($line)")
                }
            }
        }
    } catch { }

    try {
        $rawUsn = fsutil usn readjournal $vol csv 2>$null
        if (-not $rawUsn) { return $alerts }
        $cutoff = (Get-Date).AddHours(-48)
        $normPath = $ModsDir.Replace("/", "\\").TrimEnd("\\")
        $fileEvents = @{}
        foreach ($line in $rawUsn) {
            $cols = $line -split ","
            if ($cols.Count -ge 5) {
                $name = $cols[0].Trim('"')
                $reason = $cols[1].Trim('"')
                $timeStr = $cols[2].Trim('"')
                $path = $cols[4].Trim('"')
                if ($name.EndsWith(".jar") -and $path.Contains($normPath)) {
                    try {
                        $dt = [datetime]::Parse($timeStr)
                        if ($dt -ge $cutoff) {
                            if (-not $fileEvents.ContainsKey($name)) { $fileEvents[$name] = [System.Collections.Generic.List[object]]::new() }
                            [void]$fileEvents[$name].Add(@{ Reason = $reason; Time = $dt; Path = $path })
                        }
                    } catch { }
                }
            }
        }
        foreach ($fn in $fileEvents.Keys) {
            $events = $fileEvents[$fn] | Sort-Object { $_.Time }
            $reasons = @($events | ForEach-Object { $_.Reason })
            $seqStr = $reasons -join " -> "
            $fullPath = Join-Path $ModsDir $fn
            $existsOnDisk = Test-Path $fullPath

            if ($seqStr.Contains("File Delete") -and ($seqStr.Contains("Rename: old name") -or $seqStr.Contains("Rename: new name"))) {
                [void]$alerts.Add("$fn|Explorer Replace: File Delete followed by Rename cycle (Explorer file overwrite)")
            } elseif ($seqStr.Contains("Data Truncation") -and $seqStr.Contains("Security Change") -and $seqStr.Contains("Data Overwrite")) {
                [void]$alerts.Add("$fn|Copy 1 Replace: Full Copy Replace with Security Change & Data Overwrite")
            } elseif ($seqStr.Contains("Data Truncation") -and $seqStr.Contains("Data Overwrite") -and $seqStr.Contains("Basic Info Change")) {
                [void]$alerts.Add("$fn|Copy 2 Replace: Standard Copy Replace with Data Overwrite & metadata modification")
            } elseif ($seqStr.Contains("Data Extend") -and $seqStr.Contains("Data Truncation") -and $seqStr.Contains("Close")) {
                [void]$alerts.Add("$fn|Type 1 Replace: Data Extend | Data Truncation stream overwrite (type redirect)")
            } elseif ($seqStr.Contains("Data Truncation") -and $seqStr.Contains("Data Extend")) {
                [void]$alerts.Add("$fn|Type 2 Replace: Data Truncation followed by Data Extend truncation cycle")
            } elseif ($seqStr.Contains("Data Overwrite") -and $seqStr.Contains("Data Extend")) {
                [void]$alerts.Add("$fn|HEX Replace: Direct in-place binary data overwrite (Hex editor / Bytecode patcher)")
            } elseif ($seqStr.Contains("Basic Info Change") -and -not $seqStr.Contains("Data Extend")) {
                [void]$alerts.Add("$fn|Attribute-only update: Timestamps/attributes modified without content change")
            } elseif ($seqStr.Contains("Named Data Extend") -or $seqStr.Contains("Named Data Truncation")) {
                [void]$alerts.Add("$fn|Alternate Data Stream modification detected in journal")
            } elseif (-not $existsOnDisk -and ($seqStr.Contains("File Delete") -or $seqStr.Contains("Rename: old name"))) {
                $latestEventTime = ($events[-1]).Time
                $timeDesc = if ($GameStartTime -and $latestEventTime -ge $GameStartTime) { "during active Minecraft session" } else { "within last 48h" }
                [void]$alerts.Add("$fn|USN Journal Unload/Deletion: Mod '$fn' was deleted or moved out of mods folder $timeDesc")
            }
        }
    } catch { }
    return $alerts
}

function Test-ExecutedSelfDestruct {
    param([string]$ModsDir, [object]$GameStartTime = $null)
    $findings = [System.Collections.Generic.List[object]]::new()
    $currentJars = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($f in (Get-ChildItem -Path $ModsDir -Filter *.jar -ErrorAction SilentlyContinue)) {
        [void]$currentJars.Add($f.Name)
    }

    try {
        $drives = Get-PSDrive -PSProvider FileSystem
        foreach ($d in $drives) {
            $rbPath = "$($d.Root)`$Recycle.Bin"
            if (Test-Path $rbPath) {
                $iFiles = Get-ChildItem -Path $rbPath -Filter "`$I*.jar" -Recurse -Force -ErrorAction SilentlyContinue
                foreach ($iFile in $iFiles) {
                    try {
                        $bytes = [System.IO.File]::ReadAllBytes($iFile.FullName)
                        if ($bytes.Length -ge 28) {
                            $fileTimeLong = [System.BitConverter]::ToInt64($bytes, 16)
                            $delTime = [DateTime]::FromFileTimeUtc($fileTimeLong)
                            $pathLen = [System.BitConverter]::ToInt32($bytes, 24)
                            $origPath = [System.Text.Encoding]::Unicode.GetString($bytes, 28, [Math]::Min($bytes.Length - 28, $pathLen * 2)).TrimEnd("`0")

                            if ($origPath.ToLower().Contains($ModsDir.ToLower()) -or $origPath.ToLower().Contains(".minecraft\mods")) {
                                $timeStr = $delTime.ToLocalTime().ToString("yyyy-MM-dd HH:mm:ss")
                                $fn = [System.IO.Path]::GetFileName($origPath)
                                $isSession = if ($GameStartTime -and $delTime -ge $GameStartTime) { $true } else { $false }
                                [void]$findings.Add([PSCustomObject]@{
                                    Category = "Recycle Bin Artifact"
                                    FileName = $fn
                                    Details = "Mod '$fn' was deleted from mods folder at $timeStr"
                                    OriginalPath = $origPath
                                    Timestamp = $delTime
                                    DuringGameSession = $isSession
                                })
                            }
                        }
                    } catch { }
                }
            }
        }
    } catch { }

    try {
        $driveLetter = (Get-Item $ModsDir).PSDrive.Name + ":"
        $usnQuery = fsutil usn queryjournal $driveLetter 2>$null
        if ($usnQuery) {
            $usnStr = $usnQuery -join "`n"
            if ($usnStr -match "Lowest Valid Usn\s*:\s*0x0" -or $usnStr -match "Next Usn\s*:\s*0x0") {
                [void]$findings.Add([PSCustomObject]@{
                    Category = "Journal Evidence Purge"
                    FileName = "NTFS Journal"
                    Details = "NTFS USN Change Journal was purged or reset to 0 (potential evidence destruction)"
                    OriginalPath = $driveLetter
                    Timestamp = (Get-Date)
                    DuringGameSession = $false
                })
            }
        }
    } catch { }

    return $findings
}

function Test-Timestomping {
    param([string]$FilePath, $ArchiveData)
    $flags = [System.Collections.Generic.List[string]]::new()
    $fi = Get-Item $FilePath
    if ($fi.CreationTimeUtc -gt $fi.LastWriteTimeUtc) {
        $diff = ($fi.CreationTimeUtc - $fi.LastWriteTimeUtc).TotalMinutes
        if ($diff -gt 5) {
            [void]$flags.Add("Anomalous file dates: Created ($($fi.CreationTimeUtc.ToString('yyyy-MM-dd HH:mm'))) is newer than Last Write ($($fi.LastWriteTimeUtc.ToString('yyyy-MM-dd HH:mm')))")
        }
    }
    if ($fi.LastWriteTimeUtc -gt (Get-Date).ToUniversalTime().AddDays(1)) {
        [void]$flags.Add("Future timestamp: Last modified date ($($fi.LastWriteTimeUtc.ToString('yyyy-MM-dd HH:mm'))) is in the future")
    }
    if ($ArchiveData -and $ArchiveData.ZipEntries) {
        $classDates = [System.Collections.Generic.List[datetime]]::new()
        foreach ($entry in $ArchiveData.ZipEntries) {
            if ($entry.FullName.EndsWith(".class") -and $entry.LastWriteTime.Year -gt 1980) {
                [void]$classDates.Add($entry.LastWriteTime.DateTime)
            }
        }
        if ($classDates.Count -gt 0) {
            $sorted = $classDates | Sort-Object
            $newest = $sorted[-1]
            $fileDate = $fi.LastWriteTime
            if (($fileDate - $newest).TotalDays -gt 365) {
                [void]$flags.Add("Compiled code backdated: JAR modification date is $([math]::Round(($fileDate - $newest).TotalDays)) days older than internal class compile dates")
            }
        }
    }
    return $flags
}

function Test-AlternateDataStreams {
    param([string]$FilePath)
    $adsResults = @{
        ZoneId = 0
        HostUrl = ""
        ReferrerUrl = ""
        IsCheatOrigin = $false
        IsDiscordOrigin = $false
        HasHiddenPayloadStream = $false
        StreamNames = [System.Collections.Generic.List[string]]::new()
    }
    try {
        $streams = Get-Item -Path $FilePath -Stream * -ErrorAction SilentlyContinue
        if ($streams) {
            foreach ($s in $streams) {
                if ($s.Stream -ne ':$DATA') {
                    [void]$adsResults.StreamNames.Add($s.Stream)
                    if ($s.Stream -eq 'Zone.Identifier') {
                        $zContent = Get-Content -Path "$FilePath`:Zone.Identifier" -Raw -ErrorAction SilentlyContinue
                        if ($zContent) {
                            if ($zContent -match "ZoneId=(\d+)") { $adsResults.ZoneId = [int]$matches[1] }
                            if ($zContent -match "HostUrl=(.+)") { $adsResults.HostUrl = $matches[1].Trim() }
                            if ($zContent -match "ReferrerUrl=(.+)") { $adsResults.ReferrerUrl = $matches[1].Trim() }
                            if ($adsResults.HostUrl.Contains("discord.com/attachments") -or $adsResults.HostUrl.Contains("cdn.discordapp.com") -or $adsResults.HostUrl.Contains("media.discordapp.net")) {
                                $adsResults.IsDiscordOrigin = $true
                            }
                            foreach ($domain in $script:cheatDomains) {
                                if ($adsResults.HostUrl.Contains($domain) -or $adsResults.ReferrerUrl.Contains($domain)) {
                                    $adsResults.IsCheatOrigin = $true
                                    break
                                }
                            }
                        }
                    } else {
                        try {
                            $streamBytes = [System.IO.File]::ReadAllBytes("$FilePath`:$($s.Stream)")
                            if ($streamBytes.Length -ge 4) {
                                if (($streamBytes[0] -eq 0x4D -and $streamBytes[1] -eq 0x5A) -or ($streamBytes[0] -eq 0xCA -and $streamBytes[1] -eq 0xFE -and $streamBytes[2] -eq 0xBA -and $streamBytes[3] -eq 0xBE) -or ($streamBytes[0] -eq 0x50 -and $streamBytes[1] -eq 0x4B -and $streamBytes[2] -eq 0x03 -and $streamBytes[3] -eq 0x04)) {
                                    $adsResults.HasHiddenPayloadStream = $true
                                }
                            }
                        } catch { }
                    }
                }
            }
        }
    } catch { }
    return $adsResults
}

function Start-TempScan {
    $tempHits = [System.Collections.Generic.List[string]]::new()
    $tempDirs = @($env:TEMP, "$env:USERPROFILE\\AppData\\Local\\Temp", "$env:USERPROFILE\\AppData\\Roaming\\.minecraft")
    foreach ($td in $tempDirs) {
        if (Test-Path $td) {
            try {
                $suspFiles = Get-ChildItem -Path $td -Recurse -Depth 2 -File -ErrorAction SilentlyContinue |
                    Where-Object {
                        $_.Name.EndsWith(".bat") -or $_.Name.EndsWith(".vbs") -or $_.Name.EndsWith(".dll") -or $_.Name.EndsWith(".exe") -or $_.Name.EndsWith(".jar")
                    } | Where-Object {
                        $n = $_.Name.ToLower()
                        $n.Contains("cleaner") -or $n.Contains("destruct") -or $n.Contains("injector") -or $n.Contains("drop") -or $n.Contains("patcher") -or $n.Contains("loader") -or $n.Contains("meteor") -or $n.Contains("doomsday") -or $n.Contains("novoware") -or $n.Contains("hellclient") -or $n.Contains("vape")
                    }
                foreach ($sf in $suspFiles) {
                    [void]$tempHits.Add("Suspicious helper file in temp: $($sf.FullName) ($([math]::Round($sf.Length / 1024)) KB)")
                }
            } catch { }
        }
    }
    return $tempHits
}

function Read-ArchiveData {
    param([string]$Target)
    $entryNames = [System.Collections.Generic.List[string]]::new()
    $classBytes = [System.Collections.Generic.Dictionary[string,byte[]]]::new()
    $nestedNames = [System.Collections.Generic.List[string]]::new()
    $zipEntriesList = [System.Collections.Generic.List[object]]::new()

    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($Target)
        foreach ($e in $zip.Entries) {
            [void]$entryNames.Add($e.FullName)
            [void]$zipEntriesList.Add(@{ FullName = $e.FullName; LastWriteTime = $e.LastWriteTime; Length = $e.Length })

            $fn = $e.FullName
            $isStdLib = $fn.StartsWith("kotlin/") -or $fn.StartsWith("kotlinx/") -or $fn.StartsWith("org/jetbrains/") -or $fn.StartsWith("scala/") -or $fn.StartsWith("com/google/gson/") -or $fn.StartsWith("it/unimi/dsi/fastutil/") -or $fn.StartsWith("org/apache/commons/") -or $fn.StartsWith("org/joml/") -or $fn.StartsWith("com/ibm/icu/")
            $isTarget = $fn.EndsWith(".class") -or $fn.EndsWith(".json") -or $fn.EndsWith(".toml") -or $fn.EndsWith(".info") -or $fn.EndsWith("MANIFEST.MF") -or ($e.Length -gt 0 -and $e.Length -lt 65536 -and ($fn.EndsWith(".png") -or $fn.EndsWith(".jpg") -or $fn.EndsWith(".bin") -or $fn.EndsWith(".dat") -or $fn.EndsWith(".ico") -or $fn.EndsWith(".txt") -or $fn.EndsWith(".properties")))

            if (-not $isStdLib -and $isTarget) {
                try {
                    $s = $e.Open(); $m = [System.IO.MemoryStream]::new()
                    $s.CopyTo($m); $s.Close()
                    $classBytes[$fn] = $m.ToArray(); $m.Dispose()
                } catch { }
            }
        }
        foreach ($nj in ($zip.Entries | Where-Object { $_.FullName.StartsWith("META-INF/jars/") -or $_.FullName.StartsWith("assets/") -or $_.FullName.StartsWith("data/") -or $_.FullName.StartsWith("resources/") -or $_.FullName.StartsWith("META-INF/libraries/") })) {
            if ($nj.FullName.EndsWith(".jar")) {
                $njBase = $nj.FullName
                $njSlash = $njBase.LastIndexOf("/")
                if ($njSlash -ge 0) { $njBase = $njBase.Substring($njSlash + 1) }
                $skipNested = $njBase.StartsWith("kotlin-") -or $njBase.StartsWith("kotlinx-") -or $njBase.StartsWith("fastutil-") -or $njBase.StartsWith("joml-") -or $njBase.StartsWith("commons-") -or $njBase.StartsWith("annotations-") -or $njBase.StartsWith("atomicfu-") -or $njBase.StartsWith("icu4j-") -or $njBase.StartsWith("guava-") -or $njBase.StartsWith("gson-") -or $njBase.StartsWith("asm-") -or $njBase.StartsWith("slf4j-") -or $njBase.StartsWith("log4j-") -or $njBase.StartsWith("trove4j-") -or $njBase.StartsWith("jna-") -or $njBase.StartsWith("netty-") -or $njBase.StartsWith("lwjgl-") -or $njBase.StartsWith("checker-")
                if ($skipNested) { continue }
                try {
                    $ns = $nj.Open(); $ms = [System.IO.MemoryStream]::new()
                    $ns.CopyTo($ms); $ns.Close(); $ms.Position = 0
                    $iz = [System.IO.Compression.ZipArchive]::new($ms, [System.IO.Compression.ZipArchiveMode]::Read)
                    foreach ($ie in $iz.Entries) {
                        [void]$nestedNames.Add($ie.FullName)
                        $ifn = $ie.FullName
                        $isStdLibNested = $ifn.StartsWith("kotlin/") -or $ifn.StartsWith("kotlinx/") -or $ifn.StartsWith("org/jetbrains/") -or $ifn.StartsWith("scala/") -or $ifn.StartsWith("com/google/gson/") -or $ifn.StartsWith("it/unimi/dsi/fastutil/") -or $ifn.StartsWith("org/apache/commons/") -or $ifn.StartsWith("org/joml/") -or $ifn.StartsWith("com/ibm/icu/")
                        if (-not $isStdLibNested -and ($ifn.EndsWith(".class") -or $ifn.EndsWith(".json") -or $ifn.EndsWith(".toml") -or $ifn.EndsWith(".info"))) {
                            try {
                                $is = $ie.Open(); $im = [System.IO.MemoryStream]::new()
                                $is.CopyTo($im); $is.Close()
                                $classBytes["NESTED:$ifn"] = $im.ToArray(); $im.Dispose()
                            } catch { }
                        }
                    }
                    $iz.Dispose(); $ms.Dispose()
                } catch { }
            }
        }
        $zip.Dispose()
    } catch { }
    return @{ Entries = $entryNames; ClassBytes = $classBytes; NestedEntries = $nestedNames; ZipEntries = $zipEntriesList }
}

function Start-DeepBytecodeScan {
    param($ArchiveData)
    $flags = [System.Collections.Generic.List[string]]::new()
    $totalClasses = 0
    $totalResources = 0

    foreach ($k in $ArchiveData.ClassBytes.Keys) {
        if ($k.EndsWith(".class") -and -not $k.StartsWith("NESTED:")) { $totalClasses++ }
        if (-not $k.EndsWith(".class") -and -not $k.Contains("META-INF") -and -not $k.EndsWith(".json") -and -not $k.EndsWith(".toml") -and -not $k.EndsWith(".info") -and -not $k.StartsWith("NESTED:")) {
            $totalResources++
            $raw = $ArchiveData.ClassBytes[$k]
            if ($raw.Length -ge 4) {
                if ($raw[0] -eq 0xCA -and $raw[1] -eq 0xFE -and $raw[2] -eq 0xBA -and $raw[3] -eq 0xBE) {
                    [void]$flags.Add("Hidden Java bytecode (.class) disguised inside resource: $k")
                }
                if ($raw[0] -eq 0x50 -and $raw[1] -eq 0x4B -and $raw[2] -eq 0x03 -and $raw[3] -eq 0x04) {
                    [void]$flags.Add("Hidden embedded ZIP/JAR container disguised inside resource: $k")
                }
                if ($raw[0] -eq 0x4D -and $raw[1] -eq 0x5A) {
                    [void]$flags.Add("Hidden native PE executable disguised inside resource: $k")
                }
            }
            if ($k.StartsWith("assets/minecraft/shaders/") -or $k.StartsWith("assets/minecraft/textures/") -or $k.StartsWith("assets/minecraft/sounds/") -or $k.StartsWith("assets/minecraft/font/") -or $k.StartsWith("assets/minecraft/models/")) {
                if ($k.EndsWith(".class") -or $k.EndsWith(".jar") -or $k.EndsWith(".dll") -or $k.EndsWith(".exe") -or $k.EndsWith(".vbs") -or $k.EndsWith(".bat")) {
                    [void]$flags.Add("Disguised executable binary inside vanilla asset directory: $k")
                }
                if ($raw.Length -gt 500) {
                    $ent = [FastScanner]::CalcEntropy($raw)
                    $isHeaderValid = ($raw[0] -eq 0x89 -and $raw[1] -eq 0x50) -or ($raw[0] -eq 0x4F -and $raw[1] -eq 0x67) -or ($raw[0] -eq 0xFF -and $raw[1] -eq 0xD8)
                    if ($ent -gt 7.5 -and -not $isHeaderValid) {
                        [void]$flags.Add("Encrypted payload blob inside asset directory: $k (Entropy: $ent)")
                    }
                }
            }
        }
    }

    $hasMetadata = $false
    foreach ($k in $ArchiveData.ClassBytes.Keys) {
        if ($k.EndsWith("fabric.mod.json") -or $k.EndsWith("quilt.mod.json") -or $k.EndsWith("mods.toml") -or $k.EndsWith("mcmod.info")) { $hasMetadata = $true; break }
    }
    if ($totalClasses -gt 50 -and -not $hasMetadata) {
        [void]$flags.Add("Unregistered raw class payload — No mod loader metadata descriptor found ($totalClasses classes)")
    }

    return $flags
}

function Read-ConstantPool {
    param([byte[]]$Raw)
    return [FastScanner]::ParseConstantPool($Raw)
}

function Find-EncodedContent {
    param([string[]]$PoolStrings)
    $hits = [System.Collections.Generic.List[string]]::new()
    foreach ($s in $PoolStrings) {
        if ($s.Length -ge 24 -and $s -match '^[A-Za-z0-9+/]{24,}={0,2}$') {
            try {
                $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($s))
                foreach ($kw in $script:contentLookup) {
                    if ($decoded.Contains($kw)) { [void]$hits.Add($kw); break }
                }
                if ($decoded.Contains("discord.gg/") -or $decoded.Contains("webhook") -or $decoded.Contains("api.novaclient") -or $decoded.Contains("novoware.eu") -or $decoded.Contains("hellclient.eu") -or $decoded.Contains("/loader")) {
                    [void]$hits.Add("Encoded C2 / Webhook / Loader URL")
                }
            } catch { }
        }
        if ($s.Length -ge 20 -and $s -match '^([0-9a-fA-F]{2}){10,}$') {
            try {
                $bytes = [byte[]]::new($s.Length / 2)
                for ($j = 0; $j -lt $s.Length; $j += 2) { $bytes[$j/2] = [Convert]::ToByte($s.Substring($j,2), 16) }
                $decoded = [System.Text.Encoding]::UTF8.GetString($bytes)
                foreach ($kw in $script:contentLookup) {
                    if ($decoded.Contains($kw)) { [void]$hits.Add($kw); break }
                }
            } catch { }
        }
    }
    return $hits
}

function Test-ReflectionUsage {
    param([string[]]$PoolStrings)
    $count = 0
    foreach ($s in $PoolStrings) {
        foreach ($r in $script:reflectionIndicators) {
            if ($s.Contains($r)) { $count++; break }
        }
    }
    return $count
}

function Resolve-OriginMetadata {
    param([string]$FilePath, $ArchiveData)
    $info = @{
        SourceHost = "Local / Direct"
        ExactUrl = ""
        Referrer = ""
        IsCheatOrigin = $false
        IsDiscordOrigin = $false
        InternalUrls = [System.Collections.Generic.List[string]]::new()
    }

    $adsData = Test-AlternateDataStreams -FilePath $FilePath
    if ($adsData.HostUrl) {
        $info.ExactUrl = $adsData.HostUrl
        $info.Referrer = $adsData.ReferrerUrl
        $info.IsCheatOrigin = $adsData.IsCheatOrigin
        $info.IsDiscordOrigin = $adsData.IsDiscordOrigin

        $u = $info.ExactUrl
        if ($u.Contains("modrinth.com")) { $info.SourceHost = "Modrinth" }
        elseif ($u.Contains("curseforge.com")) { $info.SourceHost = "CurseForge" }
        elseif ($u.Contains("github.com")) { $info.SourceHost = "GitHub" }
        elseif ($u.Contains("mediafire.com")) { $info.SourceHost = "MediaFire" }
        elseif ($u.Contains("discord.com") -or $u.Contains("discordapp.com")) { $info.SourceHost = "Discord" }
        elseif ($u.Contains("dropbox.com")) { $info.SourceHost = "Dropbox" }
        elseif ($u.Contains("drive.google.com")) { $info.SourceHost = "Google Drive" }
        elseif ($u.Contains("mega.nz") -or $u.Contains("mega.co.nz")) { $info.SourceHost = "MEGA" }
        elseif ($u -match 'https?://(?:www\.)?([^/]+)') { $info.SourceHost = $matches[1] }
        else { $info.SourceHost = $u }
    }

    foreach ($key in $ArchiveData.ClassBytes.Keys) {
        if ($key.EndsWith("MANIFEST.MF")) {
            $mf = [System.Text.Encoding]::UTF8.GetString($ArchiveData.ClassBytes[$key])
            if ($mf -match '(?:Implementation-URL|Specification-URL|Repository):\s*(.+)') {
                [void]$info.InternalUrls.Add($matches[1].Trim())
            }
        }
        if ($key.EndsWith("fabric.mod.json")) {
            try {
                $fjson = [System.Text.Encoding]::UTF8.GetString($ArchiveData.ClassBytes[$key]).Trim([char]0xFEFF) | ConvertFrom-Json
                if ($fjson.contact) {
                    if ($fjson.contact.homepage) { [void]$info.InternalUrls.Add($fjson.contact.homepage) }
                    if ($fjson.contact.sources) { [void]$info.InternalUrls.Add($fjson.contact.sources) }
                }
            } catch { }
        }
        if ($key.EndsWith("quilt.mod.json")) {
            try {
                $qjson = [System.Text.Encoding]::UTF8.GetString($ArchiveData.ClassBytes[$key]).Trim([char]0xFEFF) | ConvertFrom-Json
                if ($qjson.quilt_loader -and $qjson.quilt_loader.metadata -and $qjson.quilt_loader.metadata.contact) {
                    if ($qjson.quilt_loader.metadata.contact.homepage) { [void]$info.InternalUrls.Add($qjson.quilt_loader.metadata.contact.homepage) }
                    if ($qjson.quilt_loader.metadata.contact.sources) { [void]$info.InternalUrls.Add($qjson.quilt_loader.metadata.contact.sources) }
                }
            } catch { }
        }
        if ($key.EndsWith("mods.toml") -or $key.EndsWith("neoforge.mods.toml")) {
            $toml = [System.Text.Encoding]::UTF8.GetString($ArchiveData.ClassBytes[$key])
            if ($toml -match 'displayURL\s*=\s*"([^"]+)"') { [void]$info.InternalUrls.Add($matches[1]) }
        }
    }

    return $info
}

function Get-ModIdentity {
    param($ArchiveData)
    $identity = @{ ModId = ""; Name = ""; Version = ""; Loader = "unknown"; JavaMajor = 0 }
    
    if ($ArchiveData.ClassBytes.ContainsKey("fabric.mod.json")) {
        try {
            $data = [System.Text.Encoding]::UTF8.GetString($ArchiveData.ClassBytes["fabric.mod.json"]).Trim([char]0xFEFF) | ConvertFrom-Json
            $identity.ModId = [string]$data.id
            $identity.Name = if ($data.name) { [string]$data.name } else { [string]$data.id }
            $identity.Version = [string]$data.version
            $identity.Loader = "Fabric"
            return $identity
        } catch { }
    }
    if ($ArchiveData.ClassBytes.ContainsKey("quilt.mod.json")) {
        try {
            $data = [System.Text.Encoding]::UTF8.GetString($ArchiveData.ClassBytes["quilt.mod.json"]).Trim([char]0xFEFF) | ConvertFrom-Json
            if ($data.quilt_loader) {
                $identity.ModId = [string]$data.quilt_loader.id
                $identity.Name = if ($data.quilt_loader.metadata -and $data.quilt_loader.metadata.name) { [string]$data.quilt_loader.metadata.name } else { [string]$data.quilt_loader.id }
                $identity.Version = if ($data.quilt_loader.metadata -and $data.quilt_loader.metadata.version) { [string]$data.quilt_loader.metadata.version } else { "" }
                $identity.Loader = "Quilt"
                return $identity
            }
        } catch { }
    }
    if ($ArchiveData.ClassBytes.ContainsKey("META-INF/neoforge.mods.toml")) {
        try {
            $text = [System.Text.Encoding]::UTF8.GetString($ArchiveData.ClassBytes["META-INF/neoforge.mods.toml"])
            $identity.Loader = "NeoForge"
            if ($text -match 'modId\s*=\s*"([^"]+)"') { $identity.ModId = $matches[1] }
            if ($text -match 'displayName\s*=\s*"([^"]+)"') { $identity.Name = $matches[1] }
            if ($text -match 'version\s*=\s*"([^"]+)"') { $identity.Version = $matches[1] }
            return $identity
        } catch { }
    }
    if ($ArchiveData.ClassBytes.ContainsKey("META-INF/mods.toml")) {
        try {
            $text = [System.Text.Encoding]::UTF8.GetString($ArchiveData.ClassBytes["META-INF/mods.toml"])
            $identity.Loader = "Forge"
            if ($text -match 'modId\s*=\s*"([^"]+)"') { $identity.ModId = $matches[1] }
            if ($text -match 'displayName\s*=\s*"([^"]+)"') { $identity.Name = $matches[1] }
            if ($text -match 'version\s*=\s*"([^"]+)"') { $identity.Version = $matches[1] }
            return $identity
        } catch { }
    }
    if ($ArchiveData.ClassBytes.ContainsKey("mcmod.info")) {
        try {
            $data = [System.Text.Encoding]::UTF8.GetString($ArchiveData.ClassBytes["mcmod.info"]).Trim([char]0xFEFF) | ConvertFrom-Json
            $identity.Loader = "Forge-Legacy"
            if ($data[0]) {
                $identity.ModId = [string]$data[0].modid
                $identity.Name = [string]$data[0].name
                $identity.Version = [string]$data[0].version
                return $identity
            }
        } catch { }
    }

    foreach ($key in $ArchiveData.ClassBytes.Keys) {
        if ($key.EndsWith("fabric.mod.json") -and -not $identity.ModId) {
            try {
                $data = [System.Text.Encoding]::UTF8.GetString($ArchiveData.ClassBytes[$key]).Trim([char]0xFEFF) | ConvertFrom-Json
                $identity.ModId = [string]$data.id
                $identity.Name = if ($data.name) { [string]$data.name } else { [string]$data.id }
                $identity.Version = [string]$data.version
                $identity.Loader = "Fabric"
            } catch { }
        }
        if ($key.EndsWith("mcmod.info") -and -not $identity.ModId) {
            try {
                $data = [System.Text.Encoding]::UTF8.GetString($ArchiveData.ClassBytes[$key]).Trim([char]0xFEFF) | ConvertFrom-Json
                $identity.Loader = "Forge-Legacy"
                if ($data[0]) {
                    $identity.ModId = [string]$data[0].modid
                    $identity.Name = [string]$data[0].name
                    $identity.Version = [string]$data[0].version
                }
            } catch { }
        }
    }
    return $identity
}

function Test-ModSpoofing {
    param([string]$FileName, $ModIdentity, $ArchiveData)
    $flags = [System.Collections.Generic.List[string]]::new()
    if (-not $ModIdentity -or [string]::IsNullOrWhiteSpace($ModIdentity.ModId)) { return $flags }
    
    $fnLower = $FileName.ToLower()
    foreach ($name in $script:knownModIdentities.Keys) {
        if ($fnLower.StartsWith($name + "-") -or $fnLower.StartsWith($name + "_") -or $fnLower.StartsWith($name + "+") -or $fnLower -eq ($name + ".jar")) {
            $expected = $script:knownModIdentities[$name]
            $actual = $ModIdentity.ModId.ToLower()
            $expId = $expected.id.ToLower()
            if ($actual -ne $expId -and -not $actual.StartsWith($expId) -and -not $expId.StartsWith($actual)) {
                [void]$flags.Add("Identity spoofing — File claims '$name' but internal mod ID is '$($ModIdentity.ModId)'")
            }
        }
    }
    return $flags
}

function Start-PatternAnalysis {
    param($ArchiveData, [string]$FilePath)

    $foundPatterns  = [System.Collections.Generic.HashSet[string]]::new()
    $foundMacros    = [System.Collections.Generic.HashSet[string]]::new()
    $foundStrings   = [System.Collections.Generic.HashSet[string]]::new()
    $foundFullwidth = [System.Collections.Generic.HashSet[string]]::new()
    $encodedHits    = [System.Collections.Generic.HashSet[string]]::new()
    $highEntropyCount = 0
    $reflectionScore  = 0
    $selfDestructFlags = [System.Collections.Generic.HashSet[string]]::new()
    $combinedHeuristics = [System.Collections.Generic.Dictionary[string, bool]]::new()

    foreach ($entry in $ArchiveData.Entries) {
        [FastScanner]::ScanEntryName($entry, $foundPatterns, $foundMacros)
    }
    foreach ($entry in $ArchiveData.NestedEntries) {
        [FastScanner]::ScanEntryName($entry, $foundPatterns, $foundMacros)
    }

    $targetedCoreMixinCount = 0

    foreach ($key in $ArchiveData.ClassBytes.Keys) {
        $bytes = $ArchiveData.ClassBytes[$key]

        if ($key.Contains("mixin") -and $key.EndsWith(".json")) {
            $ascii = [System.Text.Encoding]::ASCII.GetString($bytes)
            if ($ascii.Contains("ClientPlayerEntity")) { $targetedCoreMixinCount++ }
            if ($ascii.Contains("ClientPlayNetworkHandler")) { $targetedCoreMixinCount++ }
            if ($ascii.Contains("ClientConnection")) { $targetedCoreMixinCount++ }
            if ($ascii.Contains("ClientPlayerInteractionManager")) { $targetedCoreMixinCount++ }
            if ($ascii.Contains("GameRenderer")) { $targetedCoreMixinCount++ }
            if ($ascii.Contains("InGameHud")) { $targetedCoreMixinCount++ }
            if ($ascii.Contains("Keyboard") -or $ascii.Contains("Mouse")) { $targetedCoreMixinCount++ }
        }

        if ($key.EndsWith(".class")) {
            [FastScanner]::ScanClassComprehensive(
                $bytes,
                $foundPatterns,
                $foundMacros,
                $foundStrings,
                $foundFullwidth,
                $encodedHits,
                [ref]$reflectionScore,
                [ref]$highEntropyCount,
                $combinedHeuristics
            )
        }
    }

    $heuristicScore = 0
    if ($combinedHeuristics.ContainsKey("SilentAim")) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Silent Aim / Rotations Desync") }
    if ($combinedHeuristics.ContainsKey("CrystalMath")) { $heuristicScore += 15; [void]$foundStrings.Add("Heuristic: Crystal & Anchor Damage Calculator") }
    if ($combinedHeuristics.ContainsKey("VelocitySpoof")) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Velocity Cancellation / Knockback Spoof") }
    if ($combinedHeuristics.ContainsKey("ScaffoldMath")) { $heuristicScore += 5; [void]$foundStrings.Add("Heuristic: Auto-Raycast Scaffold Logic") }
    if ($combinedHeuristics.ContainsKey("NettyIntercept")) { $heuristicScore += 8; [void]$foundStrings.Add("Heuristic: Custom Netty Channel Pipeline Interception") }
    if ($combinedHeuristics.ContainsKey("GLFWInputHook")) { $heuristicScore += 5; [void]$foundStrings.Add("Heuristic: Direct GLFW / JNativeHook Input Capture") }
    if ($combinedHeuristics.ContainsKey("ReachHitbox")) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Reach Expansion & Extended Bounding Box Math") }
    if ($combinedHeuristics.ContainsKey("AutoClicker")) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Randomized CPS Distribution & Click Dispatch") }
    if ($combinedHeuristics.ContainsKey("TriggerBot")) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Autonomous Crosshair Raycast TriggerBot") }
    if ($combinedHeuristics.ContainsKey("AutoTotem")) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Autonomous Totem Inventory Slot Swapper") }
    if ($combinedHeuristics.ContainsKey("FastPlace")) { $heuristicScore += 8; [void]$foundStrings.Add("Heuristic: Attack & Placement Cooldown Manipulation") }
    if ($combinedHeuristics.ContainsKey("PacketMine")) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Zero-Tick Packet Mine Destroy Sequence") }
    if ($combinedHeuristics.ContainsKey("NoFall")) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Ground Status Spoofing / NoFall Logic") }
    if ($combinedHeuristics.ContainsKey("Blink")) { $heuristicScore += 8; [void]$foundStrings.Add("Heuristic: Packet Buffering Queue / Blink Logic") }
    if ($combinedHeuristics.ContainsKey("AutoPot")) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Auto Potion Throw & Slot Restore Sequence") }
    if ($combinedHeuristics.ContainsKey("Backtrack")) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Entity History Tracking & Backtrack Buffer") }
    if ($combinedHeuristics.ContainsKey("WebhookExfil")) { $heuristicScore += 15; [void]$foundStrings.Add("Heuristic: Remote Webhook & C2 Exfiltration Endpoint") }
    if ($combinedHeuristics.ContainsKey("MemoryScrub")) { $heuristicScore += 12; [void]$foundStrings.Add("Heuristic: Direct JVM Native Memory Manipulation") }
    if ($combinedHeuristics.ContainsKey("FreeLook")) { $heuristicScore += 8; [void]$foundStrings.Add("Heuristic: FreeLook / Decoupled Camera Perspective Matrix") }
    if ($combinedHeuristics.ContainsKey("AutoWeb")) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Autonomous Cobweb Placement & Target Trap Logic") }
    if ($combinedHeuristics.ContainsKey("AutoMace")) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Kinetic Fall-Damage Mace & Spear Weapon Switcher") }
    if ($combinedHeuristics.ContainsKey("CriticalsDesync")) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Packet-Level Mini-Hop Critical Hit Generator") }
    if ($combinedHeuristics.ContainsKey("FastBow")) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Truncated Bow Charge & Rapid Arrow Spammer") }
    if ($combinedHeuristics.ContainsKey("SpinBot")) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Anti-Aim Pseudo-Random SpinBot Packet Generator") }
    if ($combinedHeuristics.ContainsKey("AutoAnchor")) { $heuristicScore += 12; [void]$foundStrings.Add("Heuristic: Synchronized Auto-Anchor & Glowstone Charge State Machine") }
    if ($combinedHeuristics.ContainsKey("HitboxOverride")) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: EntityRenderer Bounding Box Override & Hitbox Expansion") }
    if ($combinedHeuristics.ContainsKey("AutoSurround")) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Multi-Directional Self-Trap & Surround Placement Array") }
    if ($combinedHeuristics.ContainsKey("AutoCity")) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Auto-City Surround Obsidian Scanning & Zero-Tick Destructor") }
    if ($combinedHeuristics.ContainsKey("AutoArmor")) { $heuristicScore += 8; [void]$foundStrings.Add("Heuristic: Dynamic Protection Evaluation & Auto-Armor Slot Assignment") }
    if ($combinedHeuristics.ContainsKey("AutoEat")) { $heuristicScore += 8; [void]$foundStrings.Add("Heuristic: Autonomous Health Threshold Gapple & Consumption Routine") }
    if ($combinedHeuristics.ContainsKey("AntiKB")) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Knockback Velocity Horizontal Component Zeroing Multiplication") }
    if ($combinedHeuristics.ContainsKey("ElytraFly")) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Elytra Packet Angle Spoofing & Pitch Decoupling Loop") }
    if ($combinedHeuristics.ContainsKey("FastLadder")) { $heuristicScore += 8; [void]$foundStrings.Add("Heuristic: Climbable Block Velocity Injection & Step Height Manipulation") }
    if ($combinedHeuristics.ContainsKey("BoatFly")) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Vehicle Mount Packet Interception & Airborne Hijack Engine") }
    if ($combinedHeuristics.ContainsKey("NoSlowdown")) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Mixin Item-Use Speed Penalty Neutralizer (NoSlowdown)") }
    if ($combinedHeuristics.ContainsKey("TargetStrafe")) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Mathematical Orbit Calculation & Autonomous Circle Strafe Engine") }
    if ($combinedHeuristics.ContainsKey("SafeWalk")) { $heuristicScore += 8; [void]$foundStrings.Add("Heuristic: Ground Edge Raycast & Border Fall Prevention (SafeWalk)") }
    if ($combinedHeuristics.ContainsKey("FakeInvScreen")) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Handled Screen C2S Packet Suppression (Inventory Walk Bypass)") }
    if ($combinedHeuristics.ContainsKey("XRay")) { $heuristicScore += 12; [void]$foundStrings.Add("Heuristic: Block Occlusion & Transparency Force Overwrite (XRay Engine)") }
    if ($combinedHeuristics.ContainsKey("AutoTotemDesync")) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Instantaneous Offhand Totem Slot Replenishment Algorithm") }
    if ($combinedHeuristics.ContainsKey("AntiBlindness")) { $heuristicScore += 8; [void]$foundStrings.Add("Heuristic: Negative Potion Effect Interception & Status Stripping") }
    if ($combinedHeuristics.ContainsKey("FastBowTruncated")) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Truncated Bow Charge Duration & Fast-Release Trigger") }
    if ($combinedHeuristics.ContainsKey("AntiAimRandom")) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Pseudo-Random Movement Packet Angle Scrambler (Anti-Aim)") }

    if ($combinedHeuristics.ContainsKey("SelfDestruct_Cmd")) {
        if ($combinedHeuristics.ContainsKey("SelfDestruct_Exit")) {
            [void]$selfDestructFlags.Add("Shell-based file deletion with JVM deleteOnExit lifecycle hook")
        }
        if ($combinedHeuristics.ContainsKey("SelfDestruct_Hook")) {
            [void]$selfDestructFlags.Add("Shell command deletion paired with JVM shutdown hook")
        }
    }
    if ($combinedHeuristics.ContainsKey("SelfDestruct_Exit") -and $combinedHeuristics.ContainsKey("SelfDestruct_Hook") -and $combinedHeuristics.ContainsKey("SelfDestruct_Cmd")) {
        [void]$selfDestructFlags.Add("JVM shutdown hook registered with shell deletion command")
    }

    if ($targetedCoreMixinCount -ge 4) { $heuristicScore += 12; [void]$foundStrings.Add("Heuristic: High Density Combat/Network Mixin Clustering ($targetedCoreMixinCount targets)") }

    $fwCheatPool = $script:fwCheatPool
    $resolvedFullwidth = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($fw in @($foundFullwidth)) {
        if ($fw.Length -lt 3) { continue }
        $bestMatch = $null
        foreach ($cs in $fwCheatPool) {
            if ($cs.Contains($fw)) {
                if ($null -eq $bestMatch -or $cs.Length -lt $bestMatch.Length) { $bestMatch = $cs }
            }
        }
        if ($null -ne $bestMatch) { [void]$resolvedFullwidth.Add($bestMatch) }
        elseif ($fw.Length -ge 6) { [void]$resolvedFullwidth.Add($fw) }
    }
    $resolved = @($resolvedFullwidth)
    $finalFullwidth = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($fw in $resolved) {
        $isRedundant = $false
        foreach ($other in $resolved) {
            if ($fw.Length -lt $other.Length -and $other.Contains($fw)) { $isRedundant = $true; break }
        }
        if (-not $isRedundant) { [void]$finalFullwidth.Add($fw) }
    }

    $archResult = Test-CheatArchitecture -ArchiveData $ArchiveData
    $mixinResult = Get-MixinTargetProfile -ArchiveData $ArchiveData

    $totalConfidenceScore = $heuristicScore + $archResult.Score
    if ($mixinResult.IsSuspiciousCluster) {
        $totalConfidenceScore += 25
        [void]$foundStrings.Add("Structural: Suspicious Cross-System Mixin Cluster ($($mixinResult.HitCount) subsystems)")
    }

    return @{
        Patterns          = [System.Collections.Generic.List[string]]::new([string[]]$foundPatterns)
        Macros            = [System.Collections.Generic.List[string]]::new([string[]]$foundMacros)
        FlaggedStrings    = [System.Collections.Generic.List[string]]::new([string[]]$foundStrings)
        FullwidthStrings  = [System.Collections.Generic.List[string]]::new([string[]]$finalFullwidth)
        EncodedHits       = [System.Collections.Generic.List[string]]::new([string[]]$encodedHits)
        HighEntropyCount  = $highEntropyCount
        ReflectionScore   = $reflectionScore
        ConfidenceScore   = $totalConfidenceScore
        SelfDestructFlags = [System.Collections.Generic.List[string]]::new([string[]]$selfDestructFlags)
    }
}

function Start-InjectionAnalysis {
    param($ArchiveData, [string]$FilePath)
    $flags = [System.Collections.Generic.List[string]]::new()

    $nestedJarNames = [System.Collections.Generic.List[string]]::new()
    foreach ($e in $ArchiveData.Entries) {
        if ($e.StartsWith("META-INF/jars/") -or $e.StartsWith("assets/") -or $e.StartsWith("data/") -or $e.StartsWith("resources/") -or $e.StartsWith("META-INF/libraries/")) {
            if ($e.EndsWith(".jar")) { [void]$nestedJarNames.Add($e) }
        }
    }

    $outerClassCount = 0
    foreach ($e in $ArchiveData.Entries) {
        if ($e.EndsWith(".class") -and -not $e.Contains("/")) { $outerClassCount++ }
    }

    $hasFabricJiJ = $false
    foreach ($key in $ArchiveData.ClassBytes.Keys) {
        if ($key.EndsWith("fabric.mod.json")) {
            try {
                $fjson = [System.Text.Encoding]::UTF8.GetString($ArchiveData.ClassBytes[$key]).Trim([char]0xFEFF) | ConvertFrom-Json
                if ($fjson.jars -and $fjson.jars.Count -gt 0) { $hasFabricJiJ = $true }
            } catch { }
        }
    }
    if ($nestedJarNames.Count -ge 1 -and -not $hasFabricJiJ) {
        [void]$flags.Add("Hollow loader shell — Wraps nested payload: $($nestedJarNames[0])")
    }

    $instrumentationFound = $false; $memoryPatchFound = $false; $remoteClassLoadFound = $false
    $nativeLoadFound = $false; $namedPipeFound = $false; $dynamicAsmFound = $false
    $processInjectFound = $false; $inputSimFound = $false; $clipboardExfilFound = $false
    $screenCaptureFound = $false; $fileScanFound = $false; $socketBackdoorFound = $false
    $runtimeExecFound = $false; $dynamicAttachFound = $false

    foreach ($key in $ArchiveData.ClassBytes.Keys) {
        if ($key.EndsWith(".class")) {
            $ct = [System.Text.Encoding]::ASCII.GetString($ArchiveData.ClassBytes[$key])
            if ($ct.Contains("java/lang/instrument/Instrumentation") -and ($ct.Contains("redefineClasses") -or $ct.Contains("retransformClasses") -or $ct.Contains("appendToBootstrapClassLoaderSearch"))) {
                $instrumentationFound = $true
            }
            if (($ct.Contains("sun/misc/Unsafe") -or $ct.Contains("jdk/internal/misc/Unsafe")) -and ($ct.Contains("putAddress") -or $ct.Contains("defineAnonymousClass"))) {
                if (-not $ct.Contains("org/lwjgl") -and -not $ct.Contains("com/mojang/blaze3d") -and -not $ct.Contains("net/caffeinemc") -and -not $ct.Contains("me/jellysquid") -and -not $ct.Contains("org/embeddedt") -and -not $ct.Contains("it/unimi/dsi")) {
                    $memoryPatchFound = $true
                }
            }
            if (($ct.Contains("URLClassLoader") -or $ct.Contains("ClassLoader")) -and ($ct.Contains("addURL") -or $ct.Contains("defineClass") -or $ct.Contains("loadClass"))) {
                if (($ct.Contains("URLClassLoader") -or $ct.Contains("defineClass")) -and -not $ct.Contains("net/fabricmc") -and -not $ct.Contains("org/objectweb/asm") -and -not $ct.Contains("net/caffeinemc") -and -not $ct.Contains("me/jellysquid") -and -not $ct.Contains("me/steinborn") -and -not $ct.Contains("malte0811") -and -not $ct.Contains("org/anti_ad") -and -not $ct.Contains("org/spongepowered/asm")) { $remoteClassLoadFound = $true }
            }
            if (($ct.Contains("System.loadLibrary") -or $ct.Contains("System.load") -or $ct.Contains("Runtime.load")) -and ($ct.Contains(".dll") -or $ct.Contains(".so") -or $ct.Contains(".dylib") -or $ct.Contains("kernel32") -or $ct.Contains("user32"))) {
                $nativeLoadFound = $true
            }
            if ($ct.Contains('\\.\pipe\') -or $ct.Contains("NamedPipeServerStream") -or $ct.Contains("NamedPipeClientStream")) {
                $namedPipeFound = $true
            }
            if (($ct.Contains("org/objectweb/asm/ClassWriter") -or $ct.Contains("javassist/ClassPool") -or $ct.Contains("net/bytebuddy")) -and $ct.Contains("defineClass")) {
                if (-not $ct.Contains("net/fabricmc") -and -not $ct.Contains("net/neoforged") -and -not $ct.Contains("net/minecraftforge") -and -not $ct.Contains("net/caffeinemc")) {
                    $dynamicAsmFound = $true
                }
            }
            if ($ct.Contains("kernel32.dll") -or ($ct.Contains("kernel32") -and ($ct.Contains("VirtualAlloc") -or $ct.Contains("WriteProcessMemory") -or $ct.Contains("CreateRemoteThread") -or $ct.Contains("OpenProcess")))) {
                $processInjectFound = $true
            }
            if ($ct.Contains("user32.dll") -or ($ct.Contains("user32") -and ($ct.Contains("SendInput") -or $ct.Contains("keybd_event") -or $ct.Contains("mouse_event") -or $ct.Contains("GetAsyncKeyState")))) {
                $inputSimFound = $true
            }
            if ($ct.Contains("getSystemClipboard") -and ($ct.Contains("getContents") -or $ct.Contains("setContents"))) {
                $clipboardExfilFound = $true
            }
            if ($ct.Contains("java/awt/Robot") -and ($ct.Contains("createScreenCapture") -or $ct.Contains("getPixelColor"))) {
                $screenCaptureFound = $true
            }
            if ($ct.Contains("java/io/File") -and $ct.Contains("listFiles") -and ($ct.Contains("Desktop") -or $ct.Contains("Downloads") -or $ct.Contains("AppData") -or $ct.Contains(".minecraft"))) {
                $fileScanFound = $true
            }
            if ($ct.Contains("java/net/ServerSocket") -and $ct.Contains("accept")) {
                $socketBackdoorFound = $true
            }
            if ($ct.Contains("java/lang/Runtime") -and $ct.Contains("exec") -and ($ct.Contains("cmd") -or $ct.Contains("powershell") -or $ct.Contains("bash") -or $ct.Contains("curl") -or $ct.Contains("certutil"))) {
                $runtimeExecFound = $true
            }
            if ($ct.Contains("com/sun/tools/attach/VirtualMachine") -and $ct.Contains("attach")) {
                $dynamicAttachFound = $true
            }
        }
        if ($key.EndsWith("MANIFEST.MF")) {
            $mfText = [System.Text.Encoding]::UTF8.GetString($ArchiveData.ClassBytes[$key])
            if ($mfText -match '(Premain-Class|Agent-Class|Launcher-Agent-Class):\s*(.+)') {
                [void]$flags.Add("JAR manifest embeds Java Agent entrypoint: $($matches[1]) ($($matches[2].Trim()))")
            }
            if ($mfText -match 'Can-Redefine-Classes:\s*true|Can-Retransform-Classes:\s*true') {
                [void]$flags.Add("JAR manifest requests dynamic class redefinition capabilities")
            }
            if ($mfText -match 'Boot-Class-Path:\s*(.+)') {
                [void]$flags.Add("JAR manifest modifies JVM bootstrap classpath: $($matches[1].Trim())")
            }
        }
    }

    if ($instrumentationFound) { [void]$flags.Add("JVM Runtime Agent — Dynamic bytecode redefinition hook detected") }
    if ($memoryPatchFound) { [void]$flags.Add("Direct Native Memory Patching — Unsafe memory pointer manipulation detected") }
    if ($remoteClassLoadFound) { [void]$flags.Add("Remote Class Loader — Dynamic remote JAR/Class loader detected") }
    if ($nativeLoadFound) { [void]$flags.Add("Native JNI Bridge — Embedded native binary loader hook detected") }
    if ($namedPipeFound) { [void]$flags.Add("External IPC Bridge — Windows Named Pipe cross-process communication channel") }
    if ($dynamicAsmFound) { [void]$flags.Add("Dynamic Bytecode Transformer — In-memory ASM/Javassist class synthesizer") }
    if ($processInjectFound) { [void]$flags.Add("Windows API Process Injection — Cross-process memory manipulation") }
    if ($inputSimFound) { [void]$flags.Add("Windows API Input Simulation — OS-level simulated hardware keystrokes") }
    if ($clipboardExfilFound) { [void]$flags.Add("Clipboard Data Access — Programmatic clipboard exfiltration hook") }
    if ($screenCaptureFound) { [void]$flags.Add("Screen Capture API — Automated background screenshot capability") }
    if ($fileScanFound) { [void]$flags.Add("User Directory Enumeration — Scanning personal user directories") }
    if ($socketBackdoorFound) { [void]$flags.Add("Local Network Listener — ServerSocket backdoor listener") }
    if ($runtimeExecFound) { [void]$flags.Add("System Command Execution — Shell process spawning via Runtime.exec") }
    if ($dynamicAttachFound) { [void]$flags.Add("JVM Dynamic Attach — com.sun.tools.attach process injector") }

    return $flags
}

function Start-StructureAnalysis {
    param($ArchiveData, [string]$FilePath)
    $flags = [System.Collections.Generic.List[string]]::new()

    $totalClass = 0; $numericCount = 0; $unicodeCount = 0
    $fullwidthCount = 0; $japaneseCount = 0; $singleLetterCount = 0
    $unprintableCount = 0; $cyrillicCount = 0; $shortPackageCount = 0
    $vowellessCount = 0; $rootClassCount = 0
    $contentSample = [System.Text.StringBuilder]::new()
    $sampleSize = 0

    $cheatObfuscators = @{
        "Skidfuscator"   = @("dev/skidfuscator", "Skidfuscator", "skidfuscator.dev", "skidfuscator.config")
        "Paramorphism"   = @("Paramorphism", "paramorphism-", "dev/paramorphism", "paramorphism-runtime")
        "Radon"          = @("ItzSomebody/Radon", "me/itzsomebody/radon")
        "Caesium"        = @("sim0n/Caesium", "dev/sim0n/caesium")
        "Bozar"          = @("vimasig/Bozar", "com/bozar", "bozar.repack", "bozar.transform")
        "Branchlock"     = @("Branchlock", "branchlock.dev", "com/branchlock", "branchlock.config")
        "Binscure"       = @("Binscure", "com/binscure")
        "SuperBlaubeere" = @("superblaubeere", "superblaubeere27")
        "Qprotect"       = @("Qprotect", "QProtect", "mdma.dev/qprotect")
        "Zelix"          = @("ZKMFLOW", "ZelixKlassMaster")
        "Stringer"       = @("StringerJavaObfuscator", "com/licel/stringer")
        "JNIC"           = @("JNIC", "jnic.obf", "jnic-obfuscator", "JNIC_Loader", "jnic.native")
        "Smoke"          = @("SmokeObf", "smoke.obf")
        "KryptonObf"     = @("KryptonObfuscator", "krypton.native", "KryptonLoader")
        "RosePad"        = @("rosepad.dev", "roseobf", "RoseLoader", "rosepad.config")
        "CleanroomObf"   = @("cleanroom/obf", "cleanroom.obfuscator", "CleanroomTransform")
        "Prometeo"       = @("PrometeoObfuscator", "prometeo")
        "Allatori"       = @("AllatoriDemo", "com/allatori")
        "DashO"          = @("PreEmptive", "com/preemptive")
        "NeonObf"        = @("NeonObfuscator", "neonobf")
        "Obzcure"        = @("Obzcure", "obzcure")
        "ClassGuard"     = @("ClassGuard", "classguard")
        "JJobf"          = @("JJobf", "JObf", "jobf")
        "Scuti"          = @("Scuti", "scuti")
        "AntiDump"       = @("AntiDump", "antidump", "AntiAgentLoader", "antiattach.hook")
        "yGuard"         = @("yworks/yguard")
        "SandMark"       = @("sandmark", "SandMark", "sandmark.v3")
        "ProGuard"       = @("proguard/obfuscate", "ProGuard")
        "DexGuard"       = @("dexguard", "DexGuard")
        "RetroGuard"     = @("retroguard", "RetroGuard")
        "Avaj"           = @("avaj.obf", "AvajObfuscator")
        "JavaGuard"      = @("javaguard", "JavaGuard")
        "Recaf"          = @("me/coley/recaf", "Recaf")
        "BytecodeViewer" = @("the/bytecode/club", "BytecodeViewer")
    }

    $allNames = [System.Collections.Generic.List[string]]::new()
    foreach ($e in $ArchiveData.Entries) { [void]$allNames.Add($e) }
    foreach ($e in $ArchiveData.NestedEntries) { [void]$allNames.Add($e) }

    foreach ($name in $allNames) {
        if ($name.EndsWith(".class")) {
            $totalClass++
            $fileName = ($name -split "/")[-1]
            $className = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
            $pkgName = if ($name.Contains("/")) { $name.Substring(0, $name.LastIndexOf("/")) } else { "" }

            if ([string]::IsNullOrEmpty($pkgName)) { $rootClassCount++ }
            if ($className -match '^\d+$') { $numericCount++ }
            if ($className -match '[^\x00-\x7F]') { $unicodeCount++ }
            if ($className -match '[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]') { $fullwidthCount++ }
            if ($className -match '[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF]') { $japaneseCount++ }
            if ($className -match '[\u0001-\u001F\u200B-\u200F\uFEFF]') { $unprintableCount++ }
            if ($className -match '[\u0400-\u04FF]') { $cyrillicCount++ }
            if ($className -match '^[a-zA-Z]$') { $singleLetterCount++ }
            if ($className.Length -ge 3 -and $className.Length -le 10 -and $className -notmatch '[aeiouAEIOU\d_]') { $vowellessCount++ }
            if ($pkgName -match '^[a-zA-Z]$|^[a-zA-Z]/[a-zA-Z]$') { $shortPackageCount++ }
        }
    }

    foreach ($key in $ArchiveData.ClassBytes.Keys) {
        if ($key.EndsWith(".class") -and $sampleSize -lt 250000) {
            $bytes = $ArchiveData.ClassBytes[$key]
            if ($bytes.Length -gt 20 -and $bytes.Length -lt 150000) {
                $ascii = [System.Text.Encoding]::ASCII.GetString($bytes)
                [void]$contentSample.Append($ascii)
                $sampleSize += $ascii.Length
            }
        }
    }

    if ($totalClass -lt 1) { return $flags }

    $pct = { param($n) [math]::Round(($n / $totalClass) * 100) }
    $numPct   = & $pct $numericCount
    $uniPct   = & $pct $unicodeCount
    $fwPct    = & $pct $fullwidthCount
    $jpPct    = & $pct $japaneseCount
    $s1Pct    = & $pct $singleLetterCount
    $vowPct   = & $pct $vowellessCount

    if ($singleLetterCount -ge 5 -and $s1Pct -ge 30) {
        [void]$flags.Add("Single-letter & flattened class hierarchy ($singleLetterCount classes / $s1Pct%)")
    } elseif ($rootClassCount -ge 4 -and $singleLetterCount -ge 3 -and $s1Pct -ge 40) {
        [void]$flags.Add("Single-letter root package obfuscation ($singleLetterCount classes / $s1Pct%)")
    }
    if ($vowellessCount -ge 5 -and $vowPct -ge 25) {
        [void]$flags.Add("Vowel-less random consonant class name obfuscation ($vowellessCount classes / $vowPct%)")
    }
    if ($numericCount -ge 5 -and $numPct -ge 25) {
        [void]$flags.Add("Numeric class name obfuscation ($numericCount classes / $numPct%)")
    }
    if ($fwPct -gt 0) {
        [void]$flags.Add("Fullwidth Unicode identifier obfuscation ($fullwidthCount classes)")
    }
    if ($jpPct -gt 0) {
        [void]$flags.Add("Japanese / CJK symbol obfuscation ($japaneseCount classes)")
    }
    if ($unprintableCount -gt 0) {
        [void]$flags.Add("Invisible / zero-width unprintable identifier obfuscation ($unprintableCount classes)")
    }
    if ($cyrillicCount -gt 0) {
        [void]$flags.Add("Cyrillic homoglyph identifier obfuscation ($cyrillicCount classes)")
    }

    $sampleStr = $contentSample.ToString()

    $hasStringDecryptor = $false
    if ($sampleStr.Contains("([C[B)Ljava/lang/String;") -or $sampleStr.Contains("(Ljava/lang/String;[C)Ljava/lang/String;") -or $sampleStr.Contains("([B[B)Ljava/lang/String;")) {
        $hasStringDecryptor = $true
    }
    if ($sampleStr.Contains("([C)Ljava/lang/String;") -and ($sampleStr.Contains("javax/crypto/Cipher") -or $sampleStr.Contains("java/lang/invoke/CallSite") -or $sampleStr.Contains("java/lang/invoke/MethodHandle") -or $sampleStr.Contains("xor") -or $sampleStr.Contains("XOR"))) {
        $hasStringDecryptor = $true
    }
    if ($sampleStr.Contains("([B)Ljava/lang/String;") -and ($sampleStr.Contains("javax/crypto/Cipher") -or $sampleStr.Contains("java/lang/invoke/CallSite") -or $sampleStr.Contains("java/lang/invoke/MethodHandle"))) {
        $hasStringDecryptor = $true
    }
    if ($hasStringDecryptor) {
        [void]$flags.Add("Control flow flattening & encrypted string dispatcher methods detected")
    }
    if ($sampleStr.Contains("SourceFile") -and ($sampleStr -match 'SourceFile\s*\x00\x00|SourceFile\s*\x00\x01\x61')) {
        [void]$flags.Add("Synthetic compiler debug-table stripping (LineNumberTable & SourceFile removed)")
    }

    foreach ($obfName in $cheatObfuscators.Keys) {
        foreach ($pat in $cheatObfuscators[$obfName]) {
            if ($sampleStr.Contains($pat)) {
                [void]$flags.Add("Known cheat obfuscator: $obfName (signature: $pat)")
                break
            }
        }
    }

    if ($FilePath -and (Test-Path $FilePath)) {
        $zipAnomalies = [FastScanner]::CheckZipIntegrity($FilePath)
        if ($zipAnomalies) {
            foreach ($za in $zipAnomalies) {
                [void]$flags.Add("ZIP Archive Anomaly: $za")
            }
        }
    }

    return $flags
}

function Start-RuntimeAnalysis {
    $results = [System.Collections.Generic.List[string]]::new()
    $javaProc = Get-Process javaw -ErrorAction SilentlyContinue
    if (-not $javaProc) { $javaProc = Get-Process java -ErrorAction SilentlyContinue }
    if (-not $javaProc) { return $results }
    $javaPid = ($javaProc | Select-Object -First 1).Id
    try {
        $wmi = Get-CimInstance Win32_Process -Filter "ProcessId = $javaPid" -ErrorAction Stop
        $cmdLine = $wmi.CommandLine
        if ($cmdLine) {
            $agentMatches = [regex]::Matches($cmdLine, '-javaagent:([^\s"]+)')
            foreach ($m in $agentMatches) {
                $agentPath = $m.Groups[1].Value.Trim('"').Trim("'")
                $agentName = [System.IO.Path]::GetFileName($agentPath)
                $legitAgents = @("jmxremote","yjp","jrebel","newrelic","jacoco","theseus")
                $isLegit = $false
                foreach ($la in $legitAgents) { if ($agentName.Contains($la)) { $isLegit = $true; break } }
                if (-not $isLegit) {
                    [void]$results.Add("Active JVM Agent: -javaagent:$agentName (Path: $agentPath)")
                }
            }
            $suspFlags = @(
                @{ Flag = "-Xbootclasspath/p:"; Desc = "prepends bootstrap classpath" },
                @{ Flag = "-agentlib:jdwp";     Desc = "JDWP remote debugging enabled" },
                @{ Flag = "-agentpath:";         Desc = "native agent library attached" }
            )
            foreach ($sf in $suspFlags) {
                if ($cmdLine.Contains($sf.Flag)) {
                    [void]$results.Add("JVM Argument: $($sf.Flag) ($($sf.Desc))")
                }
            }
        }
    } catch { }
    return $results
}

function Show-CategoryHeader {
    param([string]$Title, [int]$Count, [ConsoleColor]$DotColor, [ConsoleColor]$CountColor)
    Write-Host ""
    Write-Host "─ [ $Title ] " -ForegroundColor White -NoNewline
    Write-Host ("─" * [Math]::Max(5, (60 - $Title.Length))) -ForegroundColor DarkGray -NoNewline
    Write-Host " ($Count)" -ForegroundColor $CountColor
    Write-Host ""
}

function Show-AnalysisProgress {
    param([int]$Current, [int]$Total, [string]$FileName, [System.Diagnostics.Stopwatch]$Timer)
    $pct = [math]::Round(($Current / $Total) * 100)
    $elapsed = $Timer.Elapsed.TotalSeconds
    $perItem = if ($Current -gt 0) { $elapsed / $Current } else { 0 }
    $remaining = [math]::Round($perItem * ($Total - $Current))
    $barLen = 28
    $filledFull = [math]::Floor($barLen * ($pct / 100))
    $bar = ("█" * $filledFull) + ("░" * ($barLen - $filledFull))
    $name = if ($FileName.Length -gt 24) { $FileName.Substring(0,21) + "..." } else { $FileName }
    Write-Host "`r  [$bar] $pct% | $Current/$Total | ETA: ${remaining}s | $name                " -ForegroundColor Cyan -NoNewline
}

function Show-FlaggedResult {
    param($Mod)

    Write-Host "┌─────────────────────────────────────────────────────────────────────────────┐" -ForegroundColor DarkRed
    Write-Host "│ HACK / GHOST CLIENT DETECTED: " -ForegroundColor Red -NoNewline
    Write-Host $Mod.FileName -ForegroundColor Yellow
    if ($Mod.ModIdentity -and $Mod.ModIdentity.ModId) {
        Write-Host "│ Mod ID: $($Mod.ModIdentity.Name) [$($Mod.ModIdentity.Loader)]" -ForegroundColor Gray
    }
    if ($Mod.OriginInfo -and $Mod.OriginInfo.SourceHost) {
        Write-Host "│ Download Source: $($Mod.OriginInfo.SourceHost)" -ForegroundColor DarkCyan -NoNewline
        if ($Mod.OriginInfo.ExactUrl) {
            $urlDisp = if ($Mod.OriginInfo.ExactUrl.Length -gt 45) { $Mod.OriginInfo.ExactUrl.Substring(0,42) + "..." } else { $Mod.OriginInfo.ExactUrl }
            Write-Host " ($urlDisp)" -ForegroundColor Gray
        } else { Write-Host "" }
        if ($Mod.OriginInfo.IsCheatOrigin) {
            Write-Host "│ WARNING: Downloaded from verified cheat distribution source" -ForegroundColor Red
        }
        if ($Mod.OriginInfo.IsDiscordOrigin) {
            Write-Host "│ WARNING: Downloaded directly via Discord attachment CDN" -ForegroundColor DarkYellow
        }
    }
    Write-Host "├─────────────────────────────────────────────────────────────────────────────┤" -ForegroundColor DarkRed

    if ($Mod.Patterns.Count -gt 0) {
        Write-Host "│ CHEAT SIGNATURES IDENTIFIED:" -ForegroundColor DarkGray
        foreach ($p in ($Mod.Patterns | Sort-Object)) {
            Write-Host "│   • " -ForegroundColor DarkRed -NoNewline
            Write-Host $p -ForegroundColor Red
        }
    }

    $uniqueStrings = $Mod.FlaggedStrings | Where-Object { $Mod.Patterns -notcontains $_ } | Sort-Object
    if ($uniqueStrings.Count -gt 0) {
        Write-Host "│ HEURISTICS & ADVANCED PATTERNS:" -ForegroundColor DarkGray
        foreach ($s in $uniqueStrings) {
            Write-Host "│   • " -ForegroundColor DarkRed -NoNewline
            Write-Host $s -ForegroundColor DarkYellow
        }
    }

    if ($Mod.FullwidthStrings -and $Mod.FullwidthStrings.Count -gt 0) {
        Write-Host "│ FULLWIDTH UNICODE PATTERNS:" -ForegroundColor DarkGray
        foreach ($fw in ($Mod.FullwidthStrings | Sort-Object)) {
            Write-Host "│   • " -ForegroundColor DarkRed -NoNewline
            Write-Host $fw -ForegroundColor Cyan
        }
    }

    if ($Mod.EncodedHits -and $Mod.EncodedHits.Count -gt 0) {
        Write-Host "│ DECODED PAYLOADS:" -ForegroundColor DarkGray
        foreach ($eh in $Mod.EncodedHits) {
            Write-Host "│   • " -ForegroundColor DarkRed -NoNewline
            Write-Host $eh -ForegroundColor Magenta
        }
    }

    if ($Mod.SelfDestructFlags -and $Mod.SelfDestructFlags.Count -gt 0) {
        Write-Host "│ SELF-DESTRUCT MECHANISMS:" -ForegroundColor DarkGray
        foreach ($sd in $Mod.SelfDestructFlags) {
            Write-Host "│   • " -ForegroundColor DarkRed -NoNewline
            Write-Host $sd -ForegroundColor Red
        }
    }

    if ($Mod.ObfFlags -and $Mod.ObfFlags.Count -gt 0) {
        Write-Host "│ OBFUSCATION DETECTED:" -ForegroundColor DarkGray
        foreach ($of in $Mod.ObfFlags) {
            Write-Host "│   • " -ForegroundColor DarkCyan -NoNewline
            Write-Host $of -ForegroundColor Cyan
        }
    }

    if ($Mod.TimestompFlags -and $Mod.TimestompFlags.Count -gt 0) {
        Write-Host "│ DATE STAMP TAMPERING:" -ForegroundColor DarkGray
        foreach ($ts in $Mod.TimestompFlags) {
            Write-Host "│   • " -ForegroundColor DarkRed -NoNewline
            Write-Host $ts -ForegroundColor DarkYellow
        }
    }

    if ($Mod.SpoofFlags -and $Mod.SpoofFlags.Count -gt 0) {
        Write-Host "│ IDENTITY SPOOFING:" -ForegroundColor DarkGray
        foreach ($sf in $Mod.SpoofFlags) {
            Write-Host "│   • " -ForegroundColor DarkRed -NoNewline
            Write-Host $sf -ForegroundColor Red
        }
    }

    Write-Host "└─────────────────────────────────────────────────────────────────────────────┘" -ForegroundColor DarkRed
    Write-Host ""
}

function Show-MacroResult {
    param($Mod)

    Write-Host "┌─────────────────────────────────────────────────────────────────────────────┐" -ForegroundColor DarkYellow
    Write-Host "│ PVP MACRO / AUTOMATION MOD: " -ForegroundColor Yellow -NoNewline
    Write-Host $Mod.FileName -ForegroundColor White
    if ($Mod.ModIdentity -and $Mod.ModIdentity.ModId) {
        Write-Host "│ Mod ID: $($Mod.ModIdentity.Name) [$($Mod.ModIdentity.Loader)]" -ForegroundColor Gray
    }
    if ($Mod.OriginInfo -and $Mod.OriginInfo.SourceHost) {
        Write-Host "│ Download Source: $($Mod.OriginInfo.SourceHost)" -ForegroundColor DarkCyan
    }
    Write-Host "├─────────────────────────────────────────────────────────────────────────────┤" -ForegroundColor DarkYellow

    if ($Mod.Macros.Count -gt 0) {
        Write-Host "│ MACRO MODULES IDENTIFIED:" -ForegroundColor DarkGray
        foreach ($m in ($Mod.Macros | Sort-Object)) {
            Write-Host "│   • " -ForegroundColor Yellow -NoNewline
            Write-Host $m -ForegroundColor Yellow
        }
    }

    $uniqueStrings = $Mod.FlaggedStrings | Where-Object { $Mod.Macros -notcontains $_ } | Sort-Object
    if ($uniqueStrings.Count -gt 0) {
        Write-Host "│ AUTOMATION KEYWORDS & HEURISTICS:" -ForegroundColor DarkGray
        foreach ($s in $uniqueStrings) {
            Write-Host "│   • " -ForegroundColor DarkYellow -NoNewline
            Write-Host $s -ForegroundColor Gray
        }
    }

    Write-Host "└─────────────────────────────────────────────────────────────────────────────┘" -ForegroundColor DarkYellow
    Write-Host ""
}

function Show-InjectionResult {
    param($Mod)

    Write-Host "┌─────────────────────────────────────────────────────────────────────────────┐" -ForegroundColor DarkMagenta
    Write-Host "│ RUNTIME / INJECTION CRITICAL: " -ForegroundColor Magenta -NoNewline
    Write-Host $Mod.FileName -ForegroundColor Yellow
    Write-Host "├─────────────────────────────────────────────────────────────────────────────┤" -ForegroundColor DarkMagenta

    foreach ($flag in $Mod.Flags) {
        Write-Host "│   • " -ForegroundColor Magenta -NoNewline
        Write-Host $flag -ForegroundColor White
    }

    Write-Host "└─────────────────────────────────────────────────────────────────────────────┘" -ForegroundColor DarkMagenta
    Write-Host ""
}

function Show-ObfuscationResult {
    param($Mod)

    Write-Host "┌─────────────────────────────────────────────────────────────────────────────┐" -ForegroundColor DarkCyan
    Write-Host "│ OBFUSCATED MOD PACKAGE: " -ForegroundColor Cyan -NoNewline
    Write-Host $Mod.FileName -ForegroundColor Yellow
    Write-Host "├─────────────────────────────────────────────────────────────────────────────┤" -ForegroundColor DarkCyan

    foreach ($flag in $Mod.Flags) {
        Write-Host "│   • " -ForegroundColor DarkCyan -NoNewline
        Write-Host $flag -ForegroundColor White
    }

    Write-Host "└─────────────────────────────────────────────────────────────────────────────┘" -ForegroundColor DarkCyan
    Write-Host ""
}

function Show-Bar {
    param([int]$Value, [int]$Total, [int]$Width = 35)
    $pct = if ($Total -gt 0) { $Value / $Total } else { 0 }
    $filled = [math]::Round($Width * $pct)
    $empty = $Width - $filled
    return ("█" * $filled) + ("░" * ($empty))
}

$confirmedEntries  = @()
$unverifiedEntries = @()
$flaggedEntries    = @()
$macroEntries      = @()
$injectedEntries   = @()
$obfEntries        = @()

$timer = [System.Diagnostics.Stopwatch]::StartNew()
$idx = 0

Write-Host "[1/5] Checking file system, USN journal, memory & self-destruct traces..." -ForegroundColor Cyan
$mcStartTime = if ($mcProcess -and $mcProcess.Count -gt 0) { $mcProcess[0].StartTime } else { $null }
$journalHits = Start-USNAnalysis -ModsDir $modsPath -GameStartTime $mcStartTime
$selfDestructExecuted = Test-ExecutedSelfDestruct -ModsDir $modsPath -GameStartTime $mcStartTime

$memoryReport = $null
$memoryDiscrepancies = [System.Collections.Generic.List[object]]::new()
$ghostCheatPackages = [System.Collections.Generic.List[string]]::new()

if ($mcProcess) {
    try {
        $targetPid = ($mcProcess | Select-Object -First 1).Id
        $memoryReport = [FastScanner]::ScanProcessComprehensive($targetPid, $modsPath)

        if ($memoryReport.UnloadedMods.Count -gt 0) {
            foreach ($um in $memoryReport.UnloadedMods) {
                $unloadedName = [System.IO.Path]::GetFileName($um)
                [void]$memoryDiscrepancies.Add([PSCustomObject]@{
                    JarPath = $um
                    FileName = $unloadedName
                    PID = $targetPid
                })
                Write-Host "   CRITICAL UNLOAD DETECTED: '$unloadedName' in memory (PID $targetPid) but NOT on disk!" -ForegroundColor Red
            }
        }

        if ($memoryReport.GhostCheatSignatures.Count -gt 0) {
            foreach ($gcs in $memoryReport.GhostCheatSignatures) {
                [void]$ghostCheatPackages.Add($gcs)
                Write-Host "   MEMORY RESIDENT CHEAT SIGNATURE: $gcs" -ForegroundColor DarkRed
            }
        }

        if ($memoryReport.InjectedPEHeaders.Count -gt 0) {
            foreach ($ipe in $memoryReport.InjectedPEHeaders) {
                Write-Host "   CRITICAL MEMORY INJECTION: $ipe" -ForegroundColor Red
            }
        }

        if ($memoryReport.GhostMixinHandlers.Count -gt 0) {
            foreach ($gmh in $memoryReport.GhostMixinHandlers) {
                Write-Host "   GHOST MIXIN HANDLER: $gmh" -ForegroundColor DarkRed
            }
        }

        if ($memoryReport.UnlinkedModules.Count -gt 0) {
            foreach ($um in $memoryReport.UnlinkedModules) {
                Write-Host "   PEB UNLINKED MODULE: $um" -ForegroundColor Red
            }
        }

        if ($memoryReport.HookedExports.Count -gt 0) {
            foreach ($he in $memoryReport.HookedExports) {
                Write-Host "   API / RENDER HOOK: $he" -ForegroundColor Red
            }
        }

        if ($memoryReport.CheatConfigSnippets.Count -gt 0) {
            Write-Host "   MEMORY CHEAT CONFIGURATIONS: $($memoryReport.CheatConfigSnippets.Count) active module settings found in heap" -ForegroundColor DarkYellow
        }

        if ($memoryReport.CheatGUIElements.Count -gt 0) {
            Write-Host "   CHEAT GUI STRINGS IN HEAP: $($memoryReport.CheatGUIElements.Count) visual interface strings found" -ForegroundColor DarkYellow
        }

        if ($memoryReport.MemoryNetworkEndpoints.Count -gt 0) {
            foreach ($mne in $memoryReport.MemoryNetworkEndpoints) {
                Write-Host "   MEMORY C2 / NETWORK ENDPOINT: $mne" -ForegroundColor Red
            }
        }

        if ($memoryReport.JNativeHookTraces.Count -gt 0) {
            foreach ($jnh in $memoryReport.JNativeHookTraces) {
                Write-Host "   JNATIVEHOOK RESIDENT IN MEMORY: $jnh" -ForegroundColor DarkRed
            }
        }

        if ($memoryReport.JvmInstrumentationTraces.Count -gt 0) {
            foreach ($jit in $memoryReport.JvmInstrumentationTraces) {
                Write-Host "   JVM INSTRUMENTATION / ATTACH TRACE: $jit" -ForegroundColor Yellow
            }
        }

        if ($memoryReport.JvmAttachListenerActive) {
            Write-Host "   JVM ATTACH LISTENER ACTIVE: Dynamic agent IPC socket found ($($memoryReport.AttachSocketPath))" -ForegroundColor Yellow
        }
    } catch { }
}

if ($journalHits.Count -gt 0) {
    foreach ($jh in $journalHits) {
        $parts = $jh -split '\|'
        if ($parts.Count -ge 2) {
            Write-Host "   JOURNAL ALERT: $($parts[0]) - $($parts[1])" -ForegroundColor Red
        } else {
            Write-Host "   JOURNAL ALERT: $jh" -ForegroundColor Red
        }
    }
}

if ($selfDestructExecuted.Count -gt 0) {
    foreach ($sde in $selfDestructExecuted) {
        Write-Host "   SELF-DESTRUCT DETECTED: [$($sde.Category)] $($sde.Details)" -ForegroundColor Red
    }
}

if ($journalHits.Count -eq 0 -and $selfDestructExecuted.Count -eq 0 -and $memoryDiscrepancies.Count -eq 0 -and (-not $memoryReport -or ($memoryReport.GhostCheatSignatures.Count -eq 0 -and $memoryReport.InjectedPEHeaders.Count -eq 0 -and $memoryReport.UnlinkedModules.Count -eq 0 -and $memoryReport.HookedExports.Count -eq 0 -and $memoryReport.GhostMixinHandlers.Count -eq 0 -and $memoryReport.MemoryNetworkEndpoints.Count -eq 0))) {
    Write-Host "   File system journal, process memory & deletion artifacts are clean" -ForegroundColor DarkGray
}

$tempHits = Start-TempScan
if ($tempHits.Count -gt 0) {
    foreach ($th in $tempHits) {
        Write-Host "   TEMP WARNING: $th" -ForegroundColor DarkYellow
    }
}
Write-Host

$script:cacheRoot = "$env:LOCALAPPDATA\APPTModAnalyzer\cache"
if (-not (Test-Path $script:cacheRoot)) { New-Item -ItemType Directory -Path $script:cacheRoot -Force | Out-Null }

function Get-CachedResult {
    param([string]$Hash, [string]$Source)
    $f = Join-Path $script:cacheRoot "$Source-$Hash.json"
    if (Test-Path $f) {
        $age = (Get-Date) - (Get-Item $f).LastWriteTime
        if ($age.TotalHours -lt 48) { return (Get-Content $f -Raw | ConvertFrom-Json) }
    }
    return $null
}

function Save-CachedResult {
    param([string]$Hash, [string]$Source, $Data)
    $f = Join-Path $script:cacheRoot "$Source-$Hash.json"
    $Data | ConvertTo-Json -Compress | Set-Content $f -Encoding UTF8
}

function Resolve-ModrinthBatch {
    param($JarList)
    $unresolved = [System.Collections.Generic.List[object]]::new()
    $resolvedMap = @{}

    foreach ($j in $JarList) {
        $cached = Get-CachedResult -Hash $j.SHA1 -Source "modrinth"
        if ($cached -and $cached.Verified) {
            $resolvedMap[$j.SHA1] = $cached
        } else {
            [void]$unresolved.Add($j)
        }
    }

    if ($unresolved.Count -gt 0) {
        try {
            $headers = @{ "User-Agent" = "APPT-ModAnalyzer/3.0 (github.com/Poxy-1/ApptModAnalyzer)" }
            $sha1s = @($unresolved | ForEach-Object { [string]$_.SHA1.ToLower() })
            $body = @{ hashes = $sha1s; algorithm = "sha1" } | ConvertTo-Json
            $resp = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version_files" -Method Post -Body $body -ContentType "application/json" -Headers $headers -TimeoutSec 5 -ErrorAction SilentlyContinue

            if ($resp) {
                $projIds = [System.Collections.Generic.HashSet[string]]::new()
                foreach ($prop in $resp.PSObject.Properties) {
                    if ($prop.Value -and $prop.Value.project_id) {
                        [void]$projIds.Add($prop.Value.project_id)
                    }
                }

                $projectTitles = @{}
                if ($projIds.Count -gt 0) {
                    try {
                        $pJson = [string]::Format('["{0}"]', ($projIds -join '","'))
                        $pResp = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/projects?ids=$pJson" -Headers $headers -TimeoutSec 5 -ErrorAction SilentlyContinue
                        if ($pResp) {
                            foreach ($p in $pResp) {
                                if ($p.id -and $p.title) { $projectTitles[$p.id] = $p.title }
                            }
                        }
                    } catch { }
                }

                foreach ($prop in $resp.PSObject.Properties) {
                    $h = $prop.Name.ToLower()
                    $vObj = $prop.Value
                    if ($vObj -and $vObj.project_id) {
                        $projId = $vObj.project_id
                        $t = if ($projectTitles.ContainsKey($projId)) { $projectTitles[$projId] } else { $projId }
                        $data = @{ Name = $t; Slug = $projId; Verified = $true; Source = "Modrinth" }
                        Save-CachedResult -Hash $h -Source "modrinth" -Data $data
                        $resolvedMap[$h] = $data
                    }
                }
            }
        } catch { }
    }
    return $resolvedMap
}

function Resolve-MegabaseHash {
    param([string]$Hash)
    $cached = Get-CachedResult -Hash $Hash -Source "megabase"
    if ($cached) { return $cached }
    try {
        $resp = Invoke-RestMethod -Uri "https://api.megabase.org/v1/hash/$Hash" -TimeoutSec 3 -ErrorAction SilentlyContinue
        if ($resp -and $resp.name) {
            $data = @{ Name = $resp.name; Verified = $true; Source = "Megabase" }
            Save-CachedResult -Hash $Hash -Source "megabase" -Data $data
            return $data
        }
    } catch { }
    try {
        $resp2 = Invoke-RestMethod -Uri "https://megabase.vercel.app/api/query?hash=$Hash" -TimeoutSec 3 -ErrorAction SilentlyContinue
        if ($resp2 -and $resp2.name) {
            $data = @{ Name = $resp2.name; Verified = $true; Source = "Megabase" }
            Save-CachedResult -Hash $Hash -Source "megabase" -Data $data
            return $data
        }
    } catch { }
    return @{ Name = $null; Verified = $false; Source = $null }
}

function Resolve-CFWidget {
    param([string]$SlugOrId)
    if (-not $SlugOrId -or $SlugOrId.Trim() -eq "") { return $null }
    $clean = $SlugOrId.Trim().ToLower()
    $cached = Get-CachedResult -Hash $clean -Source "cfwidget"
    if ($cached) { return $cached }
    try {
        $url = if ($clean -match '^\d+$') { "https://api.cfwidget.com/$clean" } else { "https://api.cfwidget.com/minecraft/mc-mods/$clean" }
        $resp = Invoke-RestMethod -Uri $url -Headers @{ "User-Agent" = "Mozilla/5.0" } -TimeoutSec 3 -ErrorAction SilentlyContinue
        if ($resp -and $resp.title) {
            $data = @{ Name = [string]$resp.title; Slug = $clean; Verified = $true; Source = "CurseForge" }
            Save-CachedResult -Hash $clean -Source "cfwidget" -Data $data
            return $data
        }
    } catch { }
    return $null
}

function Resolve-ModrinthProject {
    param([string]$Slug)
    if (-not $Slug -or $Slug.Trim() -eq "") { return $null }
    $clean = $Slug.Trim().ToLower()
    $cached = Get-CachedResult -Hash $clean -Source "modrinth-proj"
    if ($cached) { return $cached }
    try {
        $headers = @{ "User-Agent" = "APPT-ModAnalyzer/3.0" }
        $resp = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/project/$clean" -Headers $headers -TimeoutSec 3 -ErrorAction SilentlyContinue
        if ($resp -and $resp.title) {
            $data = @{ Name = [string]$resp.title; Slug = $clean; Verified = $true; Source = "Modrinth" }
            Save-CachedResult -Hash $clean -Source "modrinth-proj" -Data $data
            return $data
        }
    } catch { }
    return $null
}

function Resolve-MavenHash {
    param([string]$FileName, [string]$Sha1)
    if ($FileName -match '^(fabric-api|fabric-language-kotlin|fabric-language-scala)-([0-9\.\+\-a-zA-Z]+)\.jar$') {
        $art = $matches[1]
        $ver = $matches[2]
        $cached = Get-CachedResult -Hash $Sha1 -Source "maven"
        if ($cached) { return $cached }
        try {
            $mavenUrl = "https://maven.fabricmc.net/net/fabricmc/fabric-api/$art/$ver/$art-$ver.jar.sha1"
            $remoteSha1 = (Invoke-RestMethod -Uri $mavenUrl -TimeoutSec 1 -ErrorAction SilentlyContinue).Trim()
            if ($remoteSha1 -eq $Sha1) {
                $data = @{ Name = "$art $ver"; Verified = $true; Source = "Maven" }
                Save-CachedResult -Hash $Sha1 -Source "maven" -Data $data
                return $data
            }
        } catch { }
    }
    return @{ Name = $null; Verified = $false; Source = $null }
}

$script:knownModCatalog = @{
    "boatiview" = @{ Name = "Boat Item View"; Source = "CurseForge / Modrinth" }
    "connectivity" = @{ Name = "Connectivity"; Source = "CurseForge" }
    "cupboard" = @{ Name = "Cupboard"; Source = "CurseForge" }
    "gpumemleakfix" = @{ Name = "fix GPU memory leak"; Source = "CurseForge" }
    "travelerstitles" = @{ Name = "Traveler's Titles"; Source = "CurseForge / Modrinth" }
    "sodium" = @{ Name = "Sodium"; Source = "Modrinth / CurseForge" }
    "lithium" = @{ Name = "Lithium"; Source = "Modrinth / CurseForge" }
    "ferritecore" = @{ Name = "FerriteCore"; Source = "Modrinth / CurseForge" }
    "iris" = @{ Name = "Iris Shaders"; Source = "Modrinth / CurseForge" }
    "indium" = @{ Name = "Indium"; Source = "Modrinth / CurseForge" }
    "modmenu" = @{ Name = "Mod Menu"; Source = "Modrinth / CurseForge" }
    "fabric-api" = @{ Name = "Fabric API"; Source = "Maven / Modrinth" }
    "cloth-config" = @{ Name = "Cloth Config"; Source = "Modrinth / CurseForge" }
    "betterf3" = @{ Name = "BetterF3"; Source = "Modrinth / CurseForge" }
    "immediatelyfast" = @{ Name = "ImmediatelyFast"; Source = "Modrinth / CurseForge" }
    "entityculling" = @{ Name = "Entity Culling"; Source = "Modrinth / CurseForge" }
    "dynamic-fps" = @{ Name = "Dynamic FPS"; Source = "Modrinth / CurseForge" }
    "continuity" = @{ Name = "Continuity"; Source = "Modrinth / CurseForge" }
    "resourcify" = @{ Name = "Resourcify"; Source = "Modrinth / CurseForge" }
    "chunky" = @{ Name = "Chunky"; Source = "Modrinth / CurseForge" }
    "lambdynamiclights" = @{ Name = "LambDynamicLights"; Source = "Modrinth / CurseForge" }
    "krypton" = @{ Name = "Krypton"; Source = "Modrinth / CurseForge" }
    "c2me" = @{ Name = "C2ME"; Source = "Modrinth / CurseForge" }
    "starlight" = @{ Name = "Starlight"; Source = "Modrinth / CurseForge" }
    "appleskin" = @{ Name = "AppleSkin"; Source = "Modrinth / CurseForge" }
    "rei" = @{ Name = "Roughly Enough Items"; Source = "Modrinth / CurseForge" }
    "jei" = @{ Name = "Just Enough Items"; Source = "Modrinth / CurseForge" }
    "emi" = @{ Name = "EMI"; Source = "Modrinth / CurseForge" }
    "xaerominimap" = @{ Name = "Xaero's Minimap"; Source = "CurseForge / Modrinth" }
    "xaeroworldmap" = @{ Name = "Xaero's World Map"; Source = "CurseForge / Modrinth" }
    "journeymap" = @{ Name = "JourneyMap"; Source = "CurseForge / Modrinth" }
    "voxelmap" = @{ Name = "VoxelMap"; Source = "CurseForge" }
}

$script:slugAliases = @{
    "gpumemleakfix" = @("fix-gpu-memory-leak", "gpu-memory-leak-fix", "882495")
    "connectivity" = @("connectivity", "470193")
    "cupboard" = @("cupboard", "326652")
    "boatiview" = @("boat-item-view", "482160")
    "travelerstitles" = @("travelers-titles", "travelers-titles-fabric", "590990")
}

Write-Host "[2/5] Verifying mod integrity & online hashes (5-way pipeline)..." -ForegroundColor Cyan

$jarDigests = [System.Collections.Generic.List[object]]::new()
foreach ($jar in $jarFiles) {
    $idx++
    Show-AnalysisProgress -Current $idx -Total $totalFiles -FileName $jar.Name -Timer $timer
    $hashes = Get-FileDigest -Target $jar.FullName
    [void]$jarDigests.Add(@{
        Jar = $jar
        SHA1 = $hashes.SHA1
        SHA256 = $hashes.SHA256
        SHA512 = $hashes.SHA512
        Murmur2 = $hashes.Murmur2
    })
}

$modrinthResults = Resolve-ModrinthBatch -JarList $jarDigests

foreach ($item in $jarDigests) {
    $jar = $item.Jar
    $verifiedName = $null
    $verifiedSource = $null

    if ($item.SHA1) {
        $hLow = $item.SHA1.ToLower()
        if ($modrinthResults.ContainsKey($hLow)) {
            $mr = $modrinthResults[$hLow]
            if ($mr.Verified) {
                $verifiedName = $mr.Name
                $verifiedSource = $mr.Source
            }
        } elseif ($modrinthResults.ContainsKey($item.SHA1)) {
            $mr = $modrinthResults[$item.SHA1]
            if ($mr.Verified) {
                $verifiedName = $mr.Name
                $verifiedSource = $mr.Source
            }
        }
    }

    if (-not $verifiedName -and $item.SHA1) {
        $mav = Resolve-MavenHash -FileName $jar.Name -Sha1 $item.SHA1
        if ($mav.Verified) {
            $verifiedName = $mav.Name
            $verifiedSource = $mav.Source
        }
    }

    if (-not $verifiedName) {
        $metaId = $null
        $metaName = $null
        $metaUrls = @()

        try {
            $zip = [System.IO.Compression.ZipFile]::OpenRead($jar.FullName)
            $fEntry = $zip.GetEntry("fabric.mod.json")
            if ($fEntry) {
                $sr = [System.IO.StreamReader]::new($fEntry.Open())
                $json = $sr.ReadToEnd() | ConvertFrom-Json
                $sr.Close()
                if ($json.id) { $metaId = [string]$json.id }
                if ($json.name) { $metaName = [string]$json.name }
                if ($json.contact) {
                    foreach ($prop in $json.contact.PSObject.Properties) {
                        if ($prop.Value -is [string]) { $metaUrls += [string]$prop.Value }
                    }
                }
            }
            if (-not $metaId) {
                $qEntry = $zip.GetEntry("quilt.mod.json")
                if ($qEntry) {
                    $sr = [System.IO.StreamReader]::new($qEntry.Open())
                    $json = $sr.ReadToEnd() | ConvertFrom-Json
                    $sr.Close()
                    if ($json.quilt_loader -and $json.quilt_loader.id) { $metaId = [string]$json.quilt_loader.id }
                }
            }
            if (-not $metaId) {
                $tEntry = $zip.GetEntry("META-INF/mods.toml")
                if ($tEntry) {
                    $sr = [System.IO.StreamReader]::new($tEntry.Open())
                    $textToml = $sr.ReadToEnd()
                    $sr.Close()
                    if ($textToml -match 'modId\s*=\s*"([^"]+)"') { $metaId = $matches[1] }
                    if ($textToml -match 'displayName\s*=\s*"([^"]+)"') { $metaName = $matches[1] }
                }
            }
            if (-not $metaId) {
                $mEntry = $zip.GetEntry("mcmod.info")
                if ($mEntry) {
                    $sr = [System.IO.StreamReader]::new($mEntry.Open())
                    $json = $sr.ReadToEnd() | ConvertFrom-Json
                    $sr.Close()
                    if ($json -is [array] -and $json.Count -gt 0 -and $json[0].modid) {
                        $metaId = [string]$json[0].modid
                        if ($json[0].name) { $metaName = [string]$json[0].name }
                    }
                }
            }
            $zip.Dispose()
        } catch { }

        if ($metaUrls.Count -gt 0) {
            foreach ($u in $metaUrls) {
                if ($u -match 'curseforge\.com/minecraft/mc-mods/([a-zA-Z0-9_\-]+)') {
                    $cfRes = Resolve-CFWidget -SlugOrId $matches[1]
                    if ($cfRes) { $verifiedName = $cfRes.Name; $verifiedSource = "CurseForge"; break }
                }
                if ($u -match 'modrinth\.com/mod/([a-zA-Z0-9_\-]+)') {
                    $mrRes = Resolve-ModrinthProject -Slug $matches[1]
                    if ($mrRes) { $verifiedName = $mrRes.Name; $verifiedSource = "Modrinth"; break }
                }
            }
        }

        if (-not $verifiedName -and $metaId) {
            $mrRes = Resolve-ModrinthProject -Slug $metaId
            if ($mrRes) {
                $verifiedName = $mrRes.Name
                $verifiedSource = "Modrinth"
            } else {
                $cfRes = Resolve-CFWidget -SlugOrId $metaId
                if ($cfRes) {
                    $verifiedName = $cfRes.Name
                    $verifiedSource = "CurseForge"
                }
            }
        }

        if (-not $verifiedName -and $metaId -and $script:slugAliases.ContainsKey($metaId.ToLower())) {
            foreach ($alias in $script:slugAliases[$metaId.ToLower()]) {
                $cfRes = Resolve-CFWidget -SlugOrId $alias
                if ($cfRes) { $verifiedName = $cfRes.Name; $verifiedSource = "CurseForge"; break }
                $mrRes = Resolve-ModrinthProject -Slug $alias
                if ($mrRes) { $verifiedName = $mrRes.Name; $verifiedSource = "Modrinth"; break }
            }
        }

        if (-not $verifiedName) {
            $cleanFn = $jar.Name -replace '-(?:fabric|forge|neoforge|quilt|mc)?-?[0-9\.\+\-a-zA-Z]+\.jar$', ''
            if ($cleanFn -and $cleanFn -ne $jar.Name) {
                $mrRes = Resolve-ModrinthProject -Slug $cleanFn
                if ($mrRes) {
                    $verifiedName = $mrRes.Name
                    $verifiedSource = "Modrinth"
                } else {
                    $cfRes = Resolve-CFWidget -SlugOrId $cleanFn
                    if ($cfRes) {
                        $verifiedName = $cfRes.Name
                        $verifiedSource = "CurseForge"
                    }
                }
            }
        }

        if (-not $verifiedName -and $metaId -and $script:knownModCatalog.ContainsKey($metaId.ToLower())) {
            $entry = $script:knownModCatalog[$metaId.ToLower()]
            $verifiedName = $entry.Name
            $verifiedSource = $entry.Source
        }
    }

    if ($verifiedName) {
        $confirmedEntries += [PSCustomObject]@{
            ModName = $verifiedName; FileName = $jar.Name
            FilePath = $jar.FullName; Verified = $true; Source = $verifiedSource
        }
    } else {
        $unverifiedEntries += [PSCustomObject]@{ FileName = $jar.Name; FilePath = $jar.FullName }
    }
}

Write-Host "`r$(' ' * 120)`r" -NoNewline

$timer2 = [System.Diagnostics.Stopwatch]::StartNew()
$modWord = if ($totalFiles -eq 1) { "mod" } else { "mods" }
Write-Host "[3/5] Running deep bytecode & signature analysis on $totalFiles $modWord..." -ForegroundColor Cyan
$idx = 0

$allModIdentities = [System.Collections.Generic.List[object]]::new()

foreach ($jar in $jarFiles) {
    $idx++
    Show-AnalysisProgress -Current $idx -Total $totalFiles -FileName $jar.Name -Timer $timer2

    $archiveData = Read-ArchiveData -Target $jar.FullName
    $patternResult = Start-PatternAnalysis -ArchiveData $archiveData -FilePath $jar.FullName
    $bypassFlags = Start-InjectionAnalysis -ArchiveData $archiveData -FilePath $jar.FullName
    $deepFlags = Start-DeepBytecodeScan -ArchiveData $archiveData
    foreach ($df in $deepFlags) { [void]$bypassFlags.Add($df) }
    $obfFlags = Start-StructureAnalysis -ArchiveData $archiveData -FilePath $jar.FullName
    $timestompFlags = Test-Timestomping -FilePath $jar.FullName -ArchiveData $archiveData
    $originInfo = Resolve-OriginMetadata -FilePath $jar.FullName -ArchiveData $archiveData
    $modIdentity = Get-ModIdentity -ArchiveData $archiveData
    $spoofFlags = Test-ModSpoofing -FileName $jar.Name -ModIdentity $modIdentity -ArchiveData $archiveData

    if ($modIdentity -and $modIdentity.ModId -and $modIdentity.ModId.Trim() -ne "") {
        [void]$allModIdentities.Add([PSCustomObject]@{ ModId = $modIdentity.ModId.Trim(); FileName = $jar.Name; Name = $modIdentity.Name })
    }

    if ($originInfo.IsCheatOrigin) {
        [void]$patternResult.FlaggedStrings.Add("Origin: Downloaded directly from known cheat distribution platform")
    }
    if ($originInfo.IsDiscordOrigin) {
        [void]$patternResult.FlaggedStrings.Add("Origin: Downloaded directly via Discord attachment CDN")
    }

    $isVerifiedMod = $false
    foreach ($ce in $confirmedEntries) {
        if ($ce.FileName -eq $jar.Name) { $isVerifiedMod = $true; break }
    }

    $blatantCheatOrigin = $originInfo.IsCheatOrigin
    $blatantSelfDestruct = $patternResult.SelfDestructFlags.Count -gt 0
    $hasStrongPatterns = $patternResult.Patterns.Count -ge 3
    $hasFullwidthCheats = $patternResult.FullwidthStrings.Count -ge 2
    $hasHighConfidence = $patternResult.ConfidenceScore -ge 50
    $hasSomePatterns = $patternResult.Patterns.Count -ge 1

    if ($isVerifiedMod) {
        $isCheatClient = $blatantCheatOrigin -or $blatantSelfDestruct -or
                         ($hasSomePatterns -and $hasHighConfidence) -or
                         ($patternResult.Patterns.Count -ge 5)
    } else {
        $isCheatClient = $blatantCheatOrigin -or $blatantSelfDestruct -or
                         $hasStrongPatterns -or $hasFullwidthCheats -or
                         ($hasSomePatterns -and $hasHighConfidence) -or
                         ($patternResult.EncodedHits.Count -ge 5 -and $patternResult.ConfidenceScore -ge 30)
    }

    $isMacroMod = $patternResult.Macros.Count -gt 0 -and -not $isCheatClient

    if ($isCheatClient) {
        $flaggedEntries += [PSCustomObject]@{
            FileName = $jar.Name; Patterns = $patternResult.Patterns
            Strings = $patternResult.FlaggedStrings; Fullwidth = $patternResult.FullwidthStrings
            EncodedHits = $patternResult.EncodedHits
            HighEntropyCount = $patternResult.HighEntropyCount
            ReflectionScore = $patternResult.ReflectionScore
            SelfDestructFlags = $patternResult.SelfDestructFlags
            TimestompFlags = $timestompFlags
            OriginInfo = $originInfo
            ModIdentity = $modIdentity; SpoofFlags = $spoofFlags
            ObfFlags = $obfFlags
        }
        $confirmedEntries = @($confirmedEntries | Where-Object { $_.FileName -ne $jar.Name })
        $unverifiedEntries = @($unverifiedEntries | Where-Object { $_.FileName -ne $jar.Name })
    } elseif ($isMacroMod) {
        $macroEntries += [PSCustomObject]@{
            FileName = $jar.Name; Macros = $patternResult.Macros
            Strings = $patternResult.FlaggedStrings
            OriginInfo = $originInfo
            ModIdentity = $modIdentity
        }
        $confirmedEntries = @($confirmedEntries | Where-Object { $_.FileName -ne $jar.Name })
        $unverifiedEntries = @($unverifiedEntries | Where-Object { $_.FileName -ne $jar.Name })
    }

    if ($bypassFlags.Count -gt 0) {
        $injectedEntries += [PSCustomObject]@{ FileName = $jar.Name; Flags = $bypassFlags }
        if (-not $isVerifiedMod) {
            $confirmedEntries = @($confirmedEntries | Where-Object { $_.FileName -ne $jar.Name })
            $unverifiedEntries = @($unverifiedEntries | Where-Object { $_.FileName -ne $jar.Name })
        }
    }

    if ($obfFlags.Count -gt 0) {
        $obfEntries += [PSCustomObject]@{ FileName = $jar.Name; Flags = $obfFlags }
        if (-not $isVerifiedMod) {
            $confirmedEntries = @($confirmedEntries | Where-Object { $_.FileName -ne $jar.Name })
            $unverifiedEntries = @($unverifiedEntries | Where-Object { $_.FileName -ne $jar.Name })
        }
    }
}

Write-Host "`r$(' ' * 120)`r" -NoNewline

$jvmFlags = @()
Write-Host "[4/5] Inspecting JVM runtime environment..." -ForegroundColor DarkYellow
$jvmFlags = Start-RuntimeAnalysis
if ($jvmFlags.Count -gt 0) {
    Write-Host "   JVM issues detected!" -ForegroundColor Yellow
} else {
    Write-Host "   JVM runtime environment is clean" -ForegroundColor DarkGray
}

if ($memoryDiscrepancies -and $memoryDiscrepancies.Count -gt 0) {
    foreach ($md in $memoryDiscrepancies) {
        $flaggedEntries += [PSCustomObject]@{
            FileName = "$($md.FileName) [UNLOADED GHOST MOD]"
            Patterns = @("Unloaded / Deleted from disk while Minecraft is running")
            Strings = @("Memory Discrepancy: Loaded in javaw.exe (PID $($md.PID)) from $($md.JarPath) but missing on disk")
            Fullwidth = @()
            EncodedHits = @()
            HighEntropyCount = 0
            ReflectionScore = 0
            SelfDestructFlags = @("Process Handle Unload & Disk File Deletion")
            TimestompFlags = @()
            OriginInfo = @{ SourceHost = "Minecraft Process Memory (PID $($md.PID))"; IsCheatOrigin = $true }
            ModIdentity = @{ Name = $md.FileName; Loader = "Memory Loaded"; ModId = "unloaded-mod" }
            SpoofFlags = @()
            ObfFlags = @()
        }
    }
}

if ($selfDestructExecuted -and $selfDestructExecuted.Count -gt 0) {
    foreach ($sde in $selfDestructExecuted) {
        $flaggedEntries += [PSCustomObject]@{
            FileName = "$($sde.FileName) [DELETED / SELF-DESTRUCTED]"
            Patterns = @("Executed Self-Destruct / Deletion Artifact ($($sde.Category))")
            Strings = @($sde.Details)
            Fullwidth = @()
            EncodedHits = @()
            HighEntropyCount = 0
            ReflectionScore = 0
            SelfDestructFlags = @($sde.Details)
            TimestompFlags = @()
            OriginInfo = @{ SourceHost = "Deleted Mod Artifact ($($sde.Category))"; IsCheatOrigin = $true; ExactUrl = $sde.OriginalPath }
            ModIdentity = @{ Name = $sde.FileName; Loader = "Post-Launch Deleted"; ModId = "self-destructed-mod" }
            SpoofFlags = @()
            ObfFlags = @()
        }
    }
}

if ($ghostCheatPackages -and $ghostCheatPackages.Count -gt 0) {
    $existingCheatJars = @($jarFiles | ForEach-Object { $_.Name.ToLower() })
    $hasKnownOnDiskCheat = $false
    foreach ($cj in @("meteor", "doomsday", "vape", "wurst", "liquidbounce", "novoware", "hellclient")) {
        foreach ($ej in $existingCheatJars) {
            if ($ej.Contains($cj)) { $hasKnownOnDiskCheat = $true; break }
        }
    }
    if (-not $hasKnownOnDiskCheat) {
        $flaggedEntries += [PSCustomObject]@{
            FileName = "JVM Memory Injected Cheat [NO DISK FILE]"
            Patterns = @($ghostCheatPackages)
            Strings = @("Injected / Fileless Cheat Package detected in javaw.exe memory pages")
            Fullwidth = @()
            EncodedHits = @()
            HighEntropyCount = 0
            ReflectionScore = 0
            SelfDestructFlags = @("Memory-Resident Bytecode without on-disk JAR footprint")
            TimestompFlags = @()
            OriginInfo = @{ SourceHost = "Active Minecraft Process Memory"; IsCheatOrigin = $true }
            ModIdentity = @{ Name = "Injected Memory Cheat"; Loader = "HotSpot JVM Injected"; ModId = "memory-injected" }
            SpoofFlags = @()
            ObfFlags = @()
        }
    }
}

if ($memoryReport) {
    if ($memoryReport.GhostMixinHandlers.Count -gt 0 -or $memoryReport.CheatGUIElements.Count -gt 0 -or $memoryReport.MemoryNetworkEndpoints.Count -gt 0 -or $memoryReport.JNativeHookTraces.Count -gt 0) {
        $memCheatPatterns = [System.Collections.Generic.List[string]]::new()
        $memCheatStrings = [System.Collections.Generic.List[string]]::new()
        foreach ($gmh in $memoryReport.GhostMixinHandlers) { [void]$memCheatPatterns.Add("Ghost Mixin: $gmh") }
        foreach ($cge in $memoryReport.CheatGUIElements) { [void]$memCheatStrings.Add("Heap GUI: $cge") }
        foreach ($mne in $memoryReport.MemoryNetworkEndpoints) { [void]$memCheatPatterns.Add("Endpoint: $mne") }
        foreach ($jnh in $memoryReport.JNativeHookTraces) { [void]$memCheatPatterns.Add("JNativeHook: $jnh") }
        $flaggedEntries += [PSCustomObject]@{
            FileName = "javaw.exe Heap / Metaspace Artifacts"
            Patterns = @($memCheatPatterns)
            Strings = @($memCheatStrings)
            Fullwidth = @()
            EncodedHits = @()
            HighEntropyCount = 0
            ReflectionScore = 0
            SelfDestructFlags = @()
            TimestompFlags = @()
            OriginInfo = @{ SourceHost = "Active Process Heap / Metaspace"; IsCheatOrigin = $true }
            ModIdentity = @{ Name = "Memory Resident Cheat Signatures"; Loader = "HotSpot JVM"; ModId = "memory-signatures" }
            SpoofFlags = @()
            ObfFlags = @()
        }
    }

    if ($memoryReport.InjectedPEHeaders.Count -gt 0 -or $memoryReport.HookedExports.Count -gt 0 -or $memoryReport.UnlinkedModules.Count -gt 0) {
        $memInjectFlags = [System.Collections.Generic.List[string]]::new()
        foreach ($ipe in $memoryReport.InjectedPEHeaders) { [void]$memInjectFlags.Add($ipe) }
        foreach ($um in $memoryReport.UnlinkedModules) { [void]$memInjectFlags.Add($um) }
        foreach ($he in $memoryReport.HookedExports) { [void]$memInjectFlags.Add($he) }
        if ($memoryReport.JvmAttachListenerActive) { [void]$memInjectFlags.Add("Dynamic JVM Attach Socket: $($memoryReport.AttachSocketPath)") }
        $injectedEntries += [PSCustomObject]@{
            FileName = "javaw.exe (Active Memory Process)"
            Flags = $memInjectFlags
        }
    }

    if ($memoryReport.JvmInstrumentationTraces.Count -gt 0 -or $memoryReport.JvmAttachListenerActive) {
        foreach ($jit in $memoryReport.JvmInstrumentationTraces) {
            $jvmFlags += "Memory JVM Trace: $jit"
        }
        if ($memoryReport.JvmAttachListenerActive) {
            $jvmFlags += "Dynamic JVM Attach Listener socket: $($memoryReport.AttachSocketPath)"
        }
    }
}

Write-Host "`r$(' ' * 120)`r" -NoNewline
Write-Host "[5/5] Generating scan summary..." -ForegroundColor Cyan

Write-Host "`r$(' ' * 120)`r" -NoNewline
$timer.Stop()
$totalTime = [math]::Round($timer.Elapsed.TotalSeconds, 1)

if (@($confirmedEntries).Count -gt 0) {
    Show-CategoryHeader -Title "VERIFIED CLEAN MODS" -Count @($confirmedEntries).Count -DotColor Green -CountColor Green
    foreach ($mod in $confirmedEntries) {
        $srcTag = if ($mod.Source) { " ($($mod.Source))" } else { "" }
        Write-Host "  [OK] " -ForegroundColor Green -NoNewline
        Write-Host "$($mod.ModName)$srcTag" -ForegroundColor White -NoNewline
        Write-Host " -> " -ForegroundColor Gray -NoNewline
        Write-Host "$($mod.FileName)" -ForegroundColor DarkGray
    }
    Write-Host ""
}

if (@($unverifiedEntries).Count -gt 0) {
    Show-CategoryHeader -Title "UNVERIFIED COMMUNITY MODS" -Count @($unverifiedEntries).Count -DotColor Yellow -CountColor Yellow
    foreach ($mod in $unverifiedEntries) {
        Write-Host "  [?]  " -ForegroundColor Yellow -NoNewline
        Write-Host "$($mod.FileName)" -ForegroundColor White
    }
    Write-Host ""
}

if (@($flaggedEntries).Count -gt 0) {
    Show-CategoryHeader -Title "HACK & GHOST CLIENTS DETECTED" -Count @($flaggedEntries).Count -DotColor Red -CountColor Red
    foreach ($mod in $flaggedEntries) {
        Show-FlaggedResult -Mod $mod
    }
}

if (@($macroEntries).Count -gt 0) {
    Show-CategoryHeader -Title "PVP MACROS & AUTOMATION MODS" -Count @($macroEntries).Count -DotColor DarkYellow -CountColor Yellow
    foreach ($mod in $macroEntries) {
        Show-MacroResult -Mod $mod
    }
}

if (@($injectedEntries).Count -gt 0) {
    Show-CategoryHeader -Title "RUNTIME & BYTECODE INJECTIONS" -Count @($injectedEntries).Count -DotColor Magenta -CountColor Magenta
    foreach ($mod in $injectedEntries) {
        Show-InjectionResult -Mod $mod
    }
}

if (@($obfEntries).Count -gt 0) {
    Show-CategoryHeader -Title "OBFUSCATED MOD PACKAGES" -Count @($obfEntries).Count -DotColor DarkCyan -CountColor Cyan
    foreach ($mod in $obfEntries) {
        Show-ObfuscationResult -Mod $mod
    }
}

if (@($jvmFlags).Count -gt 0) {
    Show-CategoryHeader -Title "JVM RUNTIME WARNINGS" -Count @($jvmFlags).Count -DotColor Yellow -CountColor Yellow
    Write-Host "┌─────────────────────────────────────────────────────────────────────────────┐" -ForegroundColor DarkYellow
    Write-Host "│ ACTIVE JVM RUNTIME ENVIRONMENT WARNINGS                                     │" -ForegroundColor Yellow
    Write-Host "├─────────────────────────────────────────────────────────────────────────────┤" -ForegroundColor DarkYellow
    foreach ($flag in $jvmFlags) {
        Write-Host "│   • " -ForegroundColor Yellow -NoNewline
        Write-Host $flag -ForegroundColor White
    }
    Write-Host "└─────────────────────────────────────────────────────────────────────────────┘" -ForegroundColor DarkYellow
    Write-Host ""
}

$idGroups = $allModIdentities | Where-Object { $_.ModId -and $_.ModId.Trim() -ne "" } | Group-Object -Property ModId | Where-Object { $_.Count -gt 1 }
if ($idGroups -and @($idGroups).Count -gt 0) {
    Write-Host "┌─────────────────────────────────────────────────────────────────────────────┐" -ForegroundColor DarkRed
    Write-Host "│ DUPLICATE MOD IDENTITY CONFLICT DETECTED                                    │" -ForegroundColor Red
    Write-Host "├─────────────────────────────────────────────────────────────────────────────┤" -ForegroundColor DarkRed
    foreach ($grp in $idGroups) {
        Write-Host "│ Mod ID '$($grp.Name)' is claimed by multiple files:" -ForegroundColor Yellow
        foreach ($item in $grp.Group) {
            Write-Host "│   • $($item.FileName)" -ForegroundColor Gray
        }
    }
    Write-Host "└─────────────────────────────────────────────────────────────────────────────┘" -ForegroundColor DarkRed
    Write-Host ""
}

Write-Host "─ [ SCAN DASHBOARD ] ──────────────────────────────────────────────────────" -ForegroundColor DarkCyan
Write-Host "  Total scanned: $totalFiles mods    Elapsed time: ${totalTime}s" -ForegroundColor Gray
Write-Host

$categories = @(
    @{ Label = "Verified Clean   "; Count = @($confirmedEntries).Count;  Color = "Green" },
    @{ Label = "Unverified Mods  "; Count = @($unverifiedEntries).Count; Color = "Yellow" },
    @{ Label = "Hack/Ghost Client"; Count = @($flaggedEntries).Count;    Color = "Red" },
    @{ Label = "PvP Macros/Auto  "; Count = @($macroEntries).Count;      Color = "DarkYellow" },
    @{ Label = "Loader Injections"; Count = @($injectedEntries).Count;   Color = "Magenta" },
    @{ Label = "Obfuscated Mods  "; Count = @($obfEntries).Count;        Color = "DarkCyan" },
    @{ Label = "JVM Runtime Flags"; Count = @($jvmFlags).Count;          Color = "Yellow" }
)

foreach ($cat in $categories) {
    $bar = Show-Bar -Value $cat.Count -Total $totalFiles
    $pctStr = if ($totalFiles -gt 0) { "$(([math]::Round(($cat.Count / $totalFiles) * 100)))%" } else { "0%" }
    Write-Host "  $($cat.Label) " -ForegroundColor DarkCyan -NoNewline
    Write-Host $bar -ForegroundColor $cat.Color -NoNewline
    Write-Host "  $($cat.Count) ($pctStr)" -ForegroundColor White
}

Write-Host
Write-Host ("─" * 77) -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  Scan completed." -ForegroundColor Cyan
Write-Host ""
Write-Host "  by " -ForegroundColor Gray -NoNewline
Write-Host "APPT" -ForegroundColor Cyan
Write-Host ""
Write-Host ("─" * 77) -ForegroundColor DarkCyan
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor DarkGray
if (-not [Console]::IsInputRedirected) {
    try { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") } catch { }
}