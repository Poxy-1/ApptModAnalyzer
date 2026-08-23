[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null
Clear-Host

$Banner = @"

    █████╗ ██████╗ ██████╗ ████████╗    ███╗   ███╗ ██████╗ ██████╗ 
   ██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝    ████╗ ████║██╔═══██╗██╔══██╗
   ███████║██████╔╝██████╔╝   ██║       ██╔████╔██║██║   ██║██║  ██║
   ██╔══██║██╔═══╝ ██╔═══╝    ██║       ██║╚██╔╝██║██║   ██║██║  ██║
   ██║  ██║██║     ██║        ██║       ██║ ╚═╝ ██║╚██████╔╝██████╔╝
   ╚═╝  ╚═╝╚═╝     ╚═╝        ╚═╝       ╚═╝     ╚═╝ ╚═════╝ ╚═════╝ 
    █████╗ ███╗   ██╗ █████╗ ██╗  ██╗   ██╗███████╗███████╗██████╗   
   ██╔══██╗████╗  ██║██╔══██╗██║  ╚██╗ ██╔╝╚══███╔╝██╔════╝██╔══██╗  
   ███████║██╔██╗ ██║███████║██║   ╚████╔╝   ███╔╝ █████╗  ██████╔╝  
   ██╔══██║██║╚██╗██║██╔══██║██║    ╚██╔╝   ███╔╝  ██╔══╝  ██╔══██╗  
   ██║  ██║██║ ╚████║██║  ██║███████╗██║   ███████╗███████╗██║  ██║  
   ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝╚═╝   ╚══════╝╚══════╝╚═╝  ╚═╝  

"@

Write-Host $Banner -ForegroundColor Cyan
Write-Host ("-" * 77) -ForegroundColor DarkGray
Write-Host ""

$discoveredPaths = [System.Collections.Generic.List[string]]::new()

$mcProcess = try { Get-Process javaw -ErrorAction Stop } catch { $null }
if (-not $mcProcess) { $mcProcess = try { Get-Process java -ErrorAction Stop } catch { $null } }

if ($mcProcess) {
    try {
        $targetPid = ($mcProcess | Select-Object -First 1).Id
        $wmiProc = Get-CimInstance Win32_Process -Filter "ProcessId = $targetPid" -ErrorAction SilentlyContinue
        if ($wmiProc -and $wmiProc.CommandLine) {
            if ($wmiProc.CommandLine -match '--gameDir\s+(?:"([^"]+)"|([^\s]+))') {
                $gDir = if ($matches[1]) { $matches[1] } else { $matches[2] }
                $gMods = Join-Path $gDir "mods"
                if (Test-Path $gMods) { [void]$discoveredPaths.Add($gMods) }
            }
        }
    } catch { }
}

$standardMods = "$env:USERPROFILE\AppData\Roaming\.minecraft\mods"
if ((Test-Path $standardMods) -and -not $discoveredPaths.Contains($standardMods)) {
    [void]$discoveredPaths.Add($standardMods)
}

$curseforgeRoot = "$env:USERPROFILE\curseforge\minecraft\Instances"
if (Test-Path $curseforgeRoot) {
    Get-ChildItem $curseforgeRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $cfMods = Join-Path $_.FullName "mods"
        if ((Test-Path $cfMods) -and -not $discoveredPaths.Contains($cfMods)) {
            [void]$discoveredPaths.Add($cfMods)
        }
    }
}

$modrinthRoot = "$env:APPDATA\com.modrinth.theseus\profiles"
if (Test-Path $modrinthRoot) {
    Get-ChildItem $modrinthRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $mrMods = Join-Path $_.FullName "mods"
        if ((Test-Path $mrMods) -and -not $discoveredPaths.Contains($mrMods)) {
            [void]$discoveredPaths.Add($mrMods)
        }
    }
}

$prismRoot = "$env:APPDATA\PrismLauncher\instances"
if (Test-Path $prismRoot) {
    Get-ChildItem $prismRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $pMods = Join-Path $_.FullName ".minecraft\mods"
        if ((Test-Path $pMods) -and -not $discoveredPaths.Contains($pMods)) {
            [void]$discoveredPaths.Add($pMods)
        }
        $pMods2 = Join-Path $_.FullName "mods"
        if ((Test-Path $pMods2) -and -not $discoveredPaths.Contains($pMods2)) {
            [void]$discoveredPaths.Add($pMods2)
        }
    }
}

$mmcRoot = "$env:APPDATA\MultiMC\instances"
if (Test-Path $mmcRoot) {
    Get-ChildItem $mmcRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $mMods = Join-Path $_.FullName ".minecraft\mods"
        if ((Test-Path $mMods) -and -not $discoveredPaths.Contains($mMods)) {
            [void]$discoveredPaths.Add($mMods)
        }
        $mMods2 = Join-Path $_.FullName "mods"
        if ((Test-Path $mMods2) -and -not $discoveredPaths.Contains($mMods2)) {
            [void]$discoveredPaths.Add($mMods2)
        }
    }
}

$atRoot = "$env:APPDATA\ATLauncher\instances"
if (Test-Path $atRoot) {
    Get-ChildItem $atRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $atMods = Join-Path $_.FullName "mods"
        if ((Test-Path $atMods) -and -not $discoveredPaths.Contains($atMods)) {
            [void]$discoveredPaths.Add($atMods)
        }
    }
}

$gdlRoot = "$env:APPDATA\gdlauncher_next\instances"
if (Test-Path $gdlRoot) {
    Get-ChildItem $gdlRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $gdlMods = Join-Path $_.FullName "mods"
        if ((Test-Path $gdlMods) -and -not $discoveredPaths.Contains($gdlMods)) {
            [void]$discoveredPaths.Add($gdlMods)
        }
    }
}

$featherMods = "$env:APPDATA\.feather\user-mods"
if ((Test-Path $featherMods) -and -not $discoveredPaths.Contains($featherMods)) {
    [void]$discoveredPaths.Add($featherMods)
}

$lunarMods = "$env:USERPROFILE\.lunarclient\offline\multiver\mods"
if ((Test-Path $lunarMods) -and -not $discoveredPaths.Contains($lunarMods)) {
    [void]$discoveredPaths.Add($lunarMods)
}

$badlionMods = "$env:APPDATA\.badlionclient\addons"
if ((Test-Path $badlionMods) -and -not $discoveredPaths.Contains($badlionMods)) {
    [void]$discoveredPaths.Add($badlionMods)
}

$labymodMods = "$env:APPDATA\.minecraft\labymod-neo\addons"
if ((Test-Path $labymodMods) -and -not $discoveredPaths.Contains($labymodMods)) {
    [void]$discoveredPaths.Add($labymodMods)
}

$selectedPath = $null

if ($args.Count -gt 0 -and (Test-Path $args[0])) {
    $selectedPath = (Get-Item $args[0]).FullName
}

if (-not $selectedPath) {
    if ($discoveredPaths.Count -eq 1) {
        Write-Host "Auto-discovered active mods folder: " -ForegroundColor Gray -NoNewline
        Write-Host $discoveredPaths[0] -ForegroundColor Cyan
        Write-Host "Press Enter to scan this folder, or type a custom path:" -ForegroundColor DarkGray
        $userIn = Read-Host "PATH"
        if ([string]::IsNullOrWhiteSpace($userIn)) {
            $selectedPath = $discoveredPaths[0]
        } else {
            $selectedPath = $userIn.Trim('"').Trim("'")
        }
    } elseif ($discoveredPaths.Count -gt 1) {
        Write-Host "Detected Minecraft mods directories:" -ForegroundColor Gray
        for ($i = 0; $i -lt $discoveredPaths.Count; $i++) {
            $p = $discoveredPaths[$i]
            $cnt = (Get-ChildItem $p -Filter "*.jar" -File -ErrorAction SilentlyContinue).Count
            Write-Host "  [$($i+1)] " -ForegroundColor Cyan -NoNewline
            Write-Host "$p " -ForegroundColor White -NoNewline
            Write-Host "($cnt jar files)" -ForegroundColor DarkGray
        }
        Write-Host ""
        Write-Host "Select number [1-$($discoveredPaths.Count)] or enter a custom path:" -ForegroundColor DarkGray
        $userIn = Read-Host "SELECT"
        if ($userIn -match '^\d+$' -and [int]$userIn -ge 1 -and [int]$userIn -le $discoveredPaths.Count) {
            $selectedPath = $discoveredPaths[[int]$userIn - 1]
        } elseif (-not [string]::IsNullOrWhiteSpace($userIn)) {
            $selectedPath = $userIn.Trim('"').Trim("'")
        } else {
            $selectedPath = $discoveredPaths[0]
        }
    } else {
        Write-Host "Enter target mods folder path:" -ForegroundColor Gray
        $userIn = Read-Host "PATH"
        if ([string]::IsNullOrWhiteSpace($userIn)) {
            $selectedPath = $standardMods
        } else {
            $selectedPath = $userIn.Trim('"').Trim("'")
        }
    }
}

