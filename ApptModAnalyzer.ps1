[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null
Clear-Host

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin -and $Host.Name -eq "ConsoleHost" -and $PSCommandPath) {
    try {
        Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$PSCommandPath`"" -Verb RunAs -ErrorAction Stop
        exit
    } catch { }
}

$currentFont = (Get-ItemProperty "HKCU:\Console" -ErrorAction SilentlyContinue).FaceName
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

Write-Host "Enter mods folder path: " -NoNewline
Write-Host "(press Enter for default)" -ForegroundColor DarkGray
$modsPath = Read-Host "PATH"
Write-Host

if ([string]::IsNullOrWhiteSpace($modsPath)) {
    $modsPath = "$env:USERPROFILE\AppData\Roaming\.minecraft\mods"
    Write-Host "Target directory: " -NoNewline
    Write-Host $modsPath -ForegroundColor White
    Write-Host
}

if (-not (Test-Path $modsPath -PathType Container)) {
    Write-Host "Error: Directory does not exist or is not accessible." -ForegroundColor Red
    Write-Host "Path: $modsPath" -ForegroundColor Gray
    Write-Host
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host "Target directory confirmed: $modsPath" -ForegroundColor Green
Write-Host

$mcProcess = Get-Process javaw -ErrorAction SilentlyContinue
if (-not $mcProcess) {
    $mcProcess = Get-Process java -ErrorAction SilentlyContinue
}

if ($mcProcess) {
    try {
        $startTime = $mcProcess.StartTime
        $uptime = (Get-Date) - $startTime
        Write-Host "Active Game Process:" -ForegroundColor DarkCyan
        Write-Host "   $($mcProcess.Name) (PID: $($mcProcess.Id)) started at $startTime" -ForegroundColor Gray
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

public static class FastScanner {
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

    public static List<string> ParseConstantPool(byte[] raw) {
        List<string> res = new List<string>();
        if (raw == null || raw.Length < 10) return res;
        if (raw[0] != 0xCA || raw[1] != 0xFE || raw[2] != 0xBA || raw[3] != 0xBE) return res;
        int cpCount = (raw[8] << 8) | raw[9];
        int pos = 10;
        for (int i = 1; i < cpCount && pos < raw.Length; i++) {
            byte tag = raw[pos++];
            switch (tag) {
                case 1:
                    if (pos + 1 >= raw.Length) return res;
                    int len = (raw[pos] << 8) | raw[pos + 1];
                    pos += 2;
                    if (len > 0 && pos + len <= raw.Length) {
                        try { res.Add(Encoding.UTF8.GetString(raw, pos, len)); } catch { }
                    }
                    pos += len;
                    break;
                case 7: case 8: case 16: case 19: case 20: pos += 2; break;
                case 3: case 4: case 9: case 10: case 11: case 12: case 17: case 18: pos += 4; break;
                case 5: case 6: pos += 8; i++; break;
                case 15: pos += 3; break;
                default: return res;
            }
        }
        return res;
    }
}

public static class CurseForgeHasher {
    public static long ComputeHash(string filePath) {
        byte[] raw = File.ReadAllBytes(filePath);
        using (var ms = new MemoryStream()) {
            foreach (byte b in raw) {
                if (b != 9 && b != 10 && b != 13 && b != 32) ms.WriteByte(b);
            }
            byte[] data = ms.ToArray();
            return MurmurHash2(data, data.Length, 1);
        }
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
try { Add-Type -TypeDefinition $fastScannerSource -Language CSharp -ErrorAction SilentlyContinue } catch { }

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
    return @{
        SHA1   = (Get-FileHash -Path $Target -Algorithm SHA1).Hash
        SHA256 = (Get-FileHash -Path $Target -Algorithm SHA256).Hash
        SHA512 = (Get-FileHash -Path $Target -Algorithm SHA512).Hash
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
    "java/lang/instrument/Instrumentation", "premain", "agentmain"
)

$script:cheatDomains = @(
    "doomsdayclient.com", "prestigeclient.vip", "vape.gg", "intent.store",
    "riseclient.com", "astolfo.club", "dqrkis.xyz", "198macros.com",
    "novaclient.lol", "speckey.shop", "catbox.moe", "anonfiles.com",
    "gofile.io", "file.io", "transfer.sh", "pixeldrain.com",
    "liquidbounce.net", "fdpclient.cn", "aristois.net",
    "rusherhack.org", "futureclient.net", "konasclient.com", "sigma-client.com",
    "tenacity.dev", "moonclient.xyz", "augustusclient.com", "azuraclient.xyz",
    "entropy.club", "drip.gg", "slinky.gg", "haruclient.com", "antic.rip",
    "novowareclient.com", "hellclient.xyz", "cyde.xyz", "flux.gg",
    "thevaultofficial.vercel.app", "opai.club", "22qqclient.com",
    "pandaware.vip", "skilledclient.xyz",
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
    "AirWalk", "WaterSpeed", "TimerExploit", "Chams", "GlowESP",
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
    "Novoware", "NovowareClient", "novoware", "novowareclient",
    "HellClient", "hellclient", "Hell-Client", "HellClientV2",
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
    "Catalyst", "Kino", "Pyro", "Mio", "Wolfram",
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
    "DynamicSynthesizer", "MemoryScrubber", "BytecodePatcher"
)

$script:macroIdentifiers = @(
    "CPvPMacros", "cpvpmacros", "ClickCrystals", "clickcrystals",
    "CrystalMacroMod", "AutoInventoryTotem", "AnchorExplorer",
    "AirAnchorMacro", "FastXPMacro", "NoBounce", "FastCrystal",
    "198Macro", "Macro198", "198macros", "WebMacro", "AutoWeb", "AntiWeb",
    "DoubleHand", "AutoDoubleHand", "RefillTotem", "HotbarManager",
    "DtapMacro", "AutoDtap", "KeyPearl", "LootYeeter", "AutoPotRefill",
    "AutoGlowstone", "FastAnchorPlace", "AutoTotemSwap", "InventoryRefillMacro",
    "FastDropper", "AutoDisconnectMacro", "QuickSlotMacro", "ArmorSwapMacro"
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
    "Novoware", "NovowareClient", "novowareclient", "HellClient", "hellclient",
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
    "ClientSidedCrystals", "AirAnchorMacro"
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

function Start-USNAnalysis {
    param([string]$ModsDir)
    $results = [System.Collections.Generic.List[string]]::new()
    $drive = [System.IO.Path]::GetPathRoot($ModsDir).Trim('\')
    if (-not $drive) { return $results }
    try {
        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
        $pinfo.FileName = "fsutil.exe"
        $pinfo.Arguments = "usn readjournal $drive csv"
        $pinfo.RedirectStandardOutput = $true
        $pinfo.UseShellExecute = $false
        $pinfo.CreateNoWindow = $true
        $proc = [System.Diagnostics.Process]::Start($pinfo)
        $reader = $proc.StandardOutput

        $fileEvents = @{}
        $normPath = $ModsDir.Replace("/", "\").TrimEnd("\")

        $readCount = 0
        while (-not $reader.EndOfStream -and $readCount -lt 15000) {
            $line = $reader.ReadLine()
            $readCount++
            if (-not $line -or $line -notmatch '\.jar') { continue }
            $parts = $line -split ','
            if ($parts.Count -ge 8) {
                $name = $parts[0].Trim('"')
                $path = $parts[7].Trim('"')
                $reason = $parts[3].Trim('"')
                if ($name -match '\.jar$' -and $path -match [regex]::Escape($normPath)) {
                    if (-not $fileEvents.ContainsKey($name)) {
                        $fileEvents[$name] = [System.Collections.Generic.List[string]]::new()
                    }
                    [void]$fileEvents[$name].Add($reason)
                }
            }
        }
        try { if (-not $proc.HasExited) { $proc.Kill() } } catch { }
        $proc.Dispose()

        foreach ($fileName in $fileEvents.Keys) {
            $seqStr = ($fileEvents[$fileName]) -join " -> "
            if ($seqStr -match "File Delete \| Close -> Rename: old name -> Rename: new name -> Rename: new name \| Close") {
                [void]$results.Add("$fileName|USN: File replacement & self-destruct cycle detected")
            } elseif ($seqStr -match "Data Extend \| Data Truncation -> Data Extend \| Data Truncation \| Close") {
                [void]$results.Add("$fileName|USN: Type 1 payload overwrite sequence detected")
            } elseif ($seqStr -match "Data Truncation -> Data Extend \| Data Truncation") {
                [void]$results.Add("$fileName|USN: Type 2 stream truncation sequence detected")
            } elseif ($seqStr -match "Data Overwrite" -and $seqStr -match "Security Change" -and $seqStr -match "Basic Info Change") {
                [void]$results.Add("$fileName|USN: Metadata overwrite & security descriptor modification detected")
            } elseif ($seqStr -match "Data Overwrite \| Data Extend -> Data Overwrite \| Data Extend \| Close") {
                [void]$results.Add("$fileName|USN: HEX direct byte overwrite sequence detected")
            }
        }
    } catch { }
    return $results
}

function Test-Timestomping {
    param([string]$FilePath, $ArchiveData)
    $flags = [System.Collections.Generic.List[string]]::new()
    try {
        $fileInfo = Get-Item $FilePath -ErrorAction SilentlyContinue
        if (-not $fileInfo) { return $flags }
        $fileWrite = $fileInfo.LastWriteTimeUtc
        $fileCreate = $fileInfo.CreationTimeUtc

        if ($fileWrite.Year -gt (Get-Date).Year + 2) {
            [void]$flags.Add("Anomalous future date stamp on container ($($fileInfo.LastWriteTime))")
        }

        $internalDates = [System.Collections.Generic.List[datetime]]::new()
        if ($ArchiveData.ZipEntries) {
            foreach ($entry in $ArchiveData.ZipEntries) {
                if ($entry.FullName -match '\.class$' -and $entry.LastWriteTime.Year -gt 1980) {
                    [void]$internalDates.Add($entry.LastWriteTime.UtcDateTime)
                }
            }
        }

        if ($internalDates.Count -gt 5) {
            $sortedDates = $internalDates | Sort-Object
            $latestClassDate = $sortedDates[-1]
            if ($fileWrite.Year -le 2020 -and $latestClassDate.Year -ge 2024) {
                [void]$flags.Add("Timestamp backdating detected — File modified: $($fileInfo.LastWriteTime.Year) vs Compiled code: $($latestClassDate.Year)")
            }
        }
    } catch { }
    return $flags
}

function Start-TempScan {
    $results = [System.Collections.Generic.List[string]]::new()
    $tempPaths = @($env:TEMP, "$env:LOCALAPPDATA\Temp") | Select-Object -Unique
    $mcProc = Get-Process javaw -ErrorAction SilentlyContinue
    if (-not $mcProc) { $mcProc = Get-Process java -ErrorAction SilentlyContinue }

    $sessionStart = if ($mcProc) { $mcProc.StartTime.AddMinutes(-5) } else { (Get-Date).AddHours(-2) }

    foreach ($tp in $tempPaths) {
        if (-not (Test-Path $tp)) { continue }
        try {
            $files = Get-ChildItem -Path $tp -File -ErrorAction SilentlyContinue | Where-Object {
                $_.LastWriteTime -ge $sessionStart -and
                ($_.Name -match "cleaner.*\.bat|destruct.*\.vbs|injector.*\.dll|drop.*\.jar|patcher.*\.exe")
            }
            foreach ($f in $files) {
                [void]$results.Add("Suspicious temp file: $($f.Name) (Size: $($f.Length) bytes, Created: $($f.LastWriteTime))")
            }
        } catch { }
    }
    return $results
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

            $isStdLib = $e.FullName -match '^(kotlin/|kotlinx/|org/jetbrains/|scala/|com/google/gson/|it/unimi/dsi/fastutil/|org/apache/commons/|org/joml/|com/ibm/icu/)'
            if (-not $isStdLib -and ($e.FullName -match '\.(class|json|toml|info)$' -or $e.FullName -match 'MANIFEST\.MF' -or ($e.Length -gt 0 -and $e.Length -lt 65536 -and $e.FullName -match '\.(png|jpg|bin|dat|ico|txt|properties)$'))) {
                try {
                    $s = $e.Open(); $m = [System.IO.MemoryStream]::new()
                    $s.CopyTo($m); $s.Close()
                    $classBytes[$e.FullName] = $m.ToArray(); $m.Dispose()
                } catch { }
            }
        }
        foreach ($nj in ($zip.Entries | Where-Object { $_.FullName -match "^META-INF/jars/.+\.jar$" })) {
            try {
                $ns = $nj.Open(); $ms = [System.IO.MemoryStream]::new()
                $ns.CopyTo($ms); $ns.Close(); $ms.Position = 0
                $iz = [System.IO.Compression.ZipArchive]::new($ms, [System.IO.Compression.ZipArchiveMode]::Read)
                foreach ($ie in $iz.Entries) {
                    [void]$nestedNames.Add($ie.FullName)
                    $isStdLib = $ie.FullName -match '^(kotlin/|kotlinx/|org/jetbrains/|scala/|com/google/gson/|it/unimi/dsi/fastutil/|org/apache/commons/|org/joml/|com/ibm/icu/)'
                    if (-not $isStdLib -and $ie.FullName -match '\.(class|json)$') {
                        try {
                            $is = $ie.Open(); $im = [System.IO.MemoryStream]::new()
                            $is.CopyTo($im); $is.Close()
                            $classBytes["NESTED:$($ie.FullName)"] = $im.ToArray(); $im.Dispose()
                        } catch { }
                    }
                }
                $iz.Dispose(); $ms.Dispose()
            } catch { }
        }
        $zip.Dispose()
    } catch { }
    return @{ Entries = $entryNames; ClassBytes = $classBytes; NestedEntries = $nestedNames; ZipEntries = $zipEntriesList }
}

function Start-DeepBytecodeScan {
    param($ArchiveData)
    $flags = [System.Collections.Generic.List[string]]::new()
    foreach ($k in $ArchiveData.ClassBytes.Keys) {
        if ($k -notmatch '\.class$' -and $k -notmatch 'META-INF' -and $k -notmatch '\.(json|toml|info)$' -and $k -notmatch '^NESTED:') {
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
        }
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
                if ($decoded -match 'discord\.gg/|webhook|api\.novaclient' -or $decoded -match 'https?://[a-zA-Z0-9_\.]+/loader') {
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
        InternalUrls = [System.Collections.Generic.List[string]]::new()
    }

    $zoneData = Get-Content -Raw -Stream Zone.Identifier $FilePath -ErrorAction SilentlyContinue
    if ($zoneData) {
        if ($zoneData -match "HostUrl=(.+)") { $info.ExactUrl = $matches[1].Trim() }
        if ($zoneData -match "ReferrerUrl=(.+)") { $info.Referrer = $matches[1].Trim() }
    }

    if ($info.ExactUrl) {
        $u = $info.ExactUrl
        if ($u -match "modrinth\.com") { $info.SourceHost = "Modrinth" }
        elseif ($u -match "curseforge\.com") { $info.SourceHost = "CurseForge" }
        elseif ($u -match "github\.com") { $info.SourceHost = "GitHub" }
        elseif ($u -match "mediafire\.com") { $info.SourceHost = "MediaFire" }
        elseif ($u -match "discord\.com|discordapp\.com|cdn\.discordapp\.com") { $info.SourceHost = "Discord" }
        elseif ($u -match "dropbox\.com") { $info.SourceHost = "Dropbox" }
        elseif ($u -match "drive\.google\.com") { $info.SourceHost = "Google Drive" }
        elseif ($u -match "mega\.nz|mega\.co\.nz") { $info.SourceHost = "MEGA" }
        elseif ($u -match "https?://(?:www\.)?([^/]+)") { $info.SourceHost = $matches[1] }
        else { $info.SourceHost = $u }

        foreach ($cd in $script:cheatDomains) {
            if ($u.ToLower().Contains($cd)) {
                $info.IsCheatOrigin = $true
                break
            }
        }
    }

    foreach ($key in $ArchiveData.ClassBytes.Keys) {
        if ($key -eq "MANIFEST.MF" -or $key -eq "META-INF/MANIFEST.MF") {
            $mf = [System.Text.Encoding]::UTF8.GetString($ArchiveData.ClassBytes[$key])
            if ($mf -match "(?:Implementation-URL|Specification-URL|Repository):\s*(.+)") {
                [void]$info.InternalUrls.Add($matches[1].Trim())
            }
        }
        if ($key -eq "fabric.mod.json") {
            try {
                $fjson = [System.Text.Encoding]::UTF8.GetString($ArchiveData.ClassBytes[$key]).Trim([char]0xFEFF) | ConvertFrom-Json
                if ($fjson.contact) {
                    if ($fjson.contact.homepage) { [void]$info.InternalUrls.Add($fjson.contact.homepage) }
                    if ($fjson.contact.sources) { [void]$info.InternalUrls.Add($fjson.contact.sources) }
                }
            } catch { }
        }
        if ($key -eq "META-INF/mods.toml") {
            $toml = [System.Text.Encoding]::UTF8.GetString($ArchiveData.ClassBytes[$key])
            if ($toml -match 'displayURL\s*=\s*"([^"]+)"') { [void]$info.InternalUrls.Add($matches[1]) }
        }
    }

    return $info
}

function Get-ModIdentity {
    param($ArchiveData)
    $identity = @{ ModId = ""; Name = ""; Version = ""; Loader = "unknown" }
    foreach ($key in $ArchiveData.ClassBytes.Keys) {
        if ($key -eq "fabric.mod.json") {
            try {
                $data = [System.Text.Encoding]::UTF8.GetString($ArchiveData.ClassBytes[$key]).Trim([char]0xFEFF) | ConvertFrom-Json
                $identity.ModId = $data.id
                $identity.Name = $data.name
                $identity.Version = $data.version
                $identity.Loader = "Fabric"
            } catch { }
        }
        if ($key -eq "META-INF/mods.toml") {
            try {
                $text = [System.Text.Encoding]::UTF8.GetString($ArchiveData.ClassBytes[$key])
                $identity.Loader = "Forge"
                if ($text -match 'modId\s*=\s*"([^"]+)"') { $identity.ModId = $matches[1] }
                if ($text -match 'displayName\s*=\s*"([^"]+)"') { $identity.Name = $matches[1] }
                if ($text -match 'version\s*=\s*"([^"]+)"') { $identity.Version = $matches[1] }
            } catch { }
        }
        if ($key -eq "mcmod.info") {
            try {
                $data = [System.Text.Encoding]::UTF8.GetString($ArchiveData.ClassBytes[$key]).Trim([char]0xFEFF) | ConvertFrom-Json
                $identity.Loader = "Forge-Legacy"
                if ($data[0]) {
                    $identity.ModId = $data[0].modid
                    $identity.Name = $data[0].name
                    $identity.Version = $data[0].version
                }
            } catch { }
        }
    }
    return $identity
}

function Test-ModSpoofing {
    param([string]$FileName, $ModIdentity, $ArchiveData)
    $flags = [System.Collections.Generic.List[string]]::new()
    foreach ($name in $script:knownModIdentities.Keys) {
        if ($FileName.ToLower().Contains($name)) {
            $expected = $script:knownModIdentities[$name]
            if ($ModIdentity.ModId -and $ModIdentity.ModId -ne $expected.id) {
                [void]$flags.Add("Identity spoofing — File claims '$name' but internal mod ID is '$($ModIdentity.ModId)'")
            }
        }
    }
    return $flags
}

function Start-PatternAnalysis {
    param($ArchiveData)

    $foundPatterns  = [System.Collections.Generic.HashSet[string]]::new()
    $foundMacros    = [System.Collections.Generic.HashSet[string]]::new()
    $foundStrings   = [System.Collections.Generic.HashSet[string]]::new()
    $foundFullwidth = [System.Collections.Generic.HashSet[string]]::new()
    $encodedHits    = [System.Collections.Generic.List[string]]::new()
    $highEntropyCount = 0
    $reflectionScore  = 0
    $selfDestructFlags = [System.Collections.Generic.List[string]]::new()

    foreach ($entry in $ArchiveData.Entries) {
        foreach ($m in $script:identifierMatcher.Matches($entry)) { [void]$foundPatterns.Add($m.Value) }
        foreach ($m in $script:macroMatcher.Matches($entry)) { [void]$foundMacros.Add($m.Value) }
    }
    foreach ($entry in $ArchiveData.NestedEntries) {
        foreach ($m in $script:identifierMatcher.Matches($entry)) { [void]$foundPatterns.Add($m.Value) }
        foreach ($m in $script:macroMatcher.Matches($entry)) { [void]$foundMacros.Add($m.Value) }
    }

    $hasSilentAim = $false; $hasAutoCrystalMath = $false; $hasVelocitySpoof = $false
    $hasScaffoldMath = $false; $hasNettyIntercept = $false; $hasGLFWInputHook = $false
    $hasAttackCooldownMod = $false; $hasReachHitboxMath = $false; $hasAutoClickerMath = $false
    $hasTriggerBotLogic = $false; $hasAutoTotemLogic = $false; $hasFastPlaceLogic = $false
    $hasPacketMineLogic = $false; $hasNoFallLogic = $false; $hasBlinkLogic = $false
    $hasAutoPotLogic = $false; $hasBacktrackLogic = $false; $hasWebhookExfil = $false
    $hasMemoryScrub = $false; $targetedCoreMixinCount = 0
    $hasFreeLookDecouple = $false; $hasAutoWebLogic = $false; $hasAutoMaceLogic = $false
    $hasCriticalsDesync = $false; $hasFastBowLogic = $false; $hasSpinBotLogic = $false

    foreach ($key in $ArchiveData.ClassBytes.Keys) {
        if ($key -match '\.(class|json)$' -or $key -match 'MANIFEST\.MF') {
            $bytes = $ArchiveData.ClassBytes[$key]
            $ascii = [System.Text.Encoding]::ASCII.GetString($bytes)
            $utf8  = [System.Text.Encoding]::UTF8.GetString($bytes)

            foreach ($m in $script:identifierMatcher.Matches($ascii)) { [void]$foundPatterns.Add($m.Value) }
            foreach ($m in $script:macroMatcher.Matches($ascii)) { [void]$foundMacros.Add($m.Value) }

            foreach ($s in $script:contentLookup) {
                if ($ascii.Contains($s)) { [void]$foundStrings.Add($s); continue }
                if ($utf8.Contains($s))  { [void]$foundStrings.Add($s) }
            }

            foreach ($m in $script:wideCharMatcher.Matches($utf8)) {
                [void]$foundFullwidth.Add($m.Value)
            }

            if ($key -match 'mixins?\.json$') {
                if ($ascii -match 'ClientPlayerEntity') { $targetedCoreMixinCount++ }
                if ($ascii -match 'ClientPlayNetworkHandler') { $targetedCoreMixinCount++ }
                if ($ascii -match 'ClientConnection') { $targetedCoreMixinCount++ }
                if ($ascii -match 'ClientPlayerInteractionManager') { $targetedCoreMixinCount++ }
                if ($ascii -match 'GameRenderer') { $targetedCoreMixinCount++ }
                if ($ascii -match 'InGameHud') { $targetedCoreMixinCount++ }
                if ($ascii -match 'Keyboard|Mouse') { $targetedCoreMixinCount++ }
            }

            if ($key -match '\.class$') {
                $cpStrings = Read-ConstantPool -Raw $bytes
                if ($cpStrings.Count -gt 0) {
                    $localHasYawPitch = $false; $localHasLookOnGround = $false; $localHasSetYaw = $false
                    $localHasDamageUtil = $false; $localHasExplosion = $false; $localHasVec3d = $false
                    $localHasVelocityPacket = $false; $localHasVelocityMutate = $false
                    $localHasBlockHitResult = $false; $localHasDirectionValues = $false
                    $localHasDeleteCommand = $false; $localHasDeleteOnExit = $false; $localHasShutdownHook = $false
                    $localHasNettyHandler = $false; $localHasGLFWSetKey = $false
                    $localHasBoxExpand = $false; $localHasReachCheck = $false
                    $localHasRandomCPS = $false; $localHasMouseDispatch = $false
                    $localHasCrosshairTarget = $false; $localHasDoAttack = $false
                    $localHasTotemItem = $false; $localHasSlotSwap = $false
                    $localHasCooldownField = $false; $localHasActionPackets = $false
                    $localHasFallDistance = $false; $localHasOnGroundSpoof = $false
                    $localHasPacketQueue = $false; $localHasPotItem = $false
                    $localHasPitch90 = $false; $localHasTrackedPos = $false
                    $localHasWebhook = $false; $localHasUnsafeMem = $false

                    foreach ($cp in $cpStrings) {
                        if ($cp -match "yaw|pitch") { $localHasYawPitch = $true }
                        if ($cp.Contains("PlayerMoveC2SPacket`$LookAndOnGround") -or $cp.Contains("PlayerMoveC2SPacket`$Full")) { $localHasLookOnGround = $true }
                        if ($cp.Contains("setYaw") -or $cp.Contains("setPitch")) { $localHasSetYaw = $true }

                        if ($cp.Contains("DamageUtil") -and $cp.Contains("getDamageLeft")) { $localHasDamageUtil = $true }
                        if ($cp.Contains("Explosion") -and $cp.Contains("getExposure")) { $localHasExplosion = $true }
                        if ($cp.Contains("net/minecraft/util/math/Vec3d")) { $localHasVec3d = $true }

                        if ($cp.Contains("EntityVelocityUpdateS2CPacket")) { $localHasVelocityPacket = $true }
                        if ($cp.Contains("setVelocity") -or $cp.Contains("velocityModified")) { $localHasVelocityMutate = $true }

                        if ($cp.Contains("BlockHitResult") -and $cp.Contains("Direction")) { $localHasBlockHitResult = $true }
                        if ($cp.Contains("RaycastContext") -and $cp.Contains("RaycastContext`$ShapeType")) { $localHasDirectionValues = $true }

                        if ($cp.Contains("ChannelInboundHandlerAdapter") -or $cp.Contains("ChannelOutboundHandlerAdapter")) { $localHasNettyHandler = $true }
                        if ($cp.Contains("glfwSetKeyCallback") -or $cp.Contains("glfwSetMouseButtonCallback") -or $cp.Contains("GlobalScreen")) { $localHasGLFWSetKey = $true }
                        if ($cp.Contains("setItemUseCooldown") -or $cp.Contains("setBlockBreakingCooldown") -or $cp -match "blockBreakingCooldown\s*=\s*0|itemUseCooldown\s*=\s*0|NoAttackCooldown|fastPlaceDelay") { $localHasCooldownField = $true }

                        if ($cp.Contains("getBoundingBox") -and ($cp.Contains("expand") -or $cp.Contains("stretch") -or $cp.Contains("getExtendedHitBox"))) { $localHasBoxExpand = $true }
                        if ($cp.Contains("getTargetedEntity") -and ($cp.Contains("reachDistance") -or $cp.Contains("getActualAttackRange") -or $cp.Contains("HitboxExpand"))) { $localHasReachCheck = $true }

                        if ($cp -match "minCPS|maxCPS|cpsDelay|randomCPS|clickDelay") { $localHasRandomCPS = $true }
                        if ($cp.Contains("mousePress") -or $cp.Contains("mouse_event") -or $cp.Contains("sendClick")) { $localHasMouseDispatch = $true }

                        if ($cp.Contains("crosshairTarget") -or $cp.Contains("targetedEntity")) { $localHasCrosshairTarget = $true }
                        if ($cp.Contains("attackEntity") -or $cp.Contains("doAttack") -or $cp.Contains("interactEntity")) { $localHasDoAttack = $true }

                        if ($cp.Contains("totem_of_undying") -or $cp.Contains("TOTEM_OF_UNDYING") -or $cp.Contains("field_8288")) { $localHasTotemItem = $true }
                        if ($cp.Contains("SlotActionType") -and ($cp.Contains("clickSlot") -or $cp.Contains("onSlotClick") -or $cp.Contains("quickMoveSlot"))) { $localHasSlotSwap = $true }

                        if ($cp.Contains("PlayerActionC2SPacket`$Action") -and $cp.Contains("START_DESTROY_BLOCK") -and $cp.Contains("STOP_DESTROY_BLOCK")) { $localHasActionPackets = $true }

                        if ($cp.Contains("PlayerMoveC2SPacket`$OnGroundOnly") -and ($cp -match "noFall|NoFall|groundSpoof|spoofGround|cancelFall")) { $localHasOnGroundSpoof = $true }

                        if ($cp.Contains("ConcurrentLinkedQueue") -and ($cp.Contains("Packet") -or $cp.Contains("sendPacket")) -and ($cp -match "blink|Blink|packetQueue|packetBuffer")) { $localHasPacketQueue = $true }

                        if ($cp.Contains("splash_potion") -and ($cp.Contains("pitch = 90") -or $cp.Contains("pitch=90") -or $cp.Contains("lookAtPitch") -or $cp -match "autoPot|AutoPot|potRefill")) { $localHasPotItem = $true }

                        if ($cp -match "backtrack|Backtrack|PositionHistory|historyPositions|lagCompensation|tickHistory") { $localHasTrackedPos = $true }

                        if ($cp -match "discord\.com/api/webhooks|api\.novaclient\.lol|rentry\.co/|pastebin\.com/raw") { $localHasWebhook = $true }
                        if ($cp.Contains("sun/misc/Unsafe") -and ($cp.Contains("allocateMemory") -or $cp.Contains("putAddress") -or $cp.Contains("freeMemory"))) { $localHasUnsafeMem = $true }

                        if ($cp.Contains("changeLookDirection") -and ($cp.Contains("Camera") -or $cp.Contains("MatrixStack")) -and ($cp -match "freeLook|FreeLook|cameraPitch|cameraYaw|perspectiveMode")) { $hasFreeLookDecouple = $true }
                        if (($cp.Contains("cobweb") -or $cp.Contains("COBWEB") -or $cp.Contains("field_8783")) -and ($cp.Contains("PlayerInteractBlockC2SPacket") -or $cp.Contains("interactBlock")) -and ($cp -match "autoWeb|AutoWeb|webMacro|placeWeb")) { $hasAutoWebLogic = $true }
                        if (($cp.Contains("mace") -or $cp.Contains("MACE") -or $cp.Contains("field_50153")) -and ($cp.Contains("fallDistance") -or $cp.Contains("getVelocity")) -and ($cp -match "autoMace|AutoMace|maceSwap|MaceSwap|spearSwap")) { $hasAutoMaceLogic = $true }
                        if ($cp.Contains("PlayerMoveC2SPacket`$PositionAndOnGround") -and ($cp -match "0\.0625|0\.000001|critOffset|criticals|smartCrit")) { $hasCriticalsDesync = $true }
                        if (($cp.Contains("bow") -or $cp.Contains("BOW") -or $cp.Contains("field_8255")) -and ($cp.Contains("RELEASE_USE_ITEM") -or $cp.Contains("stopUsingItem")) -and ($cp -match "fastBow|FastBow|bowSpam|BowSpam|instantBow")) { $hasFastBowLogic = $true }
                        if (($cp.Contains("PlayerMoveC2SPacket`$LookAndOnGround") -or $cp.Contains("PlayerMoveC2SPacket`$Full")) -and ($cp -match "spinBot|SpinBot|antiAim|AntiAim|yawOffset|jitterYaw")) { $hasSpinBotLogic = $true }

                        if ($cp -match "cmd\.exe\s+/c\s+timeout|cmd\.exe\s+/c\s+del|powershell.*remove-item|taskkill\s+/f") { $localHasDeleteCommand = $true }
                        if ($cp.Contains("deleteOnExit")) { $localHasDeleteOnExit = $true }
                        if ($cp.Contains("addShutdownHook")) { $localHasShutdownHook = $true }
                    }

                    if ($localHasYawPitch -and $localHasLookOnGround -and -not $localHasSetYaw) { $hasSilentAim = $true }
                    if ($localHasDamageUtil -and $localHasExplosion -and $localHasVec3d) { $hasAutoCrystalMath = $true }
                    if ($localHasVelocityPacket -and $localHasVelocityMutate) { $hasVelocitySpoof = $true }
                    if ($localHasBlockHitResult -and $localHasDirectionValues) { $hasScaffoldMath = $true }
                    if ($localHasNettyHandler) { $hasNettyIntercept = $true }
                    if ($localHasGLFWSetKey) { $hasGLFWInputHook = $true }
                    if ($localHasBoxExpand -and $localHasReachCheck) { $hasReachHitboxMath = $true }
                    if ($localHasRandomCPS -and $localHasMouseDispatch) { $hasAutoClickerMath = $true }
                    if ($localHasCrosshairTarget -and $localHasDoAttack) { $hasTriggerBotLogic = $true }
                    if ($localHasTotemItem -and $localHasSlotSwap) { $hasAutoTotemLogic = $true }
                    if ($localHasCooldownField) { $hasFastPlaceLogic = $true }
                    if ($localHasActionPackets) { $hasPacketMineLogic = $true }
                    if ($localHasOnGroundSpoof) { $hasNoFallLogic = $true }
                    if ($localHasPacketQueue) { $hasBlinkLogic = $true }
                    if ($localHasPotItem) { $hasAutoPotLogic = $true }
                    if ($localHasTrackedPos) { $hasBacktrackLogic = $true }
                    if ($localHasWebhook) { $hasWebhookExfil = $true }
                    if ($localHasUnsafeMem) { $hasMemoryScrub = $true }

                    if ($localHasDeleteCommand -and ($localHasDeleteOnExit -or $localHasShutdownHook)) {
                        [void]$selfDestructFlags.Add("Delayed self-destruct command on shutdown detected")
                    }

                    $encHits = Find-EncodedContent -PoolStrings $cpStrings
                    foreach ($eh in $encHits) { [void]$encodedHits.Add($eh) }
                    $reflectionScore += Test-ReflectionUsage -PoolStrings $cpStrings
                }

                if ($bytes.Length -gt 500) {
                    $ent = Measure-Entropy -Data $bytes
                    if ($ent -gt 7.4) { $highEntropyCount++ }
                }
            }
        }
    }

    $heuristicScore = 0
    if ($hasSilentAim) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Silent Aim / Rotations Desync") }
    if ($hasAutoCrystalMath) { $heuristicScore += 15; [void]$foundStrings.Add("Heuristic: Crystal & Anchor Damage Calculator") }
    if ($hasVelocitySpoof) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Velocity Cancellation / Knockback Spoof") }
    if ($hasScaffoldMath) { $heuristicScore += 5; [void]$foundStrings.Add("Heuristic: Auto-Raycast Scaffold Logic") }
    if ($hasNettyIntercept) { $heuristicScore += 8; [void]$foundStrings.Add("Heuristic: Custom Netty Channel Pipeline Interception") }
    if ($hasGLFWInputHook) { $heuristicScore += 5; [void]$foundStrings.Add("Heuristic: Direct GLFW / JNativeHook Input Capture") }
    if ($hasReachHitboxMath) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Reach Expansion & Extended Bounding Box Math") }
    if ($hasAutoClickerMath) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Randomized CPS Distribution & Click Dispatch") }
    if ($hasTriggerBotLogic) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Autonomous Crosshair Raycast TriggerBot") }
    if ($hasAutoTotemLogic) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Autonomous Totem Inventory Slot Swapper") }
    if ($hasFastPlaceLogic) { $heuristicScore += 8; [void]$foundStrings.Add("Heuristic: Attack & Placement Cooldown Manipulation") }
    if ($hasPacketMineLogic) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Zero-Tick Packet Mine Destroy Sequence") }
    if ($hasNoFallLogic) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Ground Status Spoofing / NoFall Logic") }
    if ($hasBlinkLogic) { $heuristicScore += 8; [void]$foundStrings.Add("Heuristic: Packet Buffering Queue / Blink Logic") }
    if ($hasAutoPotLogic) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Auto Potion Throw & Slot Restore Sequence") }
    if ($hasBacktrackLogic) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Entity History Tracking & Backtrack Buffer") }
    if ($hasWebhookExfil) { $heuristicScore += 15; [void]$foundStrings.Add("Heuristic: Remote Webhook & C2 Exfiltration Endpoint") }
    if ($hasMemoryScrub) { $heuristicScore += 12; [void]$foundStrings.Add("Heuristic: Direct JVM Native Memory Manipulation") }
    if ($hasFreeLookDecouple) { $heuristicScore += 8; [void]$foundStrings.Add("Heuristic: FreeLook / Decoupled Camera Perspective Matrix") }
    if ($hasAutoWebLogic) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Autonomous Cobweb Placement & Target Trap Logic") }
    if ($hasAutoMaceLogic) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Kinetic Fall-Damage Mace & Spear Weapon Switcher") }
    if ($hasCriticalsDesync) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Packet-Level Mini-Hop Critical Hit Generator") }
    if ($hasFastBowLogic) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Truncated Bow Charge & Rapid Arrow Spammer") }
    if ($hasSpinBotLogic) { $heuristicScore += 10; [void]$foundStrings.Add("Heuristic: Anti-Aim Pseudo-Random SpinBot Packet Generator") }
    if ($targetedCoreMixinCount -ge 4) { $heuristicScore += 12; [void]$foundStrings.Add("Heuristic: High Density Combat/Network Mixin Clustering ($targetedCoreMixinCount targets)") }

    $fwCheatPool = @($script:flaggedContent | Where-Object {
        $_ -cmatch "[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]"
    })
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
        Patterns = $foundPatterns; Macros = $foundMacros; Strings = $foundStrings; Fullwidth = $finalFullwidth
        EncodedHits = $encodedHits; HighEntropyCount = $highEntropyCount
        ReflectionScore = $reflectionScore
        SelfDestructFlags = $selfDestructFlags; HeuristicScore = $heuristicScore
    }
}

