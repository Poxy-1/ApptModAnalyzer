# APPT Mod Analyzer

An enhanced Minecraft mod analyzer based on [MeowModAnalyzer](https://github.com/MeowTonynoh/MeowModAnalyzer) to scan and detect cheats in JAR files.

---

## Credits & Attribution

This project is built upon the foundation of [MeowModAnalyzer](https://github.com/MeowTonynoh/MeowModAnalyzer) by **[MeowTonynoh](https://github.com/MeowTonynoh)**.

---

## Overview

APPT Mod Analyzer inspects Minecraft mods (`.jar` files) in a specified directory to identify cheats, macros, obfuscated packages, and runtime injection flags while avoiding false positives on legitimate mods.

---

## How to Run

### Online One-Liner (Recommended)

Run PowerShell as Administrator and execute:

```powershell
powershell -ExecutionPolicy Bypass -Command "Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/Poxy-1/ApptModAnalyzer/refs/heads/main/ApptModAnalyzer.ps1')"
```

### Local Execution

```powershell
powershell -ExecutionPolicy Bypass -File .\ApptModAnalyzer.ps1
```

When prompted, enter the path to your mods directory, or press **Enter** to use the default Minecraft folder (`%APPDATA%\.minecraft\mods`).

---

## How It Works

The scan runs through 5 sequential phases:

### Phase 1: File System & USN Journal Analysis
- **NTFS USN Journal**: Inspects recent journal operations for file replacement, stream truncation, and deletion cycles.
- **Temp Directory Inspection**: Checks `%TEMP%` for newly dropped executable JARs, DLLs, or cleanup batch scripts.
- **Zone.Identifier (ADS)**: Reads download metadata to identify if a file originated from known cheat distribution platforms.
- **Timestamp Integrity**: Compares file write times against internal class file compilation dates to detect backdating.

### Phase 2: Mod Integrity & Database Verification
- **Local Identity Resolution**: Compares mod metadata (`fabric.mod.json`, `META-INF/mods.toml`, `mcmod.info`) against known safe mod packages.
- **Online Hash Lookup**: Verifies unconfirmed mods against the **Modrinth API** and **Megabase API** using SHA1 and SHA512 hashes.

### Phase 3: Bytecode & Signature Analysis
- **Fast Bytecode Engine**: Uses compiled native C# helpers (`FastScanner`) for constant pool parsing and Shannon entropy calculation.
- **Signature Matching**: Scans class files, manifests, and mixin configurations for over 250 cheat identifiers and hardcoded string patterns.
- **Fullwidth & Unicode Detection**: Detects fullwidth characters (e.g., `Ａｕｔｏ Ｃｒｙｓｔａｌ`) and CJK symbols used to conceal cheat labels.
- **Bytecode Heuristics**: Analyzes packet structures, movement calculations, slot actions, and mixin targets to identify automated logic:
  - Silent aim & rotation desync (`PlayerMoveC2SPacket$LookAndOnGround`)
  - Velocity cancellation & knockback reduction
  - NoFall & ground status spoofing
  - Crosshair raycast triggerbots & click dispatching
  - Autonomous totem inventory slot swappers
  - Extended reach & bounding box expansion
  - FreeLook camera matrix decoupling
  - Cobweb placement & target trapping logic
  - Kinetic fall-damage mace weapon switchers
  - Packet-level mini-hop critical hit generators
  - Truncated bow charge spamming
  - Anti-aim and spinbot packet generators
- **Smart Standard Library Handling**: Skips redundant raw bytecode extraction for large bundled runtime libraries (`kotlin/`, `kotlinx/`, `scala/`, `com/google/gson/`, `it/unimi/dsi/fastutil/`, `org/apache/commons/`), ensuring rapid scans on large library mods.

### Phase 4: JVM Runtime Environment
- **Active Process Inspection**: If `javaw.exe` or `java.exe` is running, checks command-line arguments for:
  - `-javaagent:` attachments (non-standard runtime agents)
  - `-Xbootclasspath/p:` (bootstrap classpath prepending)
  - `-agentlib:jdwp` (remote JDWP debugging interfaces)
  - `-agentpath:` (native agent libraries)

### Phase 5: Categorized Report & Dashboard
Categorizes scanned files into:
- **Verified Clean Mods**: Validated against databases or official mod namespaces.
- **Unverified Community Mods**: Standard mods not present in reference databases.
- **Hack & Ghost Clients**: Mods containing confirmed cheat signatures, origin flags, or heuristic triggers.
- **PvP Macros & Automation Mods**: Standalone macro engines, hotbar rotators, and automated clickers.
- **Runtime & Bytecode Injections**: Mods using native JNI bridges, named pipe IPC, dynamic ASM synthesizers, or memory manipulation.
- **Obfuscated Mod Packages**: Mods with single-letter class structures, control flow flattening, string decryptors, or known obfuscator signatures.

---

## Supported Loaders & Environments

- **Fabric** (`fabric.mod.json`)
- **Forge** (`META-INF/mods.toml` & `mcmod.info`)
- **NeoForge**
- **Vanilla / OptiFine / Standalone JARs**
- **Operating System**: Windows (PowerShell 5.1+)