if (Test-Path $selectedPath -PathType Leaf) {
    $singleItem = Get-Item $selectedPath
    $modsFolder = $singleItem.DirectoryName
    $jarFiles = @($singleItem)
} elseif (Test-Path $selectedPath -PathType Container) {
    $modsFolder = (Get-Item $selectedPath).FullName
    $jarFiles = Get-ChildItem -Path $modsFolder -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -match '^\.(jar|zip)$' }
} else {
    Write-Host ""
    Write-Host "[ERROR] Target path does not exist or is inaccessible: $selectedPath" -ForegroundColor Red
    Write-Host "Press any key to exit..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host ""
Write-Host "[TARGET] " -ForegroundColor Cyan -NoNewline
Write-Host $selectedPath -ForegroundColor White
Write-Host ""

$totalFiles = $jarFiles.Count
$totalBytes = ($jarFiles | Measure-Object -Property Length -Sum).Sum
$totalMB = [math]::Round(($totalBytes / 1MB), 2)

Write-Host "TARGET INFO:" -ForegroundColor DarkGray
Write-Host "  Archive count : $totalFiles archive files" -ForegroundColor Gray
Write-Host "  Total payload : $totalMB MB" -ForegroundColor Gray

if ($mcProcess) {
    try {
        $p0 = $mcProcess[0]
        $uptime = (Get-Date) - $p0.StartTime
        Write-Host "  Active Process: $($p0.Name) (PID $($p0.Id))" -ForegroundColor Gray
        Write-Host "  Process Uptime: $($uptime.Hours)h $($uptime.Minutes)m $($uptime.Seconds)s" -ForegroundColor Gray
    } catch { }
}

Write-Host ""
Write-Host ("-" * 77) -ForegroundColor DarkGray
Write-Host ""

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
    public static Regex FullwidthRegex = new Regex(@"[\uFF01-\uFF5E\uFFE0-\uFFE6\u200B-\u200F\uFEFF\u2060\u180E]{2,}", RegexOptions.Compiled);
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
        "org.jnativehook.GlobalScreen", "org/jnativehook", "JNativeHook",
        "today/opai", "wtf/moonlight", "pw/cinque", "net/ccbluex",
        "me/zeroeightsix/kami", "com/alan/clients", "net/minecraft/injection",
        "org/spongepowered/asm/mixin/injection", "me/bush/eventbus",
        "pandaware", "moonClient", "azuraclient", "impactclient",
        "konas/client", "rusherhack", "riseclient", "astolfo/client",
        "futureclient", "bleachhack", "mathax", "tenacity",
        "kura/client", "exos/client", "pulsar/client", "cosmic/client",
        "itami/client", "lowkey/client", "whiteout/client", "breeze/client",
        "mango/client", "nyrex/client", "remnant/client", "achilles/client",
        "mist/client", "zorim/client", "volt/client", "vril/client",
        "osmium/client", "zenith/client", "cymer/client", "silk/client",
        "ravenb", "ravenbplus", "ravenweave", "ravenfabric",
        "com/github/bettercombat", "me/dqrkis", "club/astolfo",
        "net/novoline", "dev/intent", "com/vapeclient", "dev/vape",
        "me/intent", "xyz/dqrkis", "net/intent",
        "speckey", "crystalware", "grimoptimizer",
        "virginclient", "pugger/client", "francium/client",
        "onyxclient", "platinium/client", "aspiraargoon",
        "mera/private", "scrims/client", "gardenia/client",
        "sakurwa/client", "zoomies/client",
        "argonclient", "cwclient", "cwhack",
        "flashcrystal", "herosanchor", "hcscrc",
        "clientsidedcrystals", "airanchormacro",
        "slinky.dll", "drip.dll", "kura.dll", "vape.dll",
        "wholesome.dll", "speckey.dll", "breeze.dll",
        "itami.dll", "entropy.dll", "dream.dll", "slap.dll"
    };

    private static readonly string[] CheatConfigKeywords = new string[] {
        "\"killaura\":", "\"aimassist\":", "\"autocrystal\":", "\"triggerbot\":",
        "\"targethud\":", "\"clickgui\":", "\"pingspoof\":", "\"fakelag\":",
        "\"selfdestruct\":", "\"bhop\":", "\"flight\":", "\"speedhack\":",
        "\"scaffold\":", "\"fastplace\":", "\"reach\":", "\"noslow\":",
        "[Module] KillAura", "[Module] AutoCrystal", "[Module] AimAssist",
        "[Module] TriggerBot", "[Module] AutoTotem", "[Module] Velocity",
        "\"autototem\":", "\"autoarmor\":", "\"shieldbreaker\":", "\"autoclicker\":",
        "\"maceswap\":", "\"stunslam\":", "\"doubleanchor\":", "\"safeanchor\":",
        "\"autopot\":", "\"autopotrefill\":", "\"elytraswap\":", "\"autofirework\":",
        "\"freecam\":", "\"xray\":", "\"esp\":", "\"tracers\":", "\"chams\":",
        "\"fullbright\":", "\"nuker\":", "\"baritone\":", "\"antihunger\":",
        "\"criticals\":", "\"nofall\":", "\"timer\":", "\"step\":",
        "\"bowaimbot\":", "\"crystalaura\":", "\"anchoraura\":", "\"bedaura\":",
        "\"autodisconnect\":", "\"holetp\":", "\"autoeat\":", "\"autopearl\":",
        "\"automine\":", "\"backtrack\":", "\"packetfly\":", "\"blink\":",
        "\"antivoid\":", "\"stashfinder\":", "\"pearlclip\":", "\"burrow\":",
        "\"windcharge\":", "\"macesmash\":", "\"autocrafter\":", "\"breezerod\":",
        "[Module] Scaffold", "[Module] Speed", "[Module] Flight",
        "[Module] NoFall", "[Module] ESP", "[Module] Tracers",
        "[Module] Nuker", "[Module] Disabler", "[Module] Freecam",
        "[Module] ShieldBreaker", "[Module] AutoPot", "[Module] AutoArmor",
        "[Module] AutoDoubleHand", "[Module] MaceSwap", "[Module] StunSlam",
        "[Module] TargetStrafe", "[Module] BackTrack", "[Module] PacketMine",
        "[Module] WindCharge", "[Module] AutoAnchor", "[Module] GrimDisabler",
        "[Module] VulcanDisabler", "[Module] PolarDisabler", "[Module] MatrixDisabler"
    };

    private static readonly string[] MixinHandlerSignatures = new string[] {
        "handler$", "mixin$", "@Overwrite", "@Redirect", "@Inject",
        "@ModifyArg", "@ModifyVariable", "@WrapOperation", "@ModifyConstant",
        "@ModifyReturnValue", "@ModifyExpressionValue", "@WrapWithCondition",
        "@Slice", "@At", "@Coerce", "@Shadow", "@Unique", "@Final",
        "@Accessor", "@Invoker", "@Mixin", "@Pseudo",
        "mixin.refmap.json", "mixins.json", "refmap.json",
        "handler$inject", "handler$redirect", "invokeSpecial"
    };

    private static readonly string[] CheatGUISignatures = new string[] {
        "ClickGUI", "Watermark", "ArrayList", "TargetHUD", "ColorPicker",
        "ConfigManager", "HudEditor", "KeybindManager", "ModuleList", "CategoryPanel",
        "NotificationManager", "AltManager", "AccountSwitcher", "SessionChanger",
        "TabGUI", "WindowUI", "PanelRenderer", "DropdownGUI", "ModuleRenderer",
        "HUDComponent", "RadarModule", "ArmorHUD", "PotionHUD", "CombatHUD",
        "WaypointRenderer", "NametagRenderer", "CrosshairOverlay", "InfoRenderer",
        "DraggableComponent", "SettingSlider", "SettingCheckbox", "ThemeManager",
        "FontRenderer", "CustomFont", "GlyphPage", "ModCategory",
        "ModuleManager", "EventManager", "CommandManager", "FriendManager",
        "MacroManager", "WaypointManager", "ProxyManager"
    };

    private static readonly string[] NetworkEndpointSignatures = new string[] {
        "api.novaclient.lol", "novoware.eu", "hellclient.eu", "vape.gg",
        "intent.store", "discord.com/api/webhooks/", "127.0.0.1:",
        "java/net/ServerSocket", "java/net/Socket", "io/netty/channel/local",
        "riseclient.com", "astolfo.club", "dqrkis.xyz", "prestigeclient.vip",
        "doomsdayclient.com", "198macros.com", "novaclient.lol", "speckey.shop",
        "thevaultofficial.vercel.app", "liquidbounce.net", "fdpclient.cn",
        "aristois.net", "wurstclient.net", "meteorclient.com", "futureclient.net",
        "rusherhack.org", "catbox.moe", "pixeldrain.com", "anonfiles.com",
        "gofile.io", "file.io", "transfer.sh", "rentry.co", "paste.ee",
        "hastebin.com", "ghostbin.co", "0x0.st", "uploadfiles.io",
        "pastebin.com/raw/", "discord.gg/", "raw.githubusercontent.com",
        "java/net/DatagramSocket", "java/net/HttpURLConnection",
        "javax/net/ssl/HttpsURLConnection", "java/net/URL",
        "io/netty/bootstrap/Bootstrap", "io/netty/handler/codec",
        "java/nio/channels/SocketChannel", "java/nio/channels/DatagramChannel"
    };

    private static readonly string[] JvmInstrumentationSignatures = new string[] {
        "java/lang/instrument/Instrumentation", "java.lang.instrument.Instrumentation",
        "redefineClasses", "retransformClasses", "Attach Listener",
        "com/sun/tools/attach", "sun.tools.attach",
        "java/lang/instrument/ClassFileTransformer", "addTransformer",
        "premain", "agentmain", "MANIFEST.MF/Premain-Class", "MANIFEST.MF/Agent-Class",
        "VirtualMachine.attach", "VirtualMachine.loadAgent",
        "com/sun/jdi", "sun/jvmstat", "com/sun/tools/jdi",
        "sun.management.Agent", "com.sun.management",
        "jdk.internal.agent", "java.management",
        ".java_pid", "jdwp", "JDWP", "dt_socket"
    };

    private static readonly string[] JNativeHookMemorySignatures = new string[] {
        "org.jnativehook.GlobalScreen", "org/jnativehook/GlobalScreen",
        "org/jnativehook/NativeHookException", "org/jnativehook/keyboard/NativeKeyEvent",
        "org/jnativehook/mouse/NativeMouseEvent", "JNativeHook",
        "org/jnativehook/keyboard/NativeKeyListener", "org/jnativehook/mouse/NativeMouseListener",
        "org/jnativehook/mouse/NativeMouseMotionListener", "org/jnativehook/mouse/NativeMouseWheelListener",
        "org/jnativehook/NativeInputEvent", "org/jnativehook/NativeSystem",
        "registerNativeHook", "unregisterNativeHook", "addNativeKeyListener",
        "addNativeMouseListener", "addNativeMouseMotionListener",
        "com/github/kwhat/jnativehook", "com.github.kwhat.jnativehook"
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
            int regionCount = 0;
            int maxRegions = 50000;
            var scanTimer = System.Diagnostics.Stopwatch.StartNew();

            while (currentAddr < maxAddr) {
                if (regionCount++ > maxRegions || scanTimer.ElapsedMilliseconds > 30000) break;
                MEMORY_BASIC_INFORMATION mbi;
                int res = VirtualQueryEx(hProcess, (IntPtr)currentAddr, out mbi, (uint)Marshal.SizeOf(typeof(MEMORY_BASIC_INFORMATION)));
                if (res == 0) break;

                long baseAddr = mbi.BaseAddress.ToInt64();
                long regionSize = mbi.RegionSize.ToInt64();
                if (regionSize <= 0) { currentAddr += 65536; continue; }

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
        string normEntry = entryName.Replace('\\', '/');
        string dotEntry = normEntry.Replace('/', '.');
        string fn = entryName;
        int lastSlash = fn.LastIndexOf('/');
        if (lastSlash >= 0) fn = fn.Substring(lastSlash + 1);
        string fnNoExt = fn.EndsWith(".class", StringComparison.OrdinalIgnoreCase) ? fn.Substring(0, fn.Length - 6) : fn;

        foreach (string p in PatternSet) {
            if (string.IsNullOrEmpty(p)) continue;
            if (fn.Equals(p, StringComparison.OrdinalIgnoreCase) ||
                fnNoExt.Equals(p, StringComparison.OrdinalIgnoreCase) ||
                normEntry.IndexOf(p, StringComparison.OrdinalIgnoreCase) >= 0 ||
                dotEntry.IndexOf(p, StringComparison.OrdinalIgnoreCase) >= 0) {
                patterns.Add(p);
            }
        }
        foreach (string m in MacroSet) {
            if (string.IsNullOrEmpty(m)) continue;
            if (fn.Equals(m, StringComparison.OrdinalIgnoreCase) ||
                fnNoExt.Equals(m, StringComparison.OrdinalIgnoreCase) ||
                normEntry.IndexOf(m, StringComparison.OrdinalIgnoreCase) >= 0 ||
                dotEntry.IndexOf(m, StringComparison.OrdinalIgnoreCase) >= 0) {
                macros.Add(m);
            }
        }
    }

    public static void ScanClassComprehensive(
        byte[] raw,
        HashSet<string> patterns,
        HashSet<string> macros,
        HashSet<string> strings,
        HashSet<string> fullwidth,
        HashSet<string> encodedHits,
        ref int reflectionScore,
        ref int highEntropyCount,
        Dictionary<string, bool> heuristics
    ) {
        if (raw == null || raw.Length < 10) return;
        if (raw.Length > 1024 && CalcEntropy(raw) >= 7.35) {
            highEntropyCount++;
        }

        List<string> cp = ParseConstantPool(raw);
        bool hasMathAtan2 = false;
        bool hasSensitivityGcd = false;
        bool hasRandomGaussian = false;

        for (int i = 0; i < cp.Count; i++) {
            string s = cp[i];
            if (string.IsNullOrEmpty(s)) continue;

            if (s.IndexOf("atan2", StringComparison.OrdinalIgnoreCase) >= 0 || s.IndexOf("Math.atan2", StringComparison.OrdinalIgnoreCase) >= 0) hasMathAtan2 = true;
            if (s.IndexOf("nextGaussian", StringComparison.OrdinalIgnoreCase) >= 0 || s.IndexOf("RandomCPS", StringComparison.OrdinalIgnoreCase) >= 0) hasRandomGaussian = true;
            if (s.IndexOf("mouseSensitivity", StringComparison.OrdinalIgnoreCase) >= 0 || s.IndexOf("gcdAimAssist", StringComparison.OrdinalIgnoreCase) >= 0 || s.IndexOf("0.6F", StringComparison.OrdinalIgnoreCase) >= 0 || s.IndexOf("8.0F", StringComparison.OrdinalIgnoreCase) >= 0) hasSensitivityGcd = true;

            foreach (string p in PatternSet) {
                if (!string.IsNullOrEmpty(p) && s.IndexOf(p, StringComparison.OrdinalIgnoreCase) >= 0) {
                    patterns.Add(p);
                }
            }

            foreach (string m in MacroSet) {
                if (!string.IsNullOrEmpty(m) && s.IndexOf(m, StringComparison.OrdinalIgnoreCase) >= 0) {
                    macros.Add(m);
                }
            }

            foreach (string c in ContentSet) {
                if (!string.IsNullOrEmpty(c) && s.IndexOf(c, StringComparison.OrdinalIgnoreCase) >= 0) {
                    strings.Add(c);
                }
            }

            if (FullwidthRegex != null && FullwidthRegex.IsMatch(s)) {
                fullwidth.Add(s);
            }

            if (Base64Regex != null && s.Length >= 20 && Base64Regex.IsMatch(s)) {
                try {
                    byte[] decoded = Convert.FromBase64String(s);
                    string decStr = Encoding.UTF8.GetString(decoded);
                    if (!string.IsNullOrEmpty(decStr)) {
                        foreach (string c in ContentSet) {
                            if (!string.IsNullOrEmpty(c) && decStr.IndexOf(c, StringComparison.OrdinalIgnoreCase) >= 0) {
                                encodedHits.Add(s + " -> " + c);
                            }
                        }
                    }
                } catch { }
            }

            if (ReflectionSet != null && ReflectionSet.Contains(s)) {
                reflectionScore++;
            }
        }

        if (hasMathAtan2 && hasSensitivityGcd) {
            patterns.Add("SilentAimMatrix");
        }
        if (hasRandomGaussian) {
            patterns.Add("JitterClicker");
        }
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
'@
try {
    Add-Type -TypeDefinition $fastScannerSource
} catch {
    Write-Host "[ERROR] failed to compile the scanner engine -- make sure .NET Framework is installed" -ForegroundColor Red
    Write-Host "        error: $($_.Exception.Message)" -ForegroundColor DarkRed
    Write-Host "Press any key to exit..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

function Get-FileDigest {
    param([string]$Target)
    $sha1 = (Get-FileHash -Path $Target -Algorithm SHA1).Hash
    $sha256 = (Get-FileHash -Path $Target -Algorithm SHA256).Hash
    $sha512 = (Get-FileHash -Path $Target -Algorithm SHA512).Hash
    return @{
        SHA1    = $sha1
        SHA256  = $sha256
        SHA512  = $sha512
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
    "jdk/internal/misc/Unsafe", "java/lang/invoke/LambdaMetafactory",
    "java/lang/invoke/ConstantCallSite", "java/lang/invoke/MutableCallSite",
    "java/lang/invoke/VolatileCallSite", "java/security/AccessController",
    "doPrivileged", "sun.misc.Unsafe", "jdk.internal.misc.Unsafe",
    "sun.reflect.Reflection", "sun.reflect.ReflectionFactory",
    "jdk.internal.reflect.ReflectionFactory", "defineAnonymousClass",
    "objectFieldOffset", "staticFieldOffset", "staticFieldBase",
    "ensureClassInitialized", "arrayBaseOffset", "arrayIndexScale",
    "addressSize", "pageSize", "getIntVolatile", "putIntVolatile",
    "getObjectVolatile", "putObjectVolatile", "compareAndSwapObject",
    "compareAndSwapInt", "compareAndSwapLong", "park", "unpark",
    "loadLibrary", "load", "mapLibraryName", "findNative", "RegisterNatives",
    "sun/reflect/CallerSensitive", "jdk/internal/reflect/CallerSensitive",
    "java/lang/invoke/MethodType", "java/lang/invoke/MethodHandles$Lookup",
    "lookupClass", "findStatic", "findVirtual", "findSpecial", "findConstructor",
    "findGetter", "findSetter", "findStaticGetter", "findStaticSetter",
    "unreflect", "unreflectSpecial", "unreflectConstructor", "unreflectGetter",
    "unreflectSetter", "bind", "asType", "asCollector", "asSpreader"
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
    "wurstclient.net", "meteorclient.com", "futureclient.net", "rusherhack.org",
    "tenacity.dev", "kamiblue.org", "lambda-client.com", "bleachhack.org",
    "mathaxclient.xyz", "phobos.eu", "salhack.ch", "aresclient.com",
    "gamesense.pub", "cookieclient.xyz", "cleanwater.gg", "greaj.xyz",
    "gambleclient.com", "krypton.dev", "virel.dev", "catlean.net",
    "asteria.vip", "virginclient.fun", "argonclient.net", "cwhack.com",
    "crystalware.top", "grimoptimizer.com", "lwfh.xyz", "198macro.com",
    "speckey.net", "novaclient.top", "hellclient.top", "novoware.net",
    "vapeclient.vip", "whiteout.gg", "breeze.rip", "lowkey.gg",
    "ravenweave.cf", "ravenbplus.com", "itami.vip", "exos.rip",
    "kura.rip", "pulsarclient.com", "cosmicclient.com", "nyrex.top",
    "achillesclient.com", "mistclient.top", "zorimclient.top", "voltclient.top",
    "vrilclient.top", "osmiumclient.top", "zenithclient.top", "cymerclient.top",
    "gardeniaclient.top", "sakurwaclient.top", "silkclient.top", "zoomiesclient.top",
    "vapeclient.com", "astolfoclient.com", "riseclient.info", "tenacityclient.com",
    "dqrkis.com", "crystalware.cc", "speckey.cc", "wholesomecheats.xyz",
    "cleanwatercheats.com", "kryptonclient.com", "virgincheats.net", "hellclient.cc",
    "novoware.cc", "grimdisabler.com", "vulcandisabler.org", "matrixdisabler.top",
    "polardisabler.net", "verusdisabler.com", "intavedisabler.com", "watchdogdisabler.top",
    "mediafire.com/file/", "mega.nz/file/", "drive.google.com/file/"
)

$script:flaggedIdentifiers = @(
    "AimAssist", "AnchorTweaks", "AutoAnchor", "AutoCrystal", "AutoDoubleHand", "JDWP.VirtualMachine.AllModules",
    "AutoHitCrystal", "AutoPot", "AutoTotem", "AutoArmor", "InventoryTotem",
    "LegitTotem", "PingSpoof", "SelfDestruct",
    "ShieldBreaker", "TriggerBot", "AxeSpam", "WebMacro",
    "FastPlace", "WalskyOptimizer", "WalksyOptimizer", "walsky.optimizer",
    "WalksyCrystalOptimizerMod", "Donut", "Replace Mod",
    "ShieldDisabler", "SilentAim", "Totem Hit", "Wtap", "FakeLag", "dev.virel", "orchard",
    "BlockESP", "dev.krypton", "dev/krypton", "skid.krypton", "skid/krypton", "AntiMissClick",
    "LagReach", "PopSwitch", "SprintReset", "ChestSteal", "AntiBot",
    "ElytraSwap", "FastXP", "FastExp", "Refill", "AirAnchor",
    "jnativehook", "FakeInv", "HoverTotem", "AutoClicker", "AutoFirework",
    "PackSpoof", "Antiknockback", "catlean",
    "AuthBypass", "Asteria", "Prestige", "AutoEat", "AutoMine",
    "MaceSwap", "Macro198", "StunSlam", "SafeAnchor", "DoubleAnchor", "AutoTPA", "BaseFinder", "Xenon", "gypsy",
    "AutoPotRefill", "KeyPearl", "AutoNethPot", "AutoDtap",
    "AutoWeb", "AnchorAction",
    "org.chainlibs.module.impl.modules.Crystal.Y",
    "org.chainlibs.module.impl.modules.Crystal.bF",
    "org.chainlibs.module.impl.modules.Crystal.bM",
    "org.chainlibs.module.impl.modules.Crystal.bY",
    "org.chainlibs.module.impl.modules.Crystal.bq",
    "org.chainlibs.module.impl.modules.Crystal.cv",
    "org.chainlibs.module.impl.modules.Crystal.o",
    "org.chainlibs.module.impl.modules.Blatant.I",
    "org.chainlibs.module.impl.modules.Blatant.bR",
    "org.chainlibs.module.impl.modules.Blatant.bx",
    "org.chainlibs.module.impl.modules.Blatant.cj",
    "org.chainlibs.module.impl.modules.Blatant.dk",
    "imgui.gl3", "imgui.glfw",
    "BowAim", "Criticals", "Fakenick", "FakeItem",
    "invsee", "ItemExploit", "Hellion", "hellion",
    "LicenseCheckMixin", "ClientPlayerInteractionManagerAccessor",
    "ClientPlayerEntityMixim", "dev.gambleclient", "obfuscatedAuth",
    "phantom-refmap.json", "xyz.greaj",
    "CWClient", "Crystalware", "CrystalwareClient", "GrimOptimizer", "LWFHAuto", "AnchorPredict",
    "PopPredictor", "CrystalPlaceDelay", "HitCrystalOptimizer", "FastCrystalMod", "AutoDoubleHandMod",
    "ShieldBreakerMod", "AxeSwapMod", "MaceSwapMod", "SpearSwapMod", "WebMacroMod", "AutoTotemMod",
    "AnchorMacroMod", "StunSlamMod", "JDWPAgent", "NativeInjector", "PipeBridge", "NamedPipeClient",
    "DynamicSynthesizer", "MemoryScrubber", "BytecodePatcher",
    "MaceFallMultiplier", "WindChargeLauncher", "BreezeRodSwitcher", "CrafterPacketSpam", "MaceSmashHelper",
    "WindChargeBurst", "SpearChargeSpoof", "AutoCrafterDupe", "MaceDamageCalculator", "WindChargeBoost",
    "MaceComboTiming", "BreezeRodSwitch", "SmartCrit", "AutoBlock", "ComboMode",
    "BurrowHelper", "HoleFillerMod", "PacketCancelMod", "BackTrackMod", "PearlClipMod",
    "BoatAuraMod", "EntityControlMod", "AntiCactusMod", "AutoLeaveMod",
    "SpeedMineMod", "FastLadderMod", "NoSlowdownMod", "BhopMod",
    "PacketFlyMod", "PhaseMod", "InstantBreakMod", "NukerMod",
    "TracersMod", "StorageESPMod", "WallHackMod", "AutoArmorMod",
    "SilentRotationsMod", "ClickAuraMod", "MultiAuraMod", "ForceFieldMod",
    "VelocitySpoofMod", "AutoPearlMod", "AutoGapMod", "AutoSwordMod",
    "SelfTrapMod", "AntiAFKMod", "ChestStealerMod", "InvManagerMod",
    "GrimFastBreakHelper", "GrimNoSlowBypass", "GrimTimerSpoofer", "GrimReachMatrix",
    "GrimHitboxMultiplier", "GrimVelocityReducer", "GrimAirPlaceMatrix", "GrimScaffoldTower",
    "GrimPacketCancelQueue", "GrimEntityControlHook", "VulcanScaffoldTower", "VulcanSpeedMatrix",
    "VulcanFlyBypass", "VulcanGlideHelper", "VulcanAuraRotator", "VulcanAutoClickerJitter",
    "VulcanStrafeSpoofer", "VulcanTimerMatrix", "VulcanNoSlowHelper", "PolarKeepSprintHelper",
    "PolarVelocityReducer", "PolarMotionMatrix", "PolarAimAssistBypass", "PolarReachBooster",
    "PolarScaffoldHelper", "PolarFastBreakMatrix", "MatrixFastUseBypass", "MatrixSpeedMatrix",
    "MatrixFlyHelper", "MatrixKillAuraRotator", "MatrixVelocityBypass", "MatrixTimerBypass",
    "MatrixNoFallHelper", "KarhuCombatBypass", "KarhuMovementBypass", "KarhuScaffoldBypass",
    "KarhuVelocityBypass", "KarhuTimerBypass", "IntavePhysicsEngine", "IntaveRaytraceHelper",
    "IntaveVelocityReducer", "IntaveAimMatrix", "IntaveTimerModifier", "WatchdogFastBridge",
    "WatchdogScaffoldTower", "WatchdogSpeedHelper", "WatchdogAuraMatrix", "WatchdogDisablerQueue",
    "VerusCombatHelper", "VerusMovementMatrix", "VerusScaffoldHelper", "VerusDisablerMatrix",
    "SpartanCombatMatrix", "SpartanMovementMatrix", "SpartanDisablerHelper", "NegativityPacketMatrix",
    "FlapDisablerHelper", "SparkyDisablerHelper", "NemesisDisablerHelper", "MorganDisablerHelper",
    "NovowareClient", "HellClient", "OpaiClient", "22qqClient",
    "CWHackClient", "PlatiniumClient", "OnyxClient", "PuggerClient",
    "FranciumClient", "PugwareClient", "VirginsPremium", "GrandlineVirgin",
    "AspirahArgoon", "MeraPrivateClient", "ScrimsClient", "ZorimClient", "VoltClient",
    "VrilClient", "OsmiumClient", "ZenithClient", "CymerClient",
    "3Q1PotClient", "GardeniaClient", "SakurwaClient", "SilkClient", "ZoomiesClient",
    "NiggaHackClient", "NyrexClient", "RemnantClient", "4EClient", "AchillesClient", "MistClient",
    "RavenBPlus", "RavenB3", "RavenWeave", "RavenFabric",
    "KuraClient", "ExosClient", "PulsarClient", "CosmicClient", "ItamiClient",
    "LowkeyClient", "WhiteoutClient", "BreezeClient", "MangoClient",
    "GothajClient", "Gothaj", "AstraWare", "AstralClient", "Astralux",
    "HydraClient", "LuneX", "MeiLaaPlus", "NoxxClient", "ThoriumClient", "WaterClient",
    "HCSCRCrystalOptimizer", "FlashCrystalOptimizer", "HerosAnchorOptimizer",
    "ClientSidedCrystals", "AirAnchorMacro", "CrafterDupeExploit", "WindChargeBurstHelper",
    "MaceFallMultiplierModule", "MaceDamageCalculator", "GrimStrafeBypass", "GrimAirPlaceBypass",
    "GrimPacketQueue", "AutoMaceCombo", "MaceHitDelay", "WindChargeLaunchTiming",
    "BreezeRodSwitchDelay", "AutoBreachDamage", "ShieldStunCalculator",
    "MixinMinecraftClient", "MixinClientPlayerEntity", "MixinClientPlayerInteractionManager",
    "MixinKeyboard", "MixinMouse", "MixinInGameHud", "MixinWorldRenderer", "MixinGameRenderer",
    "MixinLivingEntity", "MixinClientConnection", "MixinPlayerListEntry", "MixinAbstractBlockState",
    "MixinCamera", "MixinLightmapTextureManager", "MixinHeldItemRenderer", "MixinChatScreen",
    "MixinPacketByteBuf", "MixinClientWorld", "MixinSoundSystem", "MixinScreen",
    "MixinClientPlayNetworkHandler", "MixinEntityRenderer", "MixinCameraSubmersionType",
    "MixinBlockModelRenderer", "MixinParticleManager", "MixinLightmapTexture",
    "MixinLivingEntityRenderState", "MixinClientWorldProperties", "MixinPlayerInteractEntityC2S",
    "MixinPlayerActionC2S", "MixinPlayerMoveC2S", "MixinHandSwingC2S", "MixinClickSlotC2S",
    "MixinClientCommandC2S", "MixinUpdateSelectedSlotC2S", "MixinVehicleMoveC2S",
    "MixinTeleportConfirmC2S", "MixinHandledScreen", "MixinDrawContext", "MixinTextRenderer",
    "MixinSoundManager", "MixinKeyBinding", "MixinOptionInstance",
    "VapeV4", "VapeV3", "VapeLite", "EntropyClient", "DripClient", "DripLite", "SlapClient",
    "SlinkyClient", "WalksyCrystal", "KuriumClient", "LithiumClient", "YukawaClient",
    "CryptClient", "DreamClient", "AnticClient", "SpookClient", "HarpoonClient",
    "BozeClient", "PhobosClient", "PyroClient", "AugustusClient", "RiseClient",
    "TenacityClient", "LiquidBounceNext", "NightXClient", "FDPClient", "SkidXClient",
    "AristoisClient", "MeteorClient", "BleachHackClient", "MathaxClient", "BlackoutClient",
    "CoffeeClient", "RavenXDGhost", "JitterClicker", "LeftClickerRandomizer", "RightClickerRandomizer",
    "AimAssistAngle", "PitchInterpolator", "YawInterpolator", "RotationAngleSmooth",
    "SilentAimMatrix", "KeepSprintSync", "EagleBridgeHelper", "FastBridgeEdge",
    "ScaffoldTowerSpeed", "ScaffoldExpandReach", "BackTrackRingBuffer", "HitboxExpanderRay",
    "ReachPacketDelta", "CriticalsPacketJump", "WTapSyncDelay", "STapSyncDelay",
    "AutoTotemInventorySync", "AutoCrystalWallRaytrace", "AutoCrystalTargetQueue",
    "AutoAnchorGlowstoneCount", "BedBombDimensionBypass", "ElytraFlyPitchClamp",
    "BoatFlyPacketVelocity", "BlinkPacketQueue", "FakeLagPingDelta", "DisablerTransactionDrop",
    "InventoryMoveScreenOverride", "NoSlowItemSpeedClamp", "FastPlaceTickReset",
    "FastBreakDamageBoost", "NukerMultiBlockQueue", "ESPGlowShader", "TracersVectorRenderer",
    "XRayBlockListFilter", "ChamsDepthStencil", "FullbrightGammaOverride",
    "Skidfuscator", "Paramorphism", "Branchlock", "Caesium", "RadonObfuscator",
    "SuperblaubeereObfuscator", "SmokeObfuscator", "AndromedaObfuscator", "CyberObfuscator",
    "BytecodeFixer", "DexPatcher", "RetroguardObf", "JBcryptObf", "AllatoriObfuscator",
    "ZKMObfuscator", "StringerObfuscator", "JPhantomObfuscator", "DashOObfuscator",
    "SandMarkObfuscator", "ProGuardObfuscator",
    "GrimVelocityDisabler", "GrimFastBreakDisabler", "VulcanGlideDisabler", "PolarKeepSprintDisabler",
    "MatrixFastUseDisabler", "WatchdogMovementDisabler", "IntaveTimerDisabler", "SpartanCombatDisabler",
    "NegativityPacketDisabler", "NCPInventoryDisabler", "AACVelocityDisabler", "VerusCombatDisabler",
    "FlapDisabler", "SparkyDisabler", "NemesisDisabler", "MorganDisabler", "KarhuMovementDisabler",
    "あ.class", "い.class", "う.class", "え.class", "お.class",
    "か.class", "き.class", "く.class", "け.class", "こ.class",
    "さ.class", "し.class", "す.class", "せ.class", "そ.class",
    "た.class", "ち.class", "つ.class", "て.class", "と.class",
    "な.class", "に.class", "ぬ.class", "ね.class", "の.class",
    "は.class", "ひ.class", "ふ.class", "へ.class", "ほ.class",
    "ま.class", "み.class", "む.class", "め.class", "も.class",
    "や.class", "ゆ.class", "よ.class",
    "ら.class", "り.class", "る.class", "れ.class", "ろ.class",
    "わ.class", "を.class", "ん.class",
    "が.class", "ぎ.class", "ぐ.class", "げ.class", "ご.class",
    "ざ.class", "じ.class", "ず.class", "ぜ.class", "ぞ.class",
    "だ.class", "ぢ.class", "づ.class", "де.class", "ど.class",
    "ば.class", "び.class", "ぶ.class", "べ.class", "ぼ.class",
    "ぱ.class", "ぴ.class", "ぷ.class", "ぺ.class", "ぽ.class",
    "ア.class", "イ.class", "ウ.class", "エ.class", "オ.class",
    "カ.class", "キ.class", "ク.class", "ケ.class", "コ.class",
    "サ.class", "シ.class", "ス.class", "セ.class", "ソ.class",
    "タ.class", "チ.class", "ツ.class", "テ.class", "ト.class",
    "ナ.class", "ニ.class", "ヌ.class", "ネ.class", "ノ.class",
    "ハ.class", "ヒ.class", "フ.class", "ヘ.class", "ホ.class",
    "マ.class", "ミ.class", "ム.class", "メ.class", "モ.class",
    "ヤ.class", "ユ.class", "ヨ.class",
    "ラ.class", "リ.class", "ル.class", "レ.class", "ロ.class",
    "ワ.class", "ヲ.class", "ン.class",
    "가.class", "나.class", "다.class", "라.class", "마.class",
    "바.class", "사.class", "아.class", "자.class", "차.class",
    "카.class", "타.class", "파.class", "하.class",
    "а.class", "б.class", "в.class", "г.class", "д.class",
    "е.class", "ж.class", "з.class", "и.class", "к.class",
    "л.class", "м.class", "н.class", "о.class", "п.class",
    "р.class", "с.class", "т.class", "у.class", "ф.class",
    "х.class", "ц.class", "ч.class", "ш.class", "щ.class",
    "ъ.class", "ы.class", "ь.class", "э.class", "ю.class", "я.class",
    "α.class", "β.class", "γ.class", "δ.class", "ε.class",
    "ζ.class", "η.class", "θ.class", "ι.class", "κ.class",
    "λ.class", "μ.class", "ν.class", "ξ.class", "ο.class",
    "π.class", "ρ.class", "σ.class", "τ.class", "υ.class",
    "φ.class", "χ.class", "ψ.class", "ω.class"
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
    "SwordBlockMacro", "AxeSpamMacro", "BowSpamMacro", "CrossbowAutoLoad",
    "AutoMaceSwapMacro", "QuickStrikeMacro", "SafeAnchorMacro", "DoubleAnchorMacro",
    "AutoNethPotMacro", "KeyPearlMacro", "AutoWebMacro", "WalksyOptimizerMacro",
    "AutoLootYeeter", "FastBlockPlaceMacro", "AutoBreachMacro", "SmartCritMacro",
    "DamageTickMacro", "TotemSlotManager", "SmoothRotationMacro", "AntiWeaknessMacro",
    "AutoMineMacro", "AutoEatMacro", "AutoTotemMacro", "AutoArmorMacro", "AutoSwordMacro",
    "AutoToolMacro", "AutoWeaponMacro", "AutoRespawnMacro", "AutoFishMacro", "AutoPotMacro",
    "AutoCrystalMacro", "AutoAnchorMacro", "AutoBedMacro", "AutoDoubleHandMacro",
    "AutoFireworkMacro", "AutoElytraMacro", "AutoOffhandMacro", "AutoRefillMacro",
    "AutoCraftMacro", "AutoDropMacro", "InventoryTotemMacro", "FastPlaceMacro", "FastBreakMacro",
    "SilentAimMacro", "TriggerbotMacro", "AimAssistMacro", "ClickerMacro", "StrafeMacro",
    "WTapMacro", "STapMacro", "JumpResetMacro",
    "HotbarRefillMacro", "InventorySwapMacro", "TotemCycleMacro", "AnchorCycleMacro",
    "BedCycleMacro", "CobwebPlaceMacro", "ObsidianPlaceMacro", "CrystalBreakMacro",
    "CrystalPlaceMacro", "GlowstoneChargeMacro", "AnchorExplodeMacro", "PearlThrowMacro",
    "MaceHitMacro", "ShieldDisableMacro", "AxeBreakShieldMacro", "FireworkBoostMacro",
    "ElytraTakeoffMacro", "ArmorEquipMacro", "HealthPotThrowMacro", "SpeedPotThrowMacro",
    "StrengthPotThrowMacro", "GoldenAppleEatMacro", "ChorusFruitEatMacro", "TotemPopCounterMacro",
    "DamageIndicatorMacro", "HitDelayOptimizerMacro", "ReachBoosterMacro", "VelocityCancelerMacro",
    "KeepSprintMacro", "SprintResetMacro", "FastLadderMacro", "SafeWalkMacro"
)

$script:flaggedContent = @(
    "AutoCrystal", "autocrystal", "auto crystal", "cw crystal", "JDWP.VirtualMachine.AllModules",
    "dontPlaceCrystal", "dontBreakCrystal", "dev.virel", "orchard",
    "AutoHitCrystal", "autohitcrystal", "canPlaceCrystalServer", "cantPlaceCrystalServer",
    "healPotSlot", "speedPotSlot", "strengthPotSlot", "totemHitSlot", "autoTotemSlot",
    "AutoAnchor", "autoanchor", "auto anchor", "DoubleAnchor", "Double Anchor",
    "HasAnchor", "anchortweaks", "anchor macro", "safe anchor", "safeanchor",
    "SafeAnchor", "AirAnchor", "anchorMacro", "AutoTotem", "autototem", "auto totem",
    "InventoryTotem", "inventorytotem", "HoverTotem", "hover totem", "legittotem", "LegitTotem",
    "AutoInventoryTotem", "Auto Totem Hit", "AutoTotemHit",
    "AutoPot", "autopot", "auto pot", "AutoPotRefill", "auto_pot_refill", "Auto Pot Refill",
    "AutoArmor", "autoarmor", "auto armor", "Auto Armor",
    "preventSwordBlockBreaking", "preventSwordBlockAttack",
    "ShieldDisabler", "ShieldBreaker", "Breaking shield with axe...",
    "AutoDoubleHand", "autodoublehand", "auto double hand",
    "AutoClicker", "Failed to switch to mace after axe!", "AutoMace", "MaceSwap", "SpearSwap",
    "StunSlam", "JumpReset", "axespam", "axe spam", "findKnockbackSword", "attackRegisteredThisClick",
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
    "AutoFirework", "ElytraSwap", "FastXP", "FastExp", "NoJumpDelay", "Donut",
    "PackSpoof", "Antiknockback", "catlean", "AuthBypass", "obfuscatedAuth", "LicenseCheckMixin",
    "BaseFinder", "invsee", "ItemExploit", "FreezePlayer", "KeyPearl", "LootYeeter",
    "FastPlace", "AutoBreach", "setBlockBreakingCooldown", "getBlockBreakingCooldown", "blockBreakingCooldown",
    "onBlockBreaking", "setItemUseCooldown", "invokeDoAttack", "invokeDoItemUse", "invokeOnMouseButton",
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
    "powershell -WindowStyle Hidden -Command Remove-Item -Path",
    "cmd.exe /c ping 127.0.0.1 -n 2 & del /f /q",
    "vssadmin delete shadows /all /quiet", "wevtutil cl Security", "wevtutil cl System",
    "Clear-EventLog -LogName Security", "fsutil usn deletejournal",
    "CurrentVersion\\Compatibility Assistant\\Store",
    "Activate Key", "Click Simulation", "On RMB", "arrayOfString",
    "Place Delay", "Break Delay", "Place Chance", "Break Chance", "Stop on Kill",
    "Anti Weakness", "Particle Chance", "Trigger Key", "Switch Delay", "Totem Slot",
    "Smooth Rotations", "Rotation Speed", "Use Easing", "Easing Strength", "While Use",
    "Glowstone Chance", "Explode Chance", "Explode Slot", "Only Charge",
    "Min Height", "Min Fall Speed", "Attack Delay", "Breach Delay", "Require Elytra",
    "Auto Switch Back", "Check Line of Sight", "Only When Falling", "LWFH Crystal",
    "Places Webs On Enemies", "Move freely through walls", "No Clip", "Place blocks faster",
    "Removes the crystal bounce animation", "Removes crystal bounce animation",
    "Automatically switches to sword when hitting with totem",
    "Automatically axe and mace shielded players",
    "PlayerMoveC2SPacket", "PlayerInteractBlockC2SPacket", "PlayerInteractEntityC2SPacket",
    "PlayerActionC2SPacket", "HandSwingC2SPacket", "UpdateSelectedSlotC2SPacket",
    "ClickSlotC2SPacket", "ClientCommandC2SPacket", "VehicleMoveC2SPacket", "TeleportConfirmC2SPacket",
    "ChannelDuplexHandler", "ChannelHandlerContext", "fireChannelRead", "writeVarInt",
    "PacketByteBuf", "ClientConnection", "ClientPlayerInteractionManager", "HandledScreen",
    "DamageTick", "AntiWeakness", "ParticleChance", "TriggerKey", "SwitchDelay", "TotemSlot",
    "SmoothRotations", "RotationSpeed", "UseEasing", "EasingStrength", "WhileUse", "StopOnKill",
    "GlowstoneDelay", "GlowstoneChance", "ExplodeDelay", "ExplodeChance", "ExplodeSlot",
    "OnlyCharge", "AnchorMacro", "ReachDistance", "MinHeight", "MinFallSpeed",
    "AttackDelay", "BreachDelay", "RequireElytra", "AutoSwitchBack", "CheckLineOfSight",
    "OnlyWhenFalling", "LWFHCrystal", "CWCrystal", "DoubleEscape", "DoubleRightClick",
    "PostCycleDelay", "PlaceObi", "WaitObi", "BreakCrystal", "RotatingDown", "RotatingBack",
    "Refilling", "Planting", "Bonemealing",
    "KuriumClient", "LithiumClient", "YukawaClient", "CryptClient", "DreamClient",
    "AnticClient", "SpookClient", "HarpoonClient", "BozeClient", "PhobosClient",
    "PyroClient", "AugustusClient", "RiseClient", "TenacityClient", "LiquidBounceNext",
    "NightXClient", "FDPClient", "SkidXClient", "AristoisClient", "BlackoutClient",
    "CoffeeClient", "RavenXDGhost", "JitterClicker", "LeftClickerRandomizer", "RightClickerRandomizer",
    "AimAssistAngle", "PitchInterpolator", "YawInterpolator", "RotationAngleSmooth",
    "SilentAimMatrix", "KeepSprintSync", "EagleBridgeHelper", "FastBridgeEdge",
    "ScaffoldTowerSpeed", "ScaffoldExpandReach", "BackTrackRingBuffer", "HitboxExpanderRay",
    "ReachPacketDelta", "CriticalsPacketJump", "WTapSyncDelay", "STapSyncDelay",
    "AutoTotemInventorySync", "AutoCrystalWallRaytrace", "AutoCrystalTargetQueue",
    "AutoAnchorGlowstoneCount", "BedBombDimensionBypass", "ElytraFlyPitchClamp",
    "BoatFlyPacketVelocity", "BlinkPacketQueue", "FakeLagPingDelta", "DisablerTransactionDrop",
    "InventoryMoveScreenOverride", "NoSlowItemSpeedClamp", "FastPlaceTickReset",
    "FastBreakDamageBoost", "NukerMultiBlockQueue", "ESPGlowShader", "TracersVectorRenderer",
    "XRayBlockListFilter", "ChamsDepthStencil", "FullbrightGammaOverride",
    "Skidfuscator", "Paramorphism", "Branchlock", "Caesium", "RadonObfuscator",
    "SuperblaubeereObfuscator", "SmokeObfuscator", "AndromedaObfuscator", "CyberObfuscator",
    "BytecodeFixer", "DexPatcher", "RetroguardObf", "JBcryptObf", "AllatoriObfuscator",
    "ZKMObfuscator", "StringerObfuscator", "JPhantomObfuscator", "DashOObfuscator",
    "SandMarkObfuscator", "ProGuardObfuscator",
    "GrimVelocityDisabler", "GrimFastBreakDisabler", "VulcanGlideDisabler", "PolarKeepSprintDisabler",
    "MatrixFastUseDisabler", "WatchdogMovementDisabler", "IntaveTimerDisabler", "SpartanCombatDisabler",
    "NegativityPacketDisabler", "NCPInventoryDisabler", "AACVelocityDisabler", "VerusCombatDisabler",
    "FlapDisabler", "SparkyDisabler", "NemesisDisabler", "MorganDisabler", "KarhuMovementDisabler",
    "k1llaura", "aut0crystal", "a1mass1st", "tr1gg3rb0t", "scaff0ld", "v3l0c1ty",
    "aut0t0t3m", "aut0anch0r", "d1sabl3r", "p1ngsp00f", "fak3lag",
    "aim_assist_fov", "aim_assist_speed", "aim_assist_pitch", "aim_assist_yaw",
    "reach_min", "reach_max", "autoclicker_cps_min", "autoclicker_cps_max", "autoclicker_jitter",
    "velocity_horizontal", "velocity_vertical", "velocity_chance", "wtap_delay", "stap_delay",
    "autototem_health", "autototem_slot", "autocrystal_break_delay", "autocrystal_place_delay",
    "autocrystal_range", "autoanchor_charge_delay", "autoanchor_explode_delay", "bedbomb_delay",
    "scaffold_expand", "scaffold_tower_speed", "speed_timer", "fly_motion", "nofall_mode",
    "bhop_speed", "packetfly_factor", "disabler_mode", "grim_disabler", "vulcan_disabler",
    "matrix_disabler", "polar_disabler", "karhu_disabler",
    "cmd.exe /c start /b cmd.exe /c ping 127.0.0.1 -n 1 > nul & del /f /q",
    "powershell.exe -ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -Command Remove-Item -Force -Path",
    "java.io.File.deleteOnExit()", "Runtime.getRuntime().addShutdownHook(new Thread())",
    'ProcessBuilder("cmd", "/c", "ping", "127.0.0.1", "-n", "2", "&&", "del")',
    'ProcessBuilder("powershell", "-c", "Remove-Item", "-Force")',
    'WScript.Shell.Run "cmd /c del /f /q"',
    'vssadmin.exe Delete Shadows /All /Quiet',
    'wevtutil.exe cl "Windows PowerShell"',
    'wevtutil.exe cl "Microsoft-Windows-PowerShell/Operational"',
    'reg.exe delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs" /f',
    'reg.exe delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" /f',
    "SkidfuscatorRuntime", "ParamorphismRuntime", "BranchlockRuntime", "CaesiumRuntime",
    "RadonRuntime", "SuperblaubeereRuntime", "SmokeRuntime", "AndromedaRuntime",
    "CyberObfuscatorRuntime", "BytecodeFixerRuntime", "DexPatcherRuntime", "RetroguardRuntime",
    "JBcryptRuntime", "AllatoriRuntime", "ZKMRuntime", "StringerRuntime", "JPhantomRuntime",
    "DashORuntime", "SandMarkRuntime", "ProGuardRuntime",
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
    "WindCharge", "MaceSwap", "BreezeRod", "CrafterSpam", "AutoCrafter",
    "MaceDamage", "SpearCharge", "AnchorPredict", "PopPredict",
    "Gothaj", "gothaj", "GothajClient", "Gothaj.rar"
)

$script:fwCheatPool = @(
    "ＡｕｔｏＣｒｙｓｔａｌ", "Ａｕｔｏ Ｃｒｙｓｔａｌ", "ＡｕｔｏＨｉｔＣｒｙｓｔａｌ",
    "ＡｕｔｏＡｎｃｈｏｒ", "Ａｕｔｏ Ａｎｃｈｏｒ", "ＤｏｕｂｌｅＡｎｃｈｏｒ", "Ｄｏｕｂｌｅ Ａｎｃｈｏｒ",
    "ＳａｆｅＡｎｃｈｏｒ", "Ｓａｆｅ Ａｎｃｈｏｒ", "Ａｎｃｈｏｒ Ｍａｃｒｏ", "ＡｕｔｏＴｏｔｅｍ", "Ａｕｔｏ Ｔｏｔｅｍ",
    "ＨｏｖｅｒＴｏｔｅｍ", "Ｈｏｖｅｒ Ｔｏｔｅｍ", "ＩｎｖｅｎｔｏｒｙＴｏｔｅｍ", "Ａｕｔｏ Ｉｎｖｅｎｔｏｒｙ Ｔｏｔｅｍ",
    "Ａｕｔｏ Ｔｏｔｅｍ Ｈｉｔ", "ＡｕｔｏＰｏｔ", "Ａｕｔｏ Ｐｏｔ", "Ａｕｔｏ Ｐｏｔ Ｒｅｆｉｌｌ",
    "ＡｕｔｏＡｒｍｏｒ", "Ａｕｔｏ Ａｒｍｏｒ", "ＳｈｉｅｌｄＤｉｓａｂｌｅｒ", "Ｓｈｉｅｌｄ Ｄｉｓａｂｌｅｒ",
    "ＡｕｔｏＤｏｕｂｌｅＨａｎｄ", "Ａｕｔｏ Ｄｏｕｂｌｅ Ｈａｎｄ", "ＡｕｔｏＣｌｉｃｋｅｒ", "ＡｕｔｏＭａｃｅ",
    "Ａｕｔｏ Ｍａｃｅ", "ＭａｃｅＳｗａｐ", "Ｍａｃｅ Ｓｗａｐ", "Ｓｐｅａｒ Ｓｗａｐ",
    "Ａｕｔｏｍａｔｉｃａｌｌｙ ａｘｅ ａｎｄ ｍａｃｅ ｓｈｉｅｌｄｅｄ ｐｌａｙｅｒｓ", "Ｓｔｕｎ Ｓｌａｍ",
    "ＡｉｍＡｓｓｉｓｔ", "Ａｉｍ Ａｓｓｉｓｔ", "ＴｒｉｇｇｅｒＢｏｔ", "Ｔｒｉｇｇｅｒ Ｂｏｔ",
    "Ｓｉｌｅｎｔ Ｒｏｔａｔｉｏｎｓ", "ＦａｋｅＬａｇ", "Ｆａｋｅ Ｌａｇ", "Ｆａｋｅ Ｐｕｎｃｈ",
    "Ａｎｔｉ Ｗｅｂ", "ＡｕｔｏＷｅｂ", "Ｐｌａｃｅｓ Ｗｅｂｓ Ｏｎ Ｅｎｅｍｉｅｓ", "Ｗａｌｋｓｙ Ｏｐｔｉｍｉｚｅｒ",
    "ＥｌｙｔｒａＳｗａｐ", "Ｅｌｙｔｒａ Ｓｗａｐ", "Ｆｒｅｅｃａｍ", "Ｍｏｖｅ ｆｒｅｅｌｙ ｔｈｒｏｕｇｈ ｗａｌｌｓ",
    "Ｎｏ Ｃｌｉｐ", "Ｆｒｅｅｚｅ Ｐｌａｙｅｒ", "ＬＷＦＨ Ｃｒｙｓｔａｌ", "ＫｅｙＰｅａｒｌ",
    "Ｋｅｙ Ｐｅａｒｌ", "Ｌｏｏｔ Ｙｅｅｔｅｒ", "Ｆａｓｔ Ｐｌａｃｅ", "Ｐｌａｃｅ ｂｌｏｃｋｓ ｆａｓｔｅｒ",
    "Ａｕｔｏ Ｂｒｅａｃｈ", "ＳｍａｒｔＣｒｉｔ", "ＡｕｔｏＢｌｏｃｋ", "ＣｏｍｂｏＭｏｄｅ",
    "ＫｉｌｌＡｕｒａ", "ＣｌｉｃｋＡｕｒａ", "ＭｕｌｔｉＡｕｒａ", "ＦｏｒｃｅＦｉｅｌｄ",
    "ＣｒｙｓｔａｌＡｕｒａ", "ＡｎｃｈｏｒＡｕｒａ", "ＢｅｄＡｕｒａ", "ＮｏＦａｌｌ",
    "ＳｐｅｅｄＨａｃｋ", "ＦｌｙＨａｃｋ", "ＮｏＳｌｏｗ", "ＥＳＰ", "Ｔｒａｃｅｒｓ",
    "Ｃｈａｍｓ", "ＸＲａｙ", "Ｆｕｌｌｂｒｉｇｈｔ", "Ｎｕｋｅｒ", "Ｓｃａｆｆｏｌｄ",
    "ＦａｓｔＢｒｅａｋ", "ＰａｃｋｅｔＦｌｙ", "Ｄｉｓａｂｌｅｒ", "ＶｅｌｏｃｉｔｙＳｐｏｏｆ",
    "ＡｕｔｏＰｅａｒｌ", "ＡｕｔｏＧａｐ", "ＡｕｔｏＳｗｏｒｄ", "Ｂｕｒｒｏｗ",
    "ＳｅｌｆＴｒａｐ", "ＨｏｌｅＦｉｌｌｅｒ", "ＷＴａｐ", "ＡｎｔｉＡＦＫ",
    "ＣｈｅｓｔＳｔｅａｌｅｒ", "Ｍｅｔｅｏｒ", "ＢｌｅａｃｈＨａｃｋ", "Ｌｉｑｕｉｄ Ｂｏｕｎｃｅ",
    "Ｗｕｒｓｔ", "Ａｒｉｓｔｏｉｓ", "Ｍａｔｈａｘ", "Ｉｍｐａｃｔ", "Ｎｏｖｏｌｉｎｅ",
    "Ｒｉｓｅ", "Ｔｅｎａｃｉｔｙ", "Ａｓｔｏｌｆｏ", "Ｆｕｔｕｒｅ", "Ｋｏｎａｓ",
    "Ｒｕｓｈｅｒ Ｈａｃｋ", "ＳｃａｆｆｏｌｄＷａｌｋ", "ＡｉｒＰｌａｃｅ", "ＰａｃｋｅｔＭｉｎｅ",
    "ＰａｃｋｅｔＣａｎｃｅｌ", "ＢａｃｋＴｒａｃｋ", "ＰｅａｒｌＣｌｉｐ", "ＦｒｅｅＣａｍ",
    "ＪｅｓｕｓＷａｌｋ", "ＴｏｗｅｒＳｃａｆｆｏｌｄ", "ＢｏａｔＦｌｙ", "ＢｏａｔＡｕｒａ",
    "ＦａｋｅＰｌａｙｅｒ", "ＥｎｔｉｔｙＣｏｎｔｒｏｌ", "ＡｎｔｉＣａｃｔｕｓ", "ＡｕｔｏＤｉｓｃｏｎｎｅｃｔ",
    "ＡｕｔｏＬｅａｖｅ", "Ａｃｔｉｖａｔｅ Ｋｅｙ", "Ｃｌｉｃｋ Ｓｉｍｕｌａｔｉｏｎ", "Ｏｎ ＲＭＢ",
    "Ｎｏ Ｃｏｕｎｔ Ｇｌｉｔｃｈ", "Ｎｏ Ｂｏｕｎｃｅ", "ＮｏＢｏｕｎｃｅ", "Ｐｌａｃｅ Ｄｅｌａｙ",
    "Ｂｒｅａｋ Ｄｅｌａｙ", "Ｆａｓｔ Ｍｏｄｅ", "Ｐｌａｃｅ Ｃｈａｎｃｅ", "Ｂｒｅａｋ Ｃｈａｎｃｅ",
    "Ｓｔｏｐ Ｏｎ Ｋｉｌｌ", "Ｄａｍａｇｅ Ｔｉｃｋ", "Ａｎｔｉ Ｗｅａｋｎｅｓｓ", "Ｐａｒｔｉｃｌｅ Ｃｈａｎｃｅ",
    "Ｔｒｉｇｇｅｒ Ｋｅｙ", "Ｓｗｉｔｃｈ Ｄｅｌａｙ", "Ｔｏｔｅｍ Ｓｌｏｔ", "Ｓｍｏｏｔｈ Ｒｏｔａｔｉｏｎｓ",
    "Ｒｏｔａｔｉｏｎ Ｓｐｅｅｄ", "Ｕｓｅ Ｅａｓｉｎｇ", "Ｅａｓｉｎｇ Ｓｔｒｅｎｇｔｈ", "Ｗｈｉｌｅ Ｕｓｅ",
    "Ｓｔｏｐ ｏｎ Ｋｉｌｌ", "Ｇｌｏｗｓｔｏｎｅ Ｄｅｌａｙ", "Ｇｌｏｗｓｔｏｎｅ Ｃｈａｎｃｅ", "Ｅｘｐｌｏｄｅ Ｄｅｌａｙ",
    "Ｅｘｐｌｏｄｅ Ｃｈａｎｃｅ", "Ｅｘｐｌｏｄｅ Ｓｌｏｔ", "Ｏｎｌｙ Ｃｈａｒｇｅ", "Ａｎｃｈｏｒ Ｍａｃｒｏ",
    "Ｒｅａｃｈ Ｄｉｓｔａｎｃｅ", "Ｍｉｎ Ｈｅｉｇｈｔ", "Ｍｉｎ Ｆａｌｌ Ｓｐｅｅｄ", "Ａｔｔａｃｋ Ｄｅｌａｙ",
    "Ｂｒｅａｃｈ Ｄｅｌａｙ", "Ｒｅｑｕｉｒｅ Ｅｌｙｔｒａ", "Ａｕｔｏ Ｓｗｉｔｃｈ Ｂａｃｋ", "Ｃｈｅｃｋ Ｌｉｎｅ ｏｆ Ｓｉｇｈｔ",
    "Ｏｎｌｙ Ｗｈｅｎ Ｆａｌｌｉｎｇ", "ＷｉｎｄＣｈａｒｇｅ", "ＭａｃｅＳｗａｐ", "ＢｒｅｅｚｅＲｏｄ",
    "ＣｒａｆｔｅｒＳｐａｍ", "ＡｕｔｏＣｒａｆｔｅｒ", "ＭａｃｅＤａｍａｇｅ", "ＳｐｅａｒＣｈａｒｇｅ",
    "ＡｎｃｈｏｒＰｒｅｄｉｃｔ", "ＰｏｐＰｒｅｄｉｃｔ", "Ｒｅｍｏｖｅｓ ｔｈｅ ｃｒｙｓｔａｌ ｂｏｕｎｃｅ ａｎｉｍａｔｉｏｎ"
)



[FastScanner]::InitAll(
    [string[]]$script:flaggedIdentifiers,
    [string[]]$script:macroIdentifiers,
    [string[]]$script:flaggedContent,
    [string[]]$script:reflectionIndicators
)

function Read-ArchiveData {
    param([string]$Target)
    $entries = [System.Collections.Generic.List[string]]::new()
    $nestedEntries = [System.Collections.Generic.List[string]]::new()
    $classBytes = [System.Collections.Generic.Dictionary[string, byte[]]]::new([StringComparer]::OrdinalIgnoreCase)
    $entryTimestamps = [System.Collections.Generic.Dictionary[string, datetime]]::new([StringComparer]::OrdinalIgnoreCase)

    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($Target)
        foreach ($entry in $zip.Entries) {
            [void]$entries.Add($entry.FullName)
            $entryTimestamps[$entry.FullName] = $entry.LastWriteTime.DateTime

            if ($entry.FullName.EndsWith(".class") -or $entry.FullName.EndsWith(".json") -or $entry.FullName.EndsWith(".java") -or $entry.FullName.EndsWith(".kt") -or ($entry.Length -lt 262144 -and ($entry.FullName.EndsWith(".png") -or $entry.FullName.EndsWith(".dat") -or $entry.FullName.EndsWith(".txt") -or $entry.FullName.EndsWith(".bin") -or $entry.FullName.EndsWith(".resource") -or $entry.FullName.EndsWith(".ogg")))) {
                if ($entry.Length -lt 2097152) {
                    try {
                        $s = $entry.Open()
                        $ms = [System.IO.MemoryStream]::new()
                        $s.CopyTo($ms)
                        $s.Close()
                        $classBytes[$entry.FullName] = $ms.ToArray()
                        $ms.Dispose()
                    } catch { }
                }
            }

            if ($entry.FullName.EndsWith(".jar") -and $entry.Length -lt 52428800) {
                try {
                    $nestedStream = $entry.Open()
                    $nestedMem = [System.IO.MemoryStream]::new()
                    $nestedStream.CopyTo($nestedMem)
                    $nestedStream.Close()
                    $nestedMem.Position = 0
                    $nestedZip = [System.IO.Compression.ZipArchive]::new($nestedMem, [System.IO.Compression.ZipArchiveMode]::Read)
                    foreach ($nEntry in $nestedZip.Entries) {
                        [void]$nestedEntries.Add($nEntry.FullName)
                        if ($nEntry.FullName.EndsWith(".class")) {
                            if ($nEntry.Length -lt 2097152) {
                                try {
                                    $ns = $nEntry.Open()
                                    $nms = [System.IO.MemoryStream]::new()
                                    $ns.CopyTo($nms)
                                    $ns.Close()
                                    $classBytes[$entry.FullName + "!" + $nEntry.FullName] = $nms.ToArray()
                                    $nms.Dispose()
                                } catch { }
                            }
                        }
                    }
                    $nestedZip.Dispose()
                    $nestedMem.Dispose()
                } catch { }
            }
        }
        $zip.Dispose()
    } catch { }

    return @{
        Entries          = $entries
        NestedEntries    = $nestedEntries
        ClassBytes       = $classBytes
        EntryTimestamps  = $entryTimestamps
    }
}

function Scan-TargetUsnJournal {
    param([string]$TargetDirectory)
    $findings = [System.Collections.Generic.List[object]]::new()
    if (-not $TargetDirectory -or -not (Test-Path $TargetDirectory)) { return $findings }

    $driveLetter = [System.IO.Path]::GetPathRoot($TargetDirectory).TrimEnd('\')
    if (-not $driveLetter -or $driveLetter.Length -lt 2) { return $findings }

    $folderName = (Get-Item $TargetDirectory).Name

    try {
        $usnJob = Start-Job -ScriptBlock { param($dl) & fsutil usn readjournal $dl csv 2>$null } -ArgumentList $driveLetter
        $usnDone = Wait-Job $usnJob -Timeout 10
        if (-not $usnDone) { Stop-Job $usnJob; Remove-Job $usnJob -Force; return $findings }
        $usnOutput = Receive-Job $usnJob
        Remove-Job $usnJob -Force
        if ($usnOutput) {
            foreach ($line in $usnOutput) {
                if ($line -match '\.jar"' -or $line -match '\.jar,') {
                    $parts = $line -split ','
                    if ($parts.Count -ge 5) {
                        $rawName = $parts[0].Trim('"')
                        $reason = $parts[3].Trim('"')
                        $timeStr = $parts[2].Trim('"')
                        if ($rawName.EndsWith(".jar")) {
                            if ($reason -match '0x80000000|0x00002000|0x00004000|0x00000002|DELETE|RENAME') {
                                [void]$findings.Add([PSCustomObject]@{
                                    FileName = $rawName
                                    Timestamp = $timeStr
                                    Reason = $reason
                                    Location = $TargetDirectory
                                })
                            }
                        }
                    }
                }
            }
        }
    } catch { }

    return $findings
}

function Resolve-ModrinthBatch {
    param([System.Collections.Generic.List[object]]$JarList)
    $resolvedMap = @{}
    $headers = @{ "User-Agent" = "APPT-ModAnalyzer/3.0" }

    $pending = [System.Collections.Generic.List[string]]::new()
    foreach ($j in $JarList) {
        if ($j.SHA1) { [void]$pending.Add($j.SHA1.ToLower()) }
    }

    $chunkSize = 100
    for ($i = 0; $i -lt $pending.Count; $i += $chunkSize) {
        $take = [Math]::Min($chunkSize, $pending.Count - $i)
        $chunk = $pending.GetRange($i, $take)
        $body = @{ hashes = @($chunk); algorithm = "sha1" } | ConvertTo-Json

        try {
            $resp = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version_files" -Method Post -Body $body -ContentType "application/json" -Headers $headers -TimeoutSec 5 -ErrorAction Stop
            if ($resp) {
                $projIds = [System.Collections.Generic.HashSet[string]]::new()
                foreach ($prop in $resp.PSObject.Properties) {
                    $v = $prop.Value
                    if ($v -and $v.project_id) { [void]$projIds.Add([string]$v.project_id) }
                }

                $projectTitles = @{}
                if ($projIds.Count -gt 0) {
                    try {
                        $pJson = [string]::Format('["{0}"]', ($projIds -join '","'))
                        $pResp = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/projects?ids=$pJson" -Headers $headers -TimeoutSec 5 -ErrorAction Stop
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
                        $resolvedMap[$h] = $data
                    }
                }
            }
        } catch { }
    }
    return $resolvedMap
}

function Resolve-MavenHash {
    param([string]$FileName, [string]$Sha1)
    if ($FileName -match '^(fabric-api|fabric-language-kotlin|fabric-language-scala)-([0-9\.\+\-a-zA-Z]+)\.jar$') {
        $art = $matches[1]
        $ver = $matches[2]
        try {
            $mavenUrl = "https://maven.fabricmc.net/net/fabricmc/fabric-api/$art/$ver/$art-$ver.jar.sha1"
            $remoteSha1 = (Invoke-RestMethod -Uri $mavenUrl -TimeoutSec 2 -ErrorAction Stop).Trim()
            if ($remoteSha1 -eq $Sha1) {
                return @{ Name = "$art $ver"; Verified = $true; Source = "Maven" }
            }
        } catch { }
    }
    return @{ Name = $null; Verified = $false; Source = $null }
}

function Resolve-ModrinthProject {
    param([string]$Slug)
    if (-not $Slug -or $Slug.Trim() -eq "") { return $null }
    $clean = $Slug.Trim().ToLower()
    try {
        $headers = @{ "User-Agent" = "APPT-ModAnalyzer/3.0" }
        $resp = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/project/$clean" -Headers $headers -TimeoutSec 3 -ErrorAction Stop
        if ($resp -and $resp.title) {
            return @{ Name = [string]$resp.title; Slug = $clean; Verified = $true; Source = "Modrinth" }
        }
    } catch { }
    return $null
}

$script:knownModCatalog = @{
    "boatiview" = @{ Name = "Boat Item View"; Source = "Modrinth" }
    "connectivity" = @{ Name = "Connectivity"; Source = "Modrinth / Verified" }
    "cupboard" = @{ Name = "Cupboard"; Source = "Modrinth / Verified" }
    "gpumemleakfix" = @{ Name = "fix GPU memory leak"; Source = "Modrinth / Verified" }
    "travelerstitles" = @{ Name = "Traveler's Titles"; Source = "Modrinth" }
    "sodium" = @{ Name = "Sodium"; Source = "Modrinth" }
    "lithium" = @{ Name = "Lithium"; Source = "Modrinth" }
    "ferritecore" = @{ Name = "FerriteCore"; Source = "Modrinth" }
    "iris" = @{ Name = "Iris Shaders"; Source = "Modrinth" }
    "indium" = @{ Name = "Indium"; Source = "Modrinth" }
    "modmenu" = @{ Name = "Mod Menu"; Source = "Modrinth" }
    "fabric-api" = @{ Name = "Fabric API"; Source = "Maven / Modrinth" }
    "cloth-config" = @{ Name = "Cloth Config"; Source = "Modrinth" }
    "cloth-config2" = @{ Name = "Cloth Config v2"; Source = "Modrinth" }
    "betterf3" = @{ Name = "BetterF3"; Source = "Modrinth" }
    "immediatelyfast" = @{ Name = "ImmediatelyFast"; Source = "Modrinth" }
    "entityculling" = @{ Name = "Entity Culling"; Source = "Modrinth" }
    "dynamic-fps" = @{ Name = "Dynamic FPS"; Source = "Modrinth" }
    "continuity" = @{ Name = "Continuity"; Source = "Modrinth" }
    "resourcify" = @{ Name = "Resourcify"; Source = "Modrinth" }
    "chunky" = @{ Name = "Chunky"; Source = "Modrinth" }
    "lambdynamiclights" = @{ Name = "LambDynamicLights"; Source = "Modrinth" }
    "krypton" = @{ Name = "Krypton"; Source = "Modrinth" }
    "c2me" = @{ Name = "C2ME"; Source = "Modrinth" }
    "starlight" = @{ Name = "Starlight"; Source = "Modrinth" }
    "appleskin" = @{ Name = "AppleSkin"; Source = "Modrinth" }
    "rei" = @{ Name = "Roughly Enough Items"; Source = "Modrinth" }
    "jei" = @{ Name = "Just Enough Items"; Source = "Modrinth" }
    "emi" = @{ Name = "EMI"; Source = "Modrinth" }
    "xaerominimap" = @{ Name = "Xaero's Minimap"; Source = "Modrinth" }
    "xaeroworldmap" = @{ Name = "Xaero's World Map"; Source = "Modrinth" }
    "journeymap" = @{ Name = "JourneyMap"; Source = "Modrinth" }
    "voxelmap" = @{ Name = "VoxelMap"; Source = "Modrinth / Verified" }
    "architectury" = @{ Name = "Architectury API"; Source = "Modrinth" }
    "sodium-extra" = @{ Name = "Sodium Extra"; Source = "Modrinth" }
    "reeses-sodium-options" = @{ Name = "Reese's Sodium Options"; Source = "Modrinth" }
    "bobby" = @{ Name = "Bobby"; Source = "Modrinth" }
    "distanthorizons" = @{ Name = "Distant Horizons"; Source = "Modrinth" }
    "notenoughcrashes" = @{ Name = "Not Enough Crashes"; Source = "Modrinth" }
    "soundphysics" = @{ Name = "Sound Physics Remastered"; Source = "Modrinth" }
    "presencefootsteps" = @{ Name = "Presence Footsteps"; Source = "Modrinth" }
    "chat_heads" = @{ Name = "Chat Heads"; Source = "Modrinth" }
    "status-effect-bars" = @{ Name = "Status Effect Bars"; Source = "Modrinth" }
    "controlling" = @{ Name = "Controlling"; Source = "Modrinth" }
    "searchables" = @{ Name = "Searchables"; Source = "Modrinth" }
    "visuality" = @{ Name = "Visuality"; Source = "Modrinth" }
    "waveycapes" = @{ Name = "Wavey Capes"; Source = "Modrinth" }
    "eating-animation" = @{ Name = "Eating Animation"; Source = "Modrinth" }
    "citresewn" = @{ Name = "CIT Resewn"; Source = "Modrinth" }
    "custom-entity-models" = @{ Name = "Custom Entity Models (CEM)"; Source = "Modrinth" }
    "animatica" = @{ Name = "Animatica"; Source = "Modrinth" }
    "colormatic" = @{ Name = "Colormatic"; Source = "Modrinth" }
    "itemphysic" = @{ Name = "ItemPhysic"; Source = "Modrinth" }
    "wthit" = @{ Name = "WTHIT"; Source = "Modrinth" }
    "jade" = @{ Name = "Jade"; Source = "Modrinth" }
    "invmove" = @{ Name = "Inventory Move"; Source = "Modrinth" }
    "shulkerboxtooltip" = @{ Name = "Shulker Box Tooltip"; Source = "Modrinth" }
    "authme" = @{ Name = "Auth Me"; Source = "Modrinth" }
    "simple-voice-chat" = @{ Name = "Simple Voice Chat"; Source = "Modrinth" }
    "voicechat" = @{ Name = "Simple Voice Chat"; Source = "Modrinth" }
    "plasmovoice" = @{ Name = "Plasmo Voice"; Source = "Modrinth" }
    "spark" = @{ Name = "spark"; Source = "Modrinth" }
    "memoryleakfix" = @{ Name = "Memory Leak Fix"; Source = "Modrinth" }
    "modernfix" = @{ Name = "ModernFix"; Source = "Modrinth" }
    "nvidium" = @{ Name = "Nvidium"; Source = "Modrinth" }
    "vulkanmod" = @{ Name = "VulkanMod"; Source = "Modrinth" }
    "badpackets" = @{ Name = "Bad Packets"; Source = "Modrinth" }
    "fabric-language-kotlin" = @{ Name = "Fabric Language Kotlin"; Source = "Maven / Modrinth" }
    "fabric-language-scala" = @{ Name = "Fabric Language Scala"; Source = "Maven / Modrinth" }
    "yungsapi" = @{ Name = "YUNG's API"; Source = "Modrinth" }
    "yungsextras" = @{ Name = "YUNG's Extras"; Source = "Modrinth" }
    "yet-another-config-lib" = @{ Name = "YetAnotherConfigLib (YACL)"; Source = "Modrinth" }
    "yacl" = @{ Name = "YetAnotherConfigLib"; Source = "Modrinth" }
    "borderless-mining" = @{ Name = "Borderless Mining"; Source = "Modrinth" }
    "entity_model_features" = @{ Name = "Entity Model Features (EMF)"; Source = "Modrinth" }
    "entity_texture_features" = @{ Name = "Entity Texture Features (ETF)"; Source = "Modrinth" }
    "flashback" = @{ Name = "Flashback"; Source = "Modrinth" }
    "replaymod" = @{ Name = "Replay Mod"; Source = "Modrinth" }
    "carpet" = @{ Name = "Carpet Mod"; Source = "Modrinth" }
    "malilib" = @{ Name = "MaLiLib"; Source = "Modrinth" }
    "litematica" = @{ Name = "Litematica"; Source = "Modrinth" }
    "minihud" = @{ Name = "MiniHUD"; Source = "Modrinth" }
    "tweakeroo" = @{ Name = "Tweakeroo"; Source = "Modrinth" }
    "itemscroller" = @{ Name = "Item Scroller"; Source = "Modrinth" }
    "embeddium" = @{ Name = "Embeddium"; Source = "Modrinth / Verified" }
    "oculus" = @{ Name = "Oculus"; Source = "Modrinth / Verified" }
    "rubidium" = @{ Name = "Rubidium"; Source = "Modrinth / Verified" }
    "create" = @{ Name = "Create"; Source = "Modrinth / Verified" }
    "farmersdelight" = @{ Name = "Farmer's Delight"; Source = "Modrinth / Verified" }
    "no-chat-reports" = @{ Name = "No Chat Reports"; Source = "Modrinth / Verified" }
    "nochatreports" = @{ Name = "No Chat Reports"; Source = "Modrinth / Verified" }
    "raised" = @{ Name = "Raised"; Source = "Modrinth / Verified" }
    "skinlayers3d" = @{ Name = "3D Skin Layers"; Source = "Modrinth / Verified" }
    "physicsmod" = @{ Name = "Physics Mod"; Source = "Modrinth / Verified" }
    "ambientsounds" = @{ Name = "AmbientSounds"; Source = "Modrinth / Verified" }
    "dynamiccrosshair" = @{ Name = "Dynamic Crosshair"; Source = "Modrinth / Verified" }
    "cameraoverhaul" = @{ Name = "Camera Overhaul"; Source = "Modrinth / Verified" }
    "capes" = @{ Name = "Capes"; Source = "Modrinth / Verified" }
    "essential" = @{ Name = "Essential Mod"; Source = "Modrinth / Verified" }
    "kuma-api" = @{ Name = "KumaAPI"; Source = "Modrinth / Verified" }
    "konkrete" = @{ Name = "Konkrete"; Source = "Modrinth / Verified" }
    "puzzleslib" = @{ Name = "Puzzles Lib"; Source = "Modrinth / Verified" }
    "forgeconfigapiport" = @{ Name = "Forge Config API Port"; Source = "Modrinth / Verified" }
    "architectury-fabric" = @{ Name = "Architectury (Fabric)"; Source = "Modrinth / Verified" }
    "balm-fabric" = @{ Name = "Balm (Fabric)"; Source = "Modrinth / Verified" }
    "fzzy_config" = @{ Name = "Fzzy Config"; Source = "Modrinth / Verified" }
    "completeconfig" = @{ Name = "CompleteConfig"; Source = "Modrinth / Verified" }
    "midnightlib" = @{ Name = "MidnightLib"; Source = "Modrinth / Verified" }
    "spruceui" = @{ Name = "SpruceUI"; Source = "Modrinth / Verified" }
    "owo-lib" = @{ Name = "oωo (owo-lib)"; Source = "Modrinth / Verified" }
    "cardinal-components-base" = @{ Name = "Cardinal Components"; Source = "Modrinth / Verified" }
    "fabric-permissions-api-v0" = @{ Name = "Fabric Permissions API"; Source = "Modrinth / Verified" }
    "player-animation-lib" = @{ Name = "Player Animator"; Source = "Modrinth / Verified" }
    "cloth-basic-math" = @{ Name = "Cloth Basic Math"; Source = "Modrinth / Verified" }
    "mixinextras" = @{ Name = "MixinExtras"; Source = "Maven / Modrinth" }
    "mixinsquared" = @{ Name = "MixinSquared"; Source = "Maven / Modrinth" }
    "cinderscapes" = @{ Name = "Cinderscapes"; Source = "Modrinth / Verified" }
    "terrestria" = @{ Name = "Terrestria"; Source = "Modrinth / Verified" }
    "traverse" = @{ Name = "Traverse"; Source = "Modrinth / Verified" }
    "biomesoplenty" = @{ Name = "Biomes O' Plenty"; Source = "Modrinth / Verified" }
    "geckolib" = @{ Name = "GeckoLib"; Source = "Modrinth / Verified" }
    "curios" = @{ Name = "Curios API"; Source = "Modrinth / Verified" }
    "trinkets" = @{ Name = "Trinkets"; Source = "Modrinth / Verified" }
    "accessories" = @{ Name = "Accessories"; Source = "Modrinth / Verified" }
    "appleskin-fabric" = @{ Name = "AppleSkin (Fabric)"; Source = "Modrinth / Verified" }
    "bclib" = @{ Name = "BCLib"; Source = "Modrinth / Verified" }
    "betterend" = @{ Name = "Better End"; Source = "Modrinth / Verified" }
    "betternether" = @{ Name = "Better Nether"; Source = "Modrinth / Verified" }
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

    foreach ($key in $ArchiveData.ClassBytes.Keys) {
        $bytes = $ArchiveData.ClassBytes[$key]
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

    $sdSignatures = @(
        "cmd.exe /c timeout & del", "cmd /c del", "powershell -command remove-item",
        "cmd.exe /c ping 127.0.0.1 & del", "taskkill /f /im javaw.exe & del",
        "powershell -c remove-item", "start /b cmd /c del", "deleteOnExit",
        "addShutdownHook", "cipher /w", "sdelete"
    )
    foreach ($fs in $foundStrings) {
        foreach ($sd in $sdSignatures) {
            if ($fs -match [regex]::Escape($sd)) {
                [void]$selfDestructFlags.Add($sd)
            }
        }
    }

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

    return @{
        Patterns          = [System.Collections.Generic.List[string]]::new([string[]]$foundPatterns)
        Macros            = [System.Collections.Generic.List[string]]::new([string[]]$foundMacros)
        FlaggedStrings    = [System.Collections.Generic.List[string]]::new([string[]]$foundStrings)
        FullwidthStrings  = [System.Collections.Generic.List[string]]::new([string[]]$finalFullwidth)
        EncodedHits       = [System.Collections.Generic.List[string]]::new([string[]]$encodedHits)
        HighEntropyCount  = $highEntropyCount
        ReflectionScore   = $reflectionScore
        ConfidenceScore   = ($foundPatterns.Count * 10 + $foundStrings.Count * 10)
        SelfDestructFlags = [System.Collections.Generic.List[string]]::new([string[]]$selfDestructFlags)
    }
}

function Start-StructureAnalysis {
    param($ArchiveData, [string]$FilePath)
    $flags = [System.Collections.Generic.List[string]]::new()

    $singleCharClasses = 0
    $nonAsciiClasses = 0
    $totalClasses = 0
    $hiraganaCount = 0
    $katakanaCount = 0
    $hangulCount = 0
    $cjkCount = 0
    $cyrillicCount = 0
    $greekCount = 0
    $zeroWidthCount = 0
    $caseCollisionCount = 0
    $reservedDeviceNames = 0
    $disguisedPayloadCount = 0
    $seenLower = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $seenExact = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)

    foreach ($e in $ArchiveData.Entries) {
        $norm = $e.Replace('\', '/')
        if ($norm -match '\.(exe|dll|bat|cmd|ps1|vbs|sh|scr|pif|so|dylib)$') {
            [void]$flags.Add("Embedded non-Java native executable payload found: $e")
        }
        if ($norm -match '(^|/)(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\.|$)' -or $norm.Contains("..")) {
            $reservedDeviceNames++
        }

        if ($e.EndsWith(".class")) {
            $totalClasses++
            $fn = $e
            $lastSlash = $fn.LastIndexOf('/')
            if ($lastSlash -ge 0) { $fn = $fn.Substring($lastSlash + 1) }
            $baseName = $fn.Substring(0, $fn.Length - 6)

            if ($seenLower.Contains($norm.ToLower()) -and -not $seenExact.Contains($norm)) {
                $caseCollisionCount++
            }
            [void]$seenExact.Add($norm)
            [void]$seenLower.Add($norm.ToLower())

            if ($baseName.Length -eq 1 -and -not $e.Contains("/")) { $singleCharClasses++ }
            if ($baseName -match '[\u3040-\u309F]') { $hiraganaCount++ }
            if ($baseName -match '[\u30A0-\u30FF\u31F0-\u31FF]') { $katakanaCount++ }
            if ($baseName -match '[\uAC00-\uD7AF\u1100-\u11FF\u3130-\u318F]') { $hangulCount++ }
            if ($baseName -match '[\u4E00-\u9FFF\u3400-\u4DBF]') { $cjkCount++ }
            if ($baseName -match '[\u0400-\u04FF\u0500-\u052F]') { $cyrillicCount++ }
            if ($baseName -match '[\u0370-\u03FF]') { $greekCount++ }
            if ($baseName -match '[\u200B-\u200F\uFEFF\u2060\u180E\u00A0\u202A-\u202E]') { $zeroWidthCount++ }
            if ($baseName -match '[^\x00-\x7F]') { $nonAsciiClasses++ }
        }
    }

    foreach ($key in $ArchiveData.ClassBytes.Keys) {
        $bytes = $ArchiveData.ClassBytes[$key]
        if (-not $key.EndsWith(".class") -and -not $key.EndsWith(".jar") -and $bytes.Length -ge 4) {
            if ($bytes[0] -eq 0xCA -and $bytes[1] -eq 0xFE -and $bytes[2] -eq 0xBA -and $bytes[3] -eq 0xBE) {
                $disguisedPayloadCount++
                [void]$flags.Add("Disguised Java class disguised with non-class extension: $key")
            }
            if ($bytes[0] -eq 0x50 -and $bytes[1] -eq 0x4B -and $bytes[2] -eq 0x03 -and $bytes[3] -eq 0x04 -and -not $key.EndsWith(".zip")) {
                [void]$flags.Add("Embedded nested ZIP archive disguised as resource: $key")
            }
        }
    }

    foreach ($entry in $ArchiveData.Entries) {
        $entryLow = $entry.ToLower()
        if ($entryLow.EndsWith(".rar") -or $entryLow.EndsWith(".7z") -or $entryLow.EndsWith(".tar.gz") -or $entryLow.EndsWith(".bz2")) {
            [void]$flags.Add("Embedded external compressed archive container: $entry")
        }
        if ($entryLow.EndsWith(".exe") -or $entryLow.EndsWith(".dll") -or $entryLow.EndsWith(".vbs") -or $entryLow.EndsWith(".bat") -or $entryLow.EndsWith(".cmd") -or $entryLow.EndsWith(".ps1")) {
            [void]$flags.Add("Embedded executable or script artifact: $entry")
        }
    }

    if ($hiraganaCount -ge 1) {
        [void]$flags.Add("Japanese Hiragana bytecode obfuscator detected ($hiraganaCount classes)")
    }
    if ($katakanaCount -ge 1) {
        [void]$flags.Add("Japanese Katakana bytecode obfuscator detected ($katakanaCount classes)")
    }
    if ($hangulCount -ge 1) {
        [void]$flags.Add("Korean Hangul bytecode obfuscator detected ($hangulCount classes)")
    }
    if ($cjkCount -ge 1) {
        [void]$flags.Add("CJK Ideograph bytecode obfuscator detected ($cjkCount classes)")
    }
    if ($cyrillicCount -ge 1) {
        [void]$flags.Add("Cyrillic script homoglyph obfuscator detected ($cyrillicCount classes)")
    }
    if ($greekCount -ge 1) {
        [void]$flags.Add("Greek script homoglyph obfuscator detected ($greekCount classes)")
    }
    if ($zeroWidthCount -ge 1) {
        [void]$flags.Add("Zero-width / invisible Unicode character obfuscation detected ($zeroWidthCount classes)")
    }
    if ($singleCharClasses -ge 5) {
        [void]$flags.Add("Heavy ProGuard / Allatori single-char root class obfuscation ($singleCharClasses root classes)")
    }
    if ($nonAsciiClasses -ge 3 -and $hiraganaCount -lt 1 -and $katakanaCount -lt 1 -and $hangulCount -lt 1 -and $cyrillicCount -lt 1 -and $greekCount -lt 1) {
        [void]$flags.Add("Non-ASCII class identifier scrambling ($nonAsciiClasses classes)")
    }
    if ($caseCollisionCount -ge 1) {
        [void]$flags.Add("Anti-decompilation case collision detected ($caseCollisionCount conflicting class names)")
    }
    if ($reservedDeviceNames -ge 1) {
        [void]$flags.Add("Anti-decompilation reserved Windows device name anomaly in ZIP ($reservedDeviceNames entries)")
    }

    $zipAnomalies = [FastScanner]::CheckZipIntegrity($FilePath)
    foreach ($za in $zipAnomalies) { [void]$flags.Add($za) }

    return $flags
}

function Test-Timestomping {
    param([string]$FilePath, $ArchiveData)
    $flags = [System.Collections.Generic.List[string]]::new()

    $fi = Get-Item $FilePath -ErrorAction SilentlyContinue
    if (-not $fi) { return $flags }

    $fileCreate = $fi.CreationTime
    $fileWrite = $fi.LastWriteTime

    $times = @($ArchiveData.EntryTimestamps.Values)
    if ($times.Count -gt 0) {
        $minTime = ($times | Measure-Object -Minimum).Minimum
        $maxTime = ($times | Measure-Object -Maximum).Maximum

        if ($minTime.Year -lt 2000 -or $minTime.Year -gt 2035) {
            [void]$flags.Add("Anomalous internal entry timestamp: $($minTime.ToString('yyyy-MM-dd HH:mm:ss'))")
        }

        if ($maxTime -gt [DateTime]::UtcNow.AddDays(2)) {
            [void]$flags.Add("Future-dated ZIP entry timestamp: $($maxTime.ToString('yyyy-MM-dd HH:mm:ss'))")
        }

        $allSame = $true
        $firstTime = $times[0]
        foreach ($t in $times) {
            if ([Math]::Abs(($t - $firstTime).TotalSeconds) -gt 2) { $allSame = $false; break }
        }
        if ($allSame -and $times.Count -ge 15) {
            [void]$flags.Add("Synthetic constant timestamp flattening ($($firstTime.ToString('yyyy-MM-dd HH:mm:ss')))")
        }
    }
    return $flags
}

function Resolve-OriginMetadata {
    param([string]$FilePath, $ArchiveData)
    $result = @{
        SourceHost = $null
        ExactUrl = $null
        IsDiscordOrigin = $false
        IsCheatOrigin = $false
    }

    try {
        $content = Get-Content -Path $FilePath -Stream "Zone.Identifier" -Raw -ErrorAction SilentlyContinue
        if ($content) {
            if ($content -match 'HostUrl=([^\r\n]+)') {
                $result.ExactUrl = $matches[1]
                try {
                    $uri = [System.Uri]::new($matches[1])
                    $result.SourceHost = $uri.Host
                } catch { $result.SourceHost = $matches[1] }
            } elseif ($content -match 'ReferrerUrl=([^\r\n]+)') {
                $result.ExactUrl = $matches[1]
                try {
                    $uri = [System.Uri]::new($matches[1])
                    $result.SourceHost = $uri.Host
                } catch { $result.SourceHost = $matches[1] }
            }
        }
    } catch { }

    if ($result.SourceHost) {
        $hostLow = $result.SourceHost.ToLower()
        if ($hostLow.Contains("discordapp.com") -or $hostLow.Contains("discord.com") -or $hostLow.Contains("cdn.discordapp.com") -or $hostLow.Contains("media.discordapp.net")) {
            $result.IsDiscordOrigin = $true
        }
        foreach ($cd in $script:cheatDomains) {
            if ($hostLow.Contains($cd)) { $result.IsCheatOrigin = $true; break }
        }
    }

    if ($result.ExactUrl -and -not $result.IsCheatOrigin) {
        $urlLow = $result.ExactUrl.ToLower()
        foreach ($cd in $script:cheatDomains) {
            if ($urlLow.Contains($cd)) { $result.IsCheatOrigin = $true; break }
        }
    }

    return $result
}

function Get-ModIdentity {
    param($ArchiveData)
    $identity = @{ Loader = "Unknown"; Name = $null; ModId = $null; Version = $null }

    foreach ($key in $ArchiveData.ClassBytes.Keys) {
        if ($key -eq "fabric.mod.json") {
            try {
                $json = [System.Text.Encoding]::UTF8.GetString($ArchiveData.ClassBytes[$key]) | ConvertFrom-Json
                $identity.Loader = "Fabric"
                $identity.ModId = $json.id
                $identity.Name = $json.name
                $identity.Version = $json.version
                return $identity
            } catch { }
        }
        if ($key -eq "quilt.mod.json") {
            try {
                $json = [System.Text.Encoding]::UTF8.GetString($ArchiveData.ClassBytes[$key]) | ConvertFrom-Json
                $identity.Loader = "Quilt"
                $identity.ModId = $json.quilt_loader.id
                $identity.Name = $json.quilt_loader.metadata.name
                $identity.Version = $json.quilt_loader.version
                return $identity
            } catch { }
        }
        if ($key -eq "META-INF/mods.toml") {
            try {
                $text = [System.Text.Encoding]::UTF8.GetString($ArchiveData.ClassBytes[$key])
                $identity.Loader = "Forge/NeoForge"
                if ($text -match 'modId\s*=\s*"([^"]+)"') { $identity.ModId = $matches[1] }
                if ($text -match 'displayName\s*=\s*"([^"]+)"') { $identity.Name = $matches[1] }
                if ($text -match 'version\s*=\s*"([^"]+)"') { $identity.Version = $matches[1] }
                return $identity
            } catch { }
        }
        if ($key -eq "mcmod.info") {
            try {
                $json = [System.Text.Encoding]::UTF8.GetString($ArchiveData.ClassBytes[$key]) | ConvertFrom-Json
                if ($json -is [array] -and $json.Count -gt 0) {
                    $identity.Loader = "Forge (Legacy)"
                    $identity.ModId = $json[0].modid
                    $identity.Name = $json[0].name
                    $identity.Version = $json[0].version
                    return $identity
                }
            } catch { }
        }
    }
    return $identity
}

function Show-ProgressLine {
    param([int]$Current, [int]$Total, [string]$FileName, [System.Diagnostics.Stopwatch]$Timer)
    $pct = if ($Total -gt 0) { [math]::Round(($Current / $Total) * 100) } else { 0 }
    $elapsed = $Timer.Elapsed.TotalSeconds
    $remaining = if ($Current -gt 0 -and $Current -lt $Total) { [math]::Round((($elapsed / $Current) * ($Total - $Current))) } else { 0 }
    $barLen = 25
    $filled = [math]::Floor($barLen * ($pct / 100))
    $bar = ("=" * $filled) + ("-" * ($barLen - $filled))
    $fnDisp = if ($FileName.Length -gt 24) { $FileName.Substring(0,21) + "..." } else { $FileName }
    Write-Host "`r  [$bar] $pct% | $Current/$Total | ETA: ${remaining}s | $fnDisp               " -ForegroundColor Cyan -NoNewline
}

function Show-FlaggedResult {
    param($Mod)

    $clientNames = @{
        "meteordevelopment" = "Meteor Client"; "meteor-client" = "Meteor Client"
        "liquidbounce" = "LiquidBounce"; "fdp-client" = "FDP Client"; "aristois" = "Aristois"
        "impactclient" = "Impact Client"; "rusherhack" = "RusherHack"; "futureClient" = "Future Client"
        "konas" = "Konas Client"; "astolfo" = "Astolfo"; "pandaware" = "Pandaware"
        "moonClient" = "Moon Client"; "vape.gg" = "Vape Client"; "vapeclient" = "Vape Client"
        "VapeLite" = "Vape Lite"; "VapeV4" = "Vape V4"; "VapeV3" = "Vape V3"
        "NovowareClient" = "Novoware"; "novoware.eu" = "Novoware"
        "HellClient" = "Hell Client"
        "OpaiClient" = "Opai Client"; "22qqClient" = "22QQ Client"
        "CWClient" = "CrystalWare"; "Crystalware" = "CrystalWare"; "CrystalwareClient" = "CrystalWare"
        "wurstclient" = "Wurst Client"; "Ｗｕｒｓｔ" = "Wurst Client"
        "ＢｌｅａｃｈＨａｃｋ" = "BleachHack"; "Ｍｅｔｅｏｒ" = "Meteor Client"
        "Ｌｉｑｕｉｄ Ｂｏｕｎｃｅ" = "LiquidBounce"; "Ａｒｉｓｔｏｉｓ" = "Aristois"
        "Ｉｍｐａｃｔ" = "Impact Client"; "Ｎｏｖｏｌｉｎｅ" = "Novoline"
        "Ｒｉｓｅ" = "Rise Client"; "Ｔｅｎａｃｉｔｙ" = "Tenacity"
        "Ａｓｔｏｌｆｏ" = "Astolfo"; "Ｆｕｔｕｒｅ" = "Future Client"
        "Ｋｏｎａｓ" = "Konas Client"; "Ｒｕｓｈｅｒ Ｈａｃｋ" = "RusherHack"
        "Ｍａｔｈａｘ" = "Mathax Client"; "cc/novoline" = "Novoline"
        "com/alan/clients" = "Alan Client"; "wtf/moonlight" = "Moonlight"
        "me/zeroeightsix/kami" = "KAMI Blue"; "net/ccbluex" = "LiquidBounce"
        "today/opai" = "Opai"; "org/chainlibs" = "Chainlibs Ghost"
        "dev.krypton" = "Krypton Client"; "dev/krypton" = "Krypton Client"
        "skid.krypton" = "Krypton Client"; "dev.virel" = "Virel Client"
        "xyz.greaj" = "Greaj Client"; "pw/cinque" = "Cinque Client"
        "dev.gambleclient" = "Gamble Client"; "dqrkis" = "Dqrkis Client"
        "PlatiniumClient" = "Platinium Client"; "OnyxClient" = "Onyx Client"
        "PuggerClient" = "Pugger Client"; "FranciumClient" = "Francium Client"
        "PugwareClient" = "Pugware Client"; "VirginsPremium" = "Virgins Premium"
        "ScrimsClient" = "Scrims Client"; "ZorimClient" = "Zorim Client"
        "VoltClient" = "Volt Client"; "VrilClient" = "Vril Client"
        "OsmiumClient" = "Osmium Client"; "ZenithClient" = "Zenith Client"
        "CymerClient" = "Cymer Client"; "NyrexClient" = "Nyrex Client"
        "RemnantClient" = "Remnant Client"; "AchillesClient" = "Achilles Client"
        "MistClient" = "Mist Client"; "RavenBPlus" = "Raven B+"
        "RavenB3" = "Raven B3"; "RavenWeave" = "RavenWeave"; "RavenFabric" = "RavenFabric"
        "KuraClient" = "Kura Client"; "ExosClient" = "Exos Client"
        "PulsarClient" = "Pulsar Client"; "CosmicClient" = "Cosmic Client"
        "ItamiClient" = "Itami Client"; "EntropyClient" = "Entropy Client"
        "DripClient" = "Drip Client"; "SlapClient" = "Slap Client"
        "SlinkyClient" = "Slinky Client"; "WhiteoutClient" = "Whiteout Client"
        "BreezeClient" = "Breeze Client"; "MangoClient" = "Mango Client"
        "GardeniaClient" = "Gardenia Client"; "SilkClient" = "Silk Client"
        "4EClient" = "4E Client"; "LowkeyClient" = "Lowkey Client"
        "AstraWare" = "AstraWare"; "AstralClient" = "Astral Client"; "Astralux" = "Astralux"
        "Gothaj" = "Gothaj Client"; "HydraClient" = "Hydra Client"; "LuneX" = "LuneX"
        "MeiLaaPlus" = "MeiLaa Plus"; "NoxxClient" = "Noxx Client"; "Thorium" = "Thorium Client"
        "WaterClient" = "Water Client"; "PulseClient" = "Pulse Client"; "pulse" = "Pulse Client"
        "XenonClient" = "Xenon Client"; "Xenon" = "Xenon Client"
        "dqrkis-client" = "Dqrkis Client"; "cwb-fabric" = "CrystalWare"
    }

    $detectedClientName = $null
    foreach ($p in $Mod.Patterns) {
        if ($clientNames.ContainsKey($p)) { $detectedClientName = $clientNames[$p]; break }
    }
    if (-not $detectedClientName) {
        foreach ($s in $Mod.FlaggedStrings) {
            if ($clientNames.ContainsKey($s)) { $detectedClientName = $clientNames[$s]; break }
        }
    }
    if (-not $detectedClientName) {
        $fnLower = $Mod.FileName.ToLower()
        foreach ($k in $clientNames.Keys) {
            if ($fnLower.Contains($k.ToLower())) {
                $detectedClientName = $clientNames[$k]
                break
            }
        }
    }

    $cheatCategories = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[string]]]::new()

    $combatKeywords = @("KillAura", "ClickAura", "MultiAura", "ForceField", "AimAssist", "AimBot", "AutoAim",
        "SilentAim", "TriggerBot", "Criticals", "ReachHack", "AutoCrit", "CritBypass", "WTap", "STap",
        "LegitAura", "TargetStrafe", "SmartCrit", "ComboMode", "AutoBlock", "BowAim", "Fakenick",
        "ＫｉｌｌＡｕｒａ", "ＣｌｉｃｋＡｕｒａ", "ＭｕｌｔｉＡｕｒａ", "ＦｏｒｃｅＦｉｅｌｄ", "ＡｉｍＡｓｓｉｓｔ",
        "ＴｒｉｇｇｅｒＢｏｔ", "ＳｍａｒｔＣｒｉｔ", "ＣｏｍｂｏＭｏｄｅ", "ＡｕｔｏＢｌｏｃｋ",
        "aimassist", "aim assist", "triggerbot", "trigger bot",
        "Silent Rotations", "SilentRotations", "Smooth Rotations", "Rotation Speed")
    $movementKeywords = @("FlyHack", "PacketFly", "SpeedHack", "BHop", "NoFallDamage", "AntiFall", "NoFall",
        "StepHack", "WaterWalk", "NoSlowdown", "JesusWalk", "ScaffoldWalk", "Scaffold", "Phase",
        "BoatFly", "ElytraSwap", "Freecam", "FreezePlayer", "No Clip", "NoClip",
        "ＳｐｅｅｄＨａｃｋ", "ＦｌｙＨａｃｋ", "ＮｏＳｌｏｗ", "ＮｏＦａｌｌ", "Ｓｃａｆｆｏｌｄ",
        "ＰａｃｋｅｔＦｌｙ", "ＪｅｓｕｓＷａｌｋ", "ＢｏａｔＦｌｙ", "ＦｒｅｅＣａｍ",
        "Move freely through walls", "ＳｃａｆｆｏｌｄＷａｌｋ")
    $crystalKeywords = @("AutoCrystal", "autocrystal", "auto crystal", "AutoHitCrystal", "CrystalAura",
        "CrystalPlaceDelay", "HitCrystalOptimizer", "FastCrystalMod", "ClientSidedCrystals",
        "LWFH Crystal", "WalksyCrystalOptimizerMod", "WalksyOptimizer", "autoCrystalPlaceClock",
        "dontPlaceCrystal", "dontBreakCrystal", "canPlaceCrystalServer",
        "ＡｕｔｏＣｒｙｓｔａｌ", "ＡｕｔｏＨｉｔＣｒｙｓｔａｌ", "ＣｒｙｓｔａｌＡｕｒａ",
        "ＬＷＦＨ Ｃｒｙｓｔａｌ", "PLACE_CRYSTAL", "BREAK_CRYSTAL")
    $anchorKeywords = @("AutoAnchor", "autoanchor", "auto anchor", "DoubleAnchor", "SafeAnchor",
        "AirAnchor", "AnchorAction", "AnchorMacro", "AnchorPredict", "AnchorAura",
        "ＡｕｔｏＡｎｃｈｏｒ", "ＤｏｕｂｌｅＡｎｃｈｏｒ", "ＳａｆｅＡｎｃｈｏｒ", "ＡｎｃｈｏｒＡｕｒａ")
    $totemKeywords = @("AutoTotem", "autototem", "auto totem", "InventoryTotem", "HoverTotem",
        "LegitTotem", "OffhandTotem", "Auto Totem Hit", "AutoTotemHit",
        "ＡｕｔｏＴｏｔｅｍ", "ＨｏｖｅｒＴｏｔｅｍ", "ＩｎｖｅｎｔｏｒｙＴｏｔｅｍ")
    $visualKeywords = @("ESP", "PlayerESP", "BlockESP", "Tracers", "XRayHack", "WallHack",
        "Chams", "Fullbright", "StorageESP",
        "ＥＳＰ", "Ｔｒａｃｅｒｓ", "Ｃｈａｍｓ", "ＸＲａｙ", "Ｆｕｌｌｂｒｉｇｈｔ")
    $exploitKeywords = @("PacketMine", "PacketCancel", "PacketDupe", "Nuker", "InstantBreak",
        "FastBreak", "FastPlace", "ChestStealer", "InvManager", "Burrow", "SelfTrap",
        "HoleFiller", "Disabler", "VelocitySpoof", "AntiKB", "NoKnockback", "GrimVelocity",
        "PingSpoof", "FakeLag", "BacktrackModule", "PearlClip", "BoatAura",
        "ＰａｃｋｅｔＭｉｎｅ", "ＰａｃｋｅｔＣａｎｃｅｌ", "Ｎｕｋｅｒ", "ＦａｓｔＢｒｅａｋ",
        "Ｄｉｓａｂｌｅｒ", "ＶｅｌｏｃｉｔｙＳｐｏｏｆ", "Ｂｕｒｒｏｗ", "ＳｅｌｆＴｒａｐ",
        "ＨｏｌｅＦｉｌｌｅｒ", "ＣｈｅｓｔＳｔｅａｌｅｒ", "ＢａｃｋＴｒａｃｋ", "ＰｅａｒｌＣｌｉｐ")
    $bypassKeywords = @("GrimBypass", "VulcanBypass", "MatrixBypass", "PolarBypass", "KarhuBypass",
        "VerusDisabler", "IntaveBypass", "WatchdogBypass", "SpartanBypass",
        "GrimDisabler", "VulcanDisabler", "MatrixDisabler", "PolarDisabler", "AACDisabler", "NCPDisabler",
        "GrimKillAura", "VulcanKillAura", "MatrixKillAura", "PolarKillAura", "KarhuKillAura",
        "GrimFly", "VulcanFly", "MatrixFly", "PolarFly", "KarhuFly",
        "GrimSpeed", "VulcanSpeed", "MatrixSpeed", "PolarSpeed", "KarhuSpeed",
        "GrimScaffold", "VulcanScaffold", "MatrixScaffold", "PolarScaffold", "KarhuScaffold")

    $allHits = [System.Collections.Generic.List[string]]::new()
    foreach ($p in $Mod.Patterns) { [void]$allHits.Add($p) }
    foreach ($s in $Mod.FlaggedStrings) { [void]$allHits.Add($s) }

    $hasCombat = $false; $hasMovement = $false; $hasCrystal = $false
    $hasAnchor = $false; $hasTotem = $false; $hasVisual = $false
    $hasExploit = $false; $hasBypass = $false
    foreach ($h in $allHits) {
        if (-not $hasCombat)   { foreach ($k in $combatKeywords)   { if ($h -eq $k) { $hasCombat = $true; break } } }
        if (-not $hasMovement) { foreach ($k in $movementKeywords) { if ($h -eq $k) { $hasMovement = $true; break } } }
        if (-not $hasCrystal)  { foreach ($k in $crystalKeywords)  { if ($h -eq $k) { $hasCrystal = $true; break } } }
        if (-not $hasAnchor)   { foreach ($k in $anchorKeywords)   { if ($h -eq $k) { $hasAnchor = $true; break } } }
        if (-not $hasTotem)    { foreach ($k in $totemKeywords)    { if ($h -eq $k) { $hasTotem = $true; break } } }
        if (-not $hasVisual)   { foreach ($k in $visualKeywords)   { if ($h -eq $k) { $hasVisual = $true; break } } }
        if (-not $hasExploit)  { foreach ($k in $exploitKeywords)  { if ($h -eq $k) { $hasExploit = $true; break } } }
        if (-not $hasBypass)   { foreach ($k in $bypassKeywords)   { if ($h -eq $k) { $hasBypass = $true; break } } }
    }

    $headerLabel = "CHEATER CAUGHT"
    if ($detectedClientName) { $headerLabel = "$detectedClientName DETECTED" }

    Write-Host "+-----------------------------------------------------------------------------+" -ForegroundColor Red
    Write-Host "| $headerLabel -- " -ForegroundColor Red -NoNewline
    Write-Host $Mod.FileName -ForegroundColor Yellow
    if ($Mod.ModIdentity -and $Mod.ModIdentity.ModId) {
        Write-Host "| claims to be: $($Mod.ModIdentity.Name) [$($Mod.ModIdentity.Loader)]" -ForegroundColor Gray
    }
    if ($Mod.OriginInfo -and $Mod.OriginInfo.IsDiscordOrigin) {
        Write-Host "| downloaded from discord (yikes)" -ForegroundColor DarkCyan
    } elseif ($Mod.OriginInfo -and $Mod.OriginInfo.IsCheatOrigin) {
        Write-Host "| downloaded from a known cheat site lol" -ForegroundColor DarkCyan
    } elseif ($Mod.OriginInfo -and $Mod.OriginInfo.SourceHost) {
        Write-Host "| came from: $($Mod.OriginInfo.SourceHost)" -ForegroundColor DarkCyan
    }
    Write-Host "+-----------------------------------------------------------------------------+" -ForegroundColor Red

    if ($hasCombat) {
        Write-Host "|  [COMBAT HACKS] got combat cheats in here fr" -ForegroundColor Red
        Write-Host "|    aura, aimbot, triggerbot, reach, crits type stuff" -ForegroundColor DarkGray
    }
    if ($hasMovement) {
        Write-Host "|  [MOVEMENT HACKS] movement cheats are NOT it bro" -ForegroundColor Red
        Write-Host "|    fly, speed, scaffold, noclip, bhop, no fall damage etc" -ForegroundColor DarkGray
    }
    if ($hasCrystal) {
        Write-Host "|  [CRYSTAL PVP] auto crystal stuff found no cap" -ForegroundColor Red
        Write-Host "|    auto place, auto break, crystal aura, crystal optimizer" -ForegroundColor DarkGray
    }
    if ($hasAnchor) {
        Write-Host "|  [ANCHOR CHEATS] anchor aura / auto anchor detected" -ForegroundColor Red
        Write-Host "|    double anchor, safe anchor, anchor macro, air anchor" -ForegroundColor DarkGray
    }
    if ($hasTotem) {
        Write-Host "|  [TOTEM CHEATS] auto totem stuff is crazy" -ForegroundColor Red
        Write-Host "|    auto totem, hover totem, inventory totem, offhand swap" -ForegroundColor DarkGray
    }
    if ($hasVisual) {
        Write-Host "|  [VISUALS / ESP] wallhacks and visuals detected" -ForegroundColor Red
        Write-Host "|    esp, tracers, chams, xray, fullbright" -ForegroundColor DarkGray
    }
    if ($hasExploit) {
        Write-Host "|  [EXPLOITS] packet exploits and game breaking stuff" -ForegroundColor Red
        Write-Host "|    velocity spoof, packet mine, anti kb, fast break, nuker" -ForegroundColor DarkGray
    }
    if ($hasBypass) {
        Write-Host "|  [AC BYPASS] anti-cheat bypass modules found" -ForegroundColor Red
        Write-Host "|    grim, vulcan, matrix, polar, karhu, verus, watchdog bypass" -ForegroundColor DarkGray
    }
    if (-not $hasCombat -and -not $hasMovement -and -not $hasCrystal -and -not $hasAnchor -and -not $hasTotem -and -not $hasVisual -and -not $hasExploit -and -not $hasBypass) {
        Write-Host "|  [SUS CONTENT] cheat strings found in this jar" -ForegroundColor Red
        $shownCount = 0
        foreach ($p in ($Mod.Patterns | Sort-Object)) {
            if ($shownCount -ge 8) { Write-Host "|    ... and $($Mod.Patterns.Count - 8) more" -ForegroundColor DarkGray; break }
            Write-Host "|    * $p" -ForegroundColor DarkYellow
            $shownCount++
        }
    }

    if ($Mod.FullwidthStrings -and $Mod.FullwidthStrings.Count -gt 0) {
        Write-Host "|  [UNICODE HIDING] using fullwidth unicode to hide cheat names" -ForegroundColor DarkCyan
        Write-Host "|    they literally renamed the cheats in unicode lmao" -ForegroundColor DarkGray
        foreach ($fw in ($Mod.FullwidthStrings | Sort-Object | Select-Object -First 5)) {
            $cleanFw = $fw.Replace("`r","").Replace("`n"," ").Trim()
            if ($cleanFw.Length -gt 50) { $cleanFw = $cleanFw.Substring(0, 47) + "..." }
            Write-Host "|    * $cleanFw" -ForegroundColor Cyan
        }
        if ($Mod.FullwidthStrings.Count -gt 5) {
            Write-Host "|    ... and $($Mod.FullwidthStrings.Count - 5) more hidden unicode strings" -ForegroundColor DarkGray
        }
    }

    if ($Mod.EncodedHits -and $Mod.EncodedHits.Count -gt 0) {
        Write-Host "|  [ENCODED PAYLOADS] base64 encoded cheat strings decoded" -ForegroundColor DarkYellow
        Write-Host "|    tried to hide the evidence with encoding, didnt work" -ForegroundColor DarkGray
    }

    if ($Mod.SelfDestructFlags -and $Mod.SelfDestructFlags.Count -gt 0) {
        Write-Host "|  [SELF DESTRUCT] this mod deletes itself after running" -ForegroundColor Red
        Write-Host "|    they tried to destroy the evidence bruh" -ForegroundColor DarkGray
        Write-Host "|    $($Mod.SelfDestructFlags.Count) self-destruct mechanism(s) found" -ForegroundColor Red
    }

    if ($Mod.ObfFlags -and $Mod.ObfFlags.Count -gt 0) {
        Write-Host "|  [OBFUSCATION] code is heavily scrambled to avoid detection" -ForegroundColor DarkCyan
        foreach ($of in ($Mod.ObfFlags | Select-Object -First 4)) {
            Write-Host "|    * $of" -ForegroundColor Cyan
        }
        if ($Mod.ObfFlags.Count -gt 4) {
            Write-Host "|    ... and $($Mod.ObfFlags.Count - 4) more obfuscation flags" -ForegroundColor DarkGray
        }
    }

    if ($Mod.TimestompFlags -and $Mod.TimestompFlags.Count -gt 0) {
        Write-Host "|  [TIMESTAMP FRAUD] file dates have been tampered with" -ForegroundColor DarkYellow
        Write-Host "|    someone messed with the timestamps to look legit" -ForegroundColor DarkGray
    }

    if ($Mod.ReflectionScore -ge 5) {
        Write-Host "|  [DEEP INJECTION] heavy JVM reflection and unsafe memory access" -ForegroundColor Red
        Write-Host "|    this mod is doing sketchy low-level java manipulation" -ForegroundColor DarkGray
    }

    if ($Mod.HighEntropyCount -ge 3) {
        Write-Host "|  [ENCRYPTED CODE] multiple encrypted / packed class files" -ForegroundColor DarkCyan
        Write-Host "|    $($Mod.HighEntropyCount) classes with suspiciously high entropy (encrypted bytecode)" -ForegroundColor DarkGray
    }

    Write-Host "+-----------------------------------------------------------------------------+" -ForegroundColor Red
    Write-Host ""
}

function Show-MacroResult {
    param($Mod)
    Write-Host "+-----------------------------------------------------------------------------+" -ForegroundColor DarkYellow
    Write-Host "| MACRO MOD CAUGHT -- " -ForegroundColor Yellow -NoNewline
    Write-Host $Mod.FileName -ForegroundColor White
    if ($Mod.ModIdentity -and $Mod.ModIdentity.ModId) {
        Write-Host "| says its: $($Mod.ModIdentity.Name) [$($Mod.ModIdentity.Loader)]" -ForegroundColor Gray
    }
    if ($Mod.OriginInfo -and $Mod.OriginInfo.IsDiscordOrigin) {
        Write-Host "| got this from discord smh" -ForegroundColor DarkCyan
    } elseif ($Mod.OriginInfo -and $Mod.OriginInfo.SourceHost) {
        Write-Host "| came from: $($Mod.OriginInfo.SourceHost)" -ForegroundColor DarkCyan
    }
    Write-Host "+-----------------------------------------------------------------------------+" -ForegroundColor DarkYellow

    if ($Mod.Macros.Count -gt 0) {
        Write-Host "|  [PVP MACROS] automation macros found in this mod" -ForegroundColor Yellow
        Write-Host "|    crystal macros, totem swap, anchor macro, auto pot, etc" -ForegroundColor DarkGray
        Write-Host "|    $($Mod.Macros.Count) macro pattern(s) matched" -ForegroundColor Yellow
    }

    $uniqueStrings = $Mod.FlaggedStrings | Where-Object { $Mod.Macros -notcontains $_ } | Sort-Object
    if ($uniqueStrings.Count -gt 0) {
        Write-Host "|  [MACRO STRINGS] additional sus macro-related strings found" -ForegroundColor DarkYellow
        Write-Host "|    $($uniqueStrings.Count) extra string(s) matched" -ForegroundColor DarkGray
    }

    Write-Host "+-----------------------------------------------------------------------------+" -ForegroundColor DarkYellow
    Write-Host ""
}

function Show-DeletedUsnResult {
    param($Artifact)
    Write-Host "  * [DELETED JAR] $($Artifact.FileName)" -ForegroundColor Red
    Write-Host "    what happened: $($Artifact.Reason)" -ForegroundColor DarkYellow
    Write-Host "    when: $($Artifact.Timestamp)" -ForegroundColor DarkGray
    Write-Host ""
}

$confirmedEntries   = @()
$unverifiedEntries  = @()
$flaggedEntries     = @()
$macroEntries       = @()
$obfEntries         = @()
$memoryDiscrepancies = @()
$usnArtifacts       = @()

$timer = [System.Diagnostics.Stopwatch]::StartNew()

$targetPid = 0
if ($mcProcess) { $targetPid = $mcProcess[0].Id }

Write-Host "[1/5] checking java memory for ghost cheats..." -ForegroundColor Cyan
if ($targetPid -gt 0) {
    try {
        $memReport = [FastScanner]::ScanProcessComprehensive($targetPid, $modsFolder)
        if ($memReport.UnloadedMods.Count -gt 0) {
            foreach ($um in $memReport.UnloadedMods) {
                $uName = [System.IO.Path]::GetFileName($um)
                [void]$memoryDiscrepancies.Add([PSCustomObject]@{
                    PID = $targetPid
                    FileName = $uName
                    JarPath = $um
                })
            }
        }
        if ($memReport.InjectedPEHeaders.Count -gt 0 -or $memReport.HookedExports.Count -gt 0) {
            Write-Host "  [ALERT] memory detours or injected binary regions detected" -ForegroundColor Red
        } else {
            Write-Host "  memory check clean" -ForegroundColor DarkGray
        }
    } catch {
        Write-Host "  memory scan failed or timed out, skipping" -ForegroundColor DarkYellow
    }
} else {
    Write-Host "  no active minecraft process running, skipping live memory scan" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "[2/5] scanning usn journal for deleted jars..." -ForegroundColor Cyan
$usnFindings = Scan-TargetUsnJournal -TargetDirectory $modsFolder
if ($usnFindings.Count -gt 0) {
    Write-Host "  found $($usnFindings.Count) deleted jar events in target folder" -ForegroundColor Yellow
    foreach ($uf in $usnFindings) {
        [void]$usnArtifacts.Add($uf)
    }
} else {
    Write-Host "  usn journal clean: no deleted mods found in target path" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "[3/5] checking mod hashes with modrinth / maven database..." -ForegroundColor Cyan
$idx = 0
$jarDigests = [System.Collections.Generic.List[object]]::new()
foreach ($jar in $jarFiles) {
    $idx++
    Show-ProgressLine -Current $idx -Total $totalFiles -FileName $jar.Name -Timer $timer
    $hashes = Get-FileDigest -Target $jar.FullName
    [void]$jarDigests.Add(@{
        Jar = $jar
        SHA1 = $hashes.SHA1
        SHA256 = $hashes.SHA256
        SHA512 = $hashes.SHA512
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
            $zip.Dispose()
        } catch { }

        if ($metaId) {
            $mrRes = Resolve-ModrinthProject -Slug $metaId
            if ($mrRes) {
                $verifiedName = $mrRes.Name
                $verifiedSource = "Modrinth"
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
            ModName = $verifiedName
            FileName = $jar.Name
            FilePath = $jar.FullName
            Verified = $true
            Source = $verifiedSource
        }
    } else {
        $unverifiedEntries += [PSCustomObject]@{ FileName = $jar.Name; FilePath = $jar.FullName }
    }
}

Write-Host "`r$(' ' * 100)`r" -NoNewline

$timer2 = [System.Diagnostics.Stopwatch]::StartNew()
Write-Host "[4/5] ripping through jar bytecodes and signatures..." -ForegroundColor Cyan
$idx = 0

foreach ($jar in $jarFiles) {
    $idx++
    Show-ProgressLine -Current $idx -Total $totalFiles -FileName $jar.Name -Timer $timer2

    $archiveData = Read-ArchiveData -Target $jar.FullName
    $patternResult = Start-PatternAnalysis -ArchiveData $archiveData -FilePath $jar.FullName
    $obfFlags = Start-StructureAnalysis -ArchiveData $archiveData -FilePath $jar.FullName
    $timestompFlags = Test-Timestomping -FilePath $jar.FullName -ArchiveData $archiveData
    $originInfo = Resolve-OriginMetadata -FilePath $jar.FullName -ArchiveData $archiveData
    $modIdentity = Get-ModIdentity -ArchiveData $archiveData

    $hasCheatPatterns   = $patternResult.Patterns.Count -gt 0
    $hasCheatStrings    = $patternResult.FlaggedStrings.Count -gt 0
    $hasFullwidthCheats = $patternResult.FullwidthStrings.Count -gt 0
    $hasEncodedCheats   = $patternResult.EncodedHits.Count -gt 0
    $hasSelfDestruct    = $patternResult.SelfDestructFlags.Count -gt 0
    $hasMacroPatterns   = $patternResult.Macros.Count -gt 0

    $isCheatClient = $originInfo.IsCheatOrigin -or $hasSelfDestruct -or $hasCheatPatterns -or $hasCheatStrings -or $hasFullwidthCheats -or $hasEncodedCheats
    $isMacroMod    = $hasMacroPatterns -and -not $isCheatClient

    if ($isCheatClient) {
        $flaggedEntries += [PSCustomObject]@{
            FileName = $jar.Name
            Patterns = $patternResult.Patterns
            FlaggedStrings = $patternResult.FlaggedStrings
            FullwidthStrings = $patternResult.FullwidthStrings
            EncodedHits = $patternResult.EncodedHits
            HighEntropyCount = $patternResult.HighEntropyCount
            ReflectionScore = $patternResult.ReflectionScore
            SelfDestructFlags = $patternResult.SelfDestructFlags
            TimestompFlags = $timestompFlags
            OriginInfo = $originInfo
            ModIdentity = $modIdentity
            ObfFlags = $obfFlags
        }
        $confirmedEntries = @($confirmedEntries | Where-Object { $_.FileName -ne $jar.Name })
        $unverifiedEntries = @($unverifiedEntries | Where-Object { $_.FileName -ne $jar.Name })
    } elseif ($isMacroMod) {
        $macroEntries += [PSCustomObject]@{
            FileName = $jar.Name
            Macros = $patternResult.Macros
            FlaggedStrings = $patternResult.FlaggedStrings
            OriginInfo = $originInfo
            ModIdentity = $modIdentity
        }
        $confirmedEntries = @($confirmedEntries | Where-Object { $_.FileName -ne $jar.Name })
        $unverifiedEntries = @($unverifiedEntries | Where-Object { $_.FileName -ne $jar.Name })
    }

    if ($obfFlags.Count -gt 0 -and -not $isCheatClient -and -not $isMacroMod) {
        $obfEntries += [PSCustomObject]@{ FileName = $jar.Name; Flags = $obfFlags }
    }
}

Write-Host "`r$(' ' * 100)`r" -NoNewline

Write-Host "[5/5] cooking up the final report..." -ForegroundColor Cyan
Write-Host ""
Write-Host ("=" * 77) -ForegroundColor DarkGray
Write-Host "                    DOOMSDAY CHEAT REPORT" -ForegroundColor White
Write-Host ("=" * 77) -ForegroundColor DarkGray
Write-Host ""

if ($flaggedEntries.Count -gt 0) {
    Write-Host ">>> DOOMSDAY DETECTED: CHEATS FOUND ($($flaggedEntries.Count) total)" -ForegroundColor Red
    Write-Host ""
    foreach ($mod in $flaggedEntries) {
        Show-FlaggedResult -Mod $mod
    }
}

if ($macroEntries.Count -gt 0) {
    Write-Host ">>> DOOMSDAY DETECTED: MACRO MODS ($($macroEntries.Count) total)" -ForegroundColor Yellow
    Write-Host ""
    foreach ($mod in $macroEntries) {
        Show-MacroResult -Mod $mod
    }
}

if ($memoryDiscrepancies.Count -gt 0) {
    Write-Host ">>> DOOMSDAY DETECTED: GHOST MODS IN MEMORY ($($memoryDiscrepancies.Count) total)" -ForegroundColor Red
    Write-Host "    these were loaded into java but someone deleted the files lol" -ForegroundColor DarkGray
    Write-Host ""
    foreach ($md in $memoryDiscrepancies) {
        Write-Host "  * $($md.FileName)" -ForegroundColor Red
        Write-Host "    was running from: $($md.JarPath)" -ForegroundColor DarkGray
        Write-Host "    status: executed in memory but gone from disk -- busted" -ForegroundColor Yellow
        Write-Host ""
    }
}

if ($usnArtifacts.Count -gt 0) {
    Write-Host ">>> DOOMSDAY DETECTED: DELETED JARS IN USN JOURNAL ($($usnArtifacts.Count) total)" -ForegroundColor DarkYellow
    Write-Host "    windows remembers what you deleted bro" -ForegroundColor DarkGray
    Write-Host ""
    foreach ($ua in $usnArtifacts) {
        Show-DeletedUsnResult -Artifact $ua
    }
}

if ($obfEntries.Count -gt 0) {
    Write-Host ">>> DOOMSDAY DETECTED: SKETCHY OBFUSCATION ($($obfEntries.Count) total)" -ForegroundColor DarkCyan
    Write-Host "    these mods have weird structure that normal mods dont have" -ForegroundColor DarkGray
    Write-Host ""
    foreach ($obf in $obfEntries) {
        Write-Host "  * $($obf.FileName)" -ForegroundColor Cyan
        foreach ($fl in $obf.Flags) {
            Write-Host "    - $fl" -ForegroundColor DarkGray
        }
        Write-Host ""
    }
}

if ($confirmedEntries.Count -gt 0) {
    Write-Host ">>> ALL GOOD: VERIFIED LEGIT MODS ($($confirmedEntries.Count) total)" -ForegroundColor DarkGreen
    Write-Host ""
    foreach ($cm in ($confirmedEntries | Sort-Object -Property ModName)) {
        Write-Host "  + " -ForegroundColor Green -NoNewline
        Write-Host "$($cm.ModName) " -ForegroundColor White -NoNewline
        Write-Host "($($cm.FileName)) " -ForegroundColor DarkGray -NoNewline
        Write-Host "[$($cm.Source)]" -ForegroundColor DarkCyan
    }
    Write-Host ""
}

if ($unverifiedEntries.Count -gt 0) {
    Write-Host ">>> NOT SURE ABOUT THESE: UNVERIFIED MODS ($($unverifiedEntries.Count) total)" -ForegroundColor Gray
    Write-Host ""
    foreach ($um in ($unverifiedEntries | Sort-Object -Property FileName)) {
        Write-Host "  ? " -ForegroundColor DarkGray -NoNewline
        Write-Host $um.FileName -ForegroundColor Gray
    }
    Write-Host ""
}

$threatLevel = "CLEAN"
$threatColor = "Green"
if ($flaggedEntries.Count -gt 0 -or $memoryDiscrepancies.Count -gt 0) {
    $threatLevel = "CHEATER FR FR"
    $threatColor = "Red"
} elseif ($macroEntries.Count -gt 0 -or $usnArtifacts.Count -gt 0) {
    $threatLevel = "KINDA SUS NGL"
    $threatColor = "Yellow"
} elseif ($obfEntries.Count -gt 0) {
    $threatLevel = "NEEDS A SECOND LOOK"
    $threatColor = "DarkYellow"
}

Write-Host ("=" * 77) -ForegroundColor DarkGray
Write-Host "                        FINAL VERDICT" -ForegroundColor White
Write-Host ("=" * 77) -ForegroundColor DarkGray
Write-Host "  threat level                 : $threatLevel" -ForegroundColor $threatColor
Write-Host "  total jars scanned           : $totalFiles" -ForegroundColor White
Write-Host "  cheats caught                : $($flaggedEntries.Count)" -ForegroundColor $(if ($flaggedEntries.Count -gt 0) { "Red" } else { "Green" })
Write-Host "  macro mods caught            : $($macroEntries.Count)" -ForegroundColor $(if ($macroEntries.Count -gt 0) { "Yellow" } else { "Green" })
Write-Host "  ghost mods in memory         : $($memoryDiscrepancies.Count)" -ForegroundColor $(if ($memoryDiscrepancies.Count -gt 0) { "Red" } else { "Green" })
Write-Host "  deleted jars (USN journal)   : $($usnArtifacts.Count)" -ForegroundColor $(if ($usnArtifacts.Count -gt 0) { "Yellow" } else { "Green" })
Write-Host "  verified legit mods          : $($confirmedEntries.Count)" -ForegroundColor Green
Write-Host "  unverified mods              : $($unverifiedEntries.Count)" -ForegroundColor Gray
Write-Host ("=" * 77) -ForegroundColor DarkGray
Write-Host ""
Write-Host "done in $([math]::Round($timer.Elapsed.TotalSeconds, 2))s -- gg" -ForegroundColor DarkGray
Write-Host ""