function Start-InjectionAnalysis {
    param($ArchiveData, [string]$FilePath)
    $flags = [System.Collections.Generic.List[string]]::new()

    $nestedJarNames = @()
    foreach ($e in $ArchiveData.Entries) {
        if ($e -match "^META-INF/jars/(.+\.jar)$") { $nestedJarNames += $matches[1] }
    }

    $outerClassCount = @($ArchiveData.Entries | Where-Object { $_ -match "\.class$" }).Count
    $hasFabricJiJ = $false
    foreach ($key in $ArchiveData.ClassBytes.Keys) {
        if ($key -eq "fabric.mod.json") {
            try {
                $fjson = [System.Text.Encoding]::UTF8.GetString($ArchiveData.ClassBytes[$key]).Trim([char]0xFEFF) | ConvertFrom-Json
                if ($fjson.jars -and $fjson.jars.Count -gt 0) { $hasFabricJiJ = $true }
            } catch { }
        }
    }
    if ($nestedJarNames.Count -ge 1 -and $outerClassCount -lt 2 -and -not $hasFabricJiJ) {
        [void]$flags.Add("Hollow loader shell — Wraps nested payload: $($nestedJarNames[0])")
    }

    $instrumentationFound = $false
    $memoryPatchFound = $false
    $remoteClassLoadFound = $false

    $modIdentity = $null
    foreach ($key in $ArchiveData.ClassBytes.Keys) {
        if ($key -eq "fabric.mod.json") {
            try {
                $mdata = [System.Text.Encoding]::UTF8.GetString($ArchiveData.ClassBytes[$key]).Trim([char]0xFEFF) | ConvertFrom-Json
                $modIdentity = $mdata.id
            } catch { }
        }
    }
    $isKnownSafe = $false
    if ($modIdentity) {
        foreach ($kn in $script:knownModIdentities.Keys) {
            if ($modIdentity -eq $script:knownModIdentities[$kn].id) { $isKnownSafe = $true; break }
        }
    }

    $nativeLoadFound = $false
    $namedPipeFound = $false
    $dynamicAsmFound = $false

    foreach ($key in $ArchiveData.ClassBytes.Keys) {
        if ($key -match "\.class$") {
            $ct = [System.Text.Encoding]::ASCII.GetString($ArchiveData.ClassBytes[$key])
            if ($ct -match "java/lang/instrument/Instrumentation" -and $ct -match "redefineClasses|retransformClasses") {
                $instrumentationFound = $true
            }
            if (-not $isKnownSafe -and $ct -match "sun/misc/Unsafe" -and $ct -match "putAddress|allocateMemory|freeMemory") {
                $memoryPatchFound = $true
            }
            if ($ct -match "java/net/URLClassLoader" -and $ct -match "addURL|defineClass") {
                $remoteClassLoadFound = $true
            }
            if (-not $isKnownSafe -and ($ct.Contains("System.loadLibrary") -or $ct.Contains("System.load")) -and ($ct -match "\.dll|\.so|\.dylib|kernel32|user32")) {
                $nativeLoadFound = $true
            }
            if ($ct -match "\\\\\.\\pipe\\" -or $ct.Contains("NamedPipeServerStream") -or $ct.Contains("NamedPipeClientStream")) {
                $namedPipeFound = $true
            }
            if (-not $isKnownSafe -and ($ct.Contains("org/objectweb/asm/ClassWriter") -or $ct.Contains("javassist/ClassPool")) -and $ct.Contains("defineClass")) {
                $dynamicAsmFound = $true
            }
        }
    }

    if ($instrumentationFound) { [void]$flags.Add("JVM Runtime Agent — Dynamic bytecode redefinition hook detected") }
    if ($memoryPatchFound) { [void]$flags.Add("Direct Native Memory Patching — Unsafe memory pointer manipulation detected") }
    if ($remoteClassLoadFound) { [void]$flags.Add("Remote Class Loader — Dynamic remote JAR/Class loader detected") }
    if ($nativeLoadFound) { [void]$flags.Add("Native JNI Bridge — Embedded native binary loader hook detected") }
    if ($namedPipeFound) { [void]$flags.Add("External IPC Bridge — Windows Named Pipe cross-process communication channel") }
    if ($dynamicAsmFound) { [void]$flags.Add("Dynamic Bytecode Transformer — In-memory ASM/Javassist class synthesizer") }

    return $flags
}

function Start-StructureAnalysis {
    param($ArchiveData)
    $flags = [System.Collections.Generic.List[string]]::new()

    $totalClass = 0; $numericCount = 0; $unicodeCount = 0
    $fullwidthCount = 0; $japaneseCount = 0; $singleLetterCount = 0
    $unprintableCount = 0; $cyrillicCount = 0; $shortPackageCount = 0
    $contentSample = [System.Text.StringBuilder]::new()
    $sampleSize = 0

    $cheatObfuscators = @{
        "Skidfuscator"   = @("dev/skidfuscator", "Skidfuscator", "skidfuscator.dev")
        "Paramorphism"   = @("Paramorphism", "paramorphism-", "dev/paramorphism")
        "Radon"          = @("ItzSomebody/Radon", "me/itzsomebody/radon")
        "Caesium"        = @("sim0n/Caesium", "dev/sim0n/caesium")
        "Bozar"          = @("vimasig/Bozar", "com/bozar")
        "Branchlock"     = @("Branchlock", "branchlock.dev")
        "Binscure"       = @("Binscure", "com/binscure")
        "SuperBlaubeere" = @("superblaubeere", "superblaubeere27")
        "Qprotect"       = @("Qprotect", "QProtect", "mdma.dev/qprotect")
        "Zelix"          = @("ZKMFLOW", "ZelixKlassMaster")
        "Stringer"       = @("StringerJavaObfuscator", "com/licel/stringer")
        "JNIC"           = @("JNIC", "jnic.obf", "jnic-obfuscator")
        "Smoke"          = @("SmokeObf", "smoke.obf")
        "KryptonObf"     = @("KryptonObfuscator")
        "Prometeo"       = @("PrometeoObfuscator", "prometeo")
        "Allatori"       = @("AllatoriDemo", "com/allatori")
        "DashO"          = @("PreEmptive", "com/preemptive")
        "NeonObf"        = @("NeonObfuscator", "neonobf")
        "Obzcure"        = @("Obzcure", "obzcure")
        "ClassGuard"     = @("ClassGuard", "classguard")
        "JJobf"          = @("JJobf", "JObf", "jobf")
        "Scuti"          = @("Scuti", "scuti")
        "AntiDump"       = @("AntiDump", "antidump")
        "yGuard"         = @("yworks/yguard")
        "SandMark"       = @("sandmark", "SandMark")
        "ProGuard"       = @("proguard/obfuscate", "ProGuard")
        "DexGuard"       = @("dexguard", "DexGuard")
        "RetroGuard"     = @("retroguard", "RetroGuard")
    }

    $allNames = [System.Collections.Generic.List[string]]::new()
    foreach ($e in $ArchiveData.Entries) { [void]$allNames.Add($e) }
    foreach ($e in $ArchiveData.NestedEntries) { [void]$allNames.Add($e) }

    foreach ($name in $allNames) {
        if ($name -match "\.class$") {
            $totalClass++
            $className = [System.IO.Path]::GetFileNameWithoutExtension(($name -split "/")[-1])
            $pkgName = [System.IO.Path]::GetDirectoryName($name)
            if ($className -match "^\d+$") { $numericCount++ }
            if ($className -match "[^\x00-\x7F]") { $unicodeCount++ }
            if ($className -match "[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]") { $fullwidthCount++ }
            if ($className -match "[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF]") { $japaneseCount++ }
            if ($className -match "[\u0001-\u001F\u200B-\u200F\uFEFF]") { $unprintableCount++ }
            if ($className -match "[\u0400-\u04FF]") { $cyrillicCount++ }
            if ($className -match "^[a-zA-Z]$") { $singleLetterCount++ }
            if ($pkgName -match "^[a-zA-Z]$|^[a-zA-Z]/[a-zA-Z]$") { $shortPackageCount++ }
        }
    }

    foreach ($key in $ArchiveData.ClassBytes.Keys) {
        if ($key -match "\.class$" -and $sampleSize -lt 250000) {
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

    if ($singleLetterCount -ge 2 -or $s1Pct -ge 20 -or $shortPackageCount -ge 2) {
        [void]$flags.Add("Single-letter & flattened class hierarchy ($singleLetterCount classes / $s1Pct%)")
    }
    if ($numericCount -ge 2 -or $numPct -ge 25) {
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

    if ($sampleStr -match '\(\[C\)Ljava/lang/String;|\(\[B\)Ljava/lang/String;|\(Ljava/lang/String;I\)Ljava/lang/String;|\(Ljava/lang/String;\[C\)Ljava/lang/String;') {
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
                foreach ($la in $legitAgents) { if ($agentName -match $la) { $isLegit = $true; break } }
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
                if ($cmdLine -match [regex]::Escape($sf.Flag)) {
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
    }
    Write-Host "├─────────────────────────────────────────────────────────────────────────────┤" -ForegroundColor DarkRed

    if ($Mod.Patterns.Count -gt 0) {
        Write-Host "│ CHEAT SIGNATURES IDENTIFIED:" -ForegroundColor DarkGray
        foreach ($p in ($Mod.Patterns | Sort-Object)) {
            Write-Host "│   • " -ForegroundColor DarkRed -NoNewline
            Write-Host $p -ForegroundColor Red
        }
    }

    $uniqueStrings = $Mod.Strings | Where-Object { $Mod.Patterns -notcontains $_ } | Sort-Object
    if ($uniqueStrings.Count -gt 0) {
        Write-Host "│ HEURISTICS & ADVANCED PATTERNS:" -ForegroundColor DarkGray
        foreach ($s in $uniqueStrings) {
            Write-Host "│   • " -ForegroundColor DarkRed -NoNewline
            Write-Host $s -ForegroundColor DarkYellow
        }
    }

    if ($Mod.Fullwidth -and $Mod.Fullwidth.Count -gt 0) {
        Write-Host "│ FULLWIDTH UNICODE PATTERNS:" -ForegroundColor DarkGray
        foreach ($fw in ($Mod.Fullwidth | Sort-Object)) {
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

    $uniqueStrings = $Mod.Strings | Where-Object { $Mod.Macros -notcontains $_ } | Sort-Object
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
Write-Host "Found $totalFiles JAR $fileWord to scan" -ForegroundColor Green
Write-Host

$timer = [System.Diagnostics.Stopwatch]::StartNew()
$idx = 0

Write-Host "[1/5] Checking file system & USN journal activity..." -ForegroundColor Cyan
$journalHits = Start-USNAnalysis -ModsDir $modsPath
if ($journalHits.Count -gt 0) {
    foreach ($jh in $journalHits) {
        $parts = $jh -split '\|'
        Write-Host "   ALERT: $($parts[0]) - $($parts[1])" -ForegroundColor Red
    }
} else {
    Write-Host "   File system journal is clean" -ForegroundColor DarkGray
}

$tempHits = Start-TempScan
if ($tempHits.Count -gt 0) {
    foreach ($th in $tempHits) {
        Write-Host "   TEMP WARNING: $th" -ForegroundColor DarkYellow
    }
} else {
    Write-Host "   Temp execution directory is clean" -ForegroundColor DarkGray
}
Write-Host

$cacheRoot = "$env:LOCALAPPDATA\APPTModAnalyzer\cache"
if (-not (Test-Path $cacheRoot)) { New-Item -ItemType Directory -Path $cacheRoot -Force | Out-Null }

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

function Resolve-ModrinthHash {
    param([string]$Sha1, [string]$Sha512)
    $cached = Get-CachedResult -Hash $Sha1 -Source "modrinth"
    if ($cached) { return $cached }
    try {
        $headers = @{ "User-Agent" = "APPT-ModAnalyzer/3.0" }
        $resp = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version_file/$Sha1" -Headers $headers -TimeoutSec 2 -ErrorAction SilentlyContinue
        if ($resp.project_id) {
            $data = @{ Name = $resp.project_id; Slug = $resp.project_id; Verified = $true }
            Save-CachedResult -Hash $Sha1 -Source "modrinth" -Data $data
            return $data
        }
    } catch { }
    return @{ Name = $null; Slug = $null; Verified = $false }
}

function Resolve-MegabaseHash {
    param([string]$Hash)
    $cached = Get-CachedResult -Hash $Hash -Source "megabase"
    if ($cached) { return $cached }
    try {
        $resp = Invoke-RestMethod -Uri "https://api.megabase.org/v1/hash/$Hash" -TimeoutSec 2 -ErrorAction SilentlyContinue
        if ($resp.name) {
            $data = @{ Name = $resp.name; Verified = $true }
            Save-CachedResult -Hash $Hash -Source "megabase" -Data $data
            return $data
        }
    } catch { }
    return @{ Name = $null; Verified = $false }
}

Write-Host "[2/5] Verifying mod integrity & online hashes..." -ForegroundColor Cyan

foreach ($jar in $jarFiles) {
    $idx++
    Show-AnalysisProgress -Current $idx -Total $totalFiles -FileName $jar.Name -Timer $timer

    $verifiedName = $null
    $archiveDataTemp = Read-ArchiveData -Target $jar.FullName
    $identTemp = Get-ModIdentity -ArchiveData $archiveDataTemp
    if ($identTemp.ModId) {
        foreach ($kn in $script:knownModIdentities.Keys) {
            if ($identTemp.ModId -eq $script:knownModIdentities[$kn].id) {
                $verifiedName = "$($identTemp.Name) [$($identTemp.Loader)]"
                break
            }
        }
    }

    if (-not $verifiedName) {
        $hashes = Get-FileDigest -Target $jar.FullName
        if ($hashes.SHA1) {
            $modrinthData = Resolve-ModrinthHash -Sha1 $hashes.SHA1 -Sha512 $hashes.SHA512
            if ($modrinthData.Verified) {
                $verifiedName = $modrinthData.Name
            } else {
                $megabaseData = Resolve-MegabaseHash -Hash $hashes.SHA1
                if ($megabaseData.Verified) {
                    $verifiedName = $megabaseData.Name
                }
            }
        }
    }

    if (-not $verifiedName -and $identTemp.Name) {
        $verifiedName = "$($identTemp.Name) [$($identTemp.Loader)]"
    }

    if ($verifiedName) {
        $confirmedEntries += [PSCustomObject]@{
            ModName = $verifiedName; FileName = $jar.Name
            FilePath = $jar.FullName; Verified = $true
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

foreach ($jar in $jarFiles) {
    $idx++
    Show-AnalysisProgress -Current $idx -Total $totalFiles -FileName $jar.Name -Timer $timer2

    $archiveData = Read-ArchiveData -Target $jar.FullName
    $patternResult = Start-PatternAnalysis -ArchiveData $archiveData
    $bypassFlags = Start-InjectionAnalysis -ArchiveData $archiveData -FilePath $jar.FullName
    $deepFlags = Start-DeepBytecodeScan -ArchiveData $archiveData
    foreach ($df in $deepFlags) { [void]$bypassFlags.Add($df) }
    $obfFlags = Start-StructureAnalysis -ArchiveData $archiveData
    $timestompFlags = Test-Timestomping -FilePath $jar.FullName -ArchiveData $archiveData
    $originInfo = Resolve-OriginMetadata -FilePath $jar.FullName -ArchiveData $archiveData
    $modIdentity = Get-ModIdentity -ArchiveData $archiveData
    $spoofFlags = Test-ModSpoofing -FileName $jar.Name -ModIdentity $modIdentity -ArchiveData $archiveData

    if ($originInfo.IsCheatOrigin) {
        [void]$patternResult.Strings.Add("Origin: Downloaded directly from known cheat distribution platform")
    }

    $isCheatClient = $patternResult.Patterns.Count -gt 0 -or $patternResult.Fullwidth.Count -gt 0 -or
                     $patternResult.EncodedHits.Count -gt 0 -or $patternResult.SelfDestructFlags.Count -gt 0 -or
                     $originInfo.IsCheatOrigin -or ($patternResult.HeuristicScore -ge 10)

    $isMacroMod = $patternResult.Macros.Count -gt 0 -and -not $isCheatClient

    if ($isCheatClient) {
        $flaggedEntries += [PSCustomObject]@{
            FileName = $jar.Name; Patterns = $patternResult.Patterns
            Strings = $patternResult.Strings; Fullwidth = $patternResult.Fullwidth
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
            Strings = $patternResult.Strings
            OriginInfo = $originInfo
            ModIdentity = $modIdentity
        }
        $confirmedEntries = @($confirmedEntries | Where-Object { $_.FileName -ne $jar.Name })
        $unverifiedEntries = @($unverifiedEntries | Where-Object { $_.FileName -ne $jar.Name })
    }

    if ($bypassFlags.Count -gt 0) {
        $injectedEntries += [PSCustomObject]@{ FileName = $jar.Name; Flags = $bypassFlags }
        $confirmedEntries = @($confirmedEntries | Where-Object { $_.FileName -ne $jar.Name })
        $unverifiedEntries = @($unverifiedEntries | Where-Object { $_.FileName -ne $jar.Name })
    }

    if ($obfFlags.Count -gt 0) {
        $obfEntries += [PSCustomObject]@{ FileName = $jar.Name; Flags = $obfFlags }
        $confirmedEntries = @($confirmedEntries | Where-Object { $_.FileName -ne $jar.Name })
        $unverifiedEntries = @($unverifiedEntries | Where-Object { $_.FileName -ne $jar.Name })
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

Write-Host "`r$(' ' * 120)`r" -NoNewline
Write-Host "[5/5] Generating scan summary..." -ForegroundColor Cyan

Write-Host "`r$(' ' * 120)`r" -NoNewline
$timer.Stop()
$totalTime = [math]::Round($timer.Elapsed.TotalSeconds, 1)

if (@($confirmedEntries).Count -gt 0) {
    Show-CategoryHeader -Title "VERIFIED CLEAN MODS" -Count @($confirmedEntries).Count -DotColor Green -CountColor Green
    foreach ($mod in $confirmedEntries) {
        Write-Host "  [OK] " -ForegroundColor Green -NoNewline
        Write-Host "$($mod.ModName)" -ForegroundColor White -NoNewline
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
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
