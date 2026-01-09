# make_fw.ps1 - ESP32 Firmware Builder
# Optimized for 1.89.0.0 Toolchain + esp-hal 1.0.0-rc.3 (Workspace Build)

$ErrorActionPreference = "Stop"

# 1. Load Environment Variables
Write-Host "Setting up ESP environment..."
try {
    . "$env:USERPROFILE\export-esp.ps1"
}
catch {
    Write-Warning "Failed to load export-esp.ps1. Assuming environment is already set."
}

# 2. Extract Project Info from Cargo.toml (Manual Parsing)
$cargoToml = Get-Content "Cargo.toml" -Raw
if ($cargoToml -match 'name\s*=\s*"([^"]+)"') {
    $packageName = $matches[1]
}
else {
    Write-Error "Could not parse package name from Cargo.toml"
    exit 1
}

if ($cargoToml -match 'version\s*=\s*"([^"]+)"') {
    $rawVersion = $matches[1]
    if ($rawVersion -match '^(\d+)\.(\d+)\.(\d+)') {
        # Format: <major><minor><patch:2digits> (e.g., 0.1.2 -> 0102)
        $major = [int]$matches[1]
        $minor = [int]$matches[2]
        $patch = [int]$matches[3]
        $version = "{0}{1}{2:D2}" -f $major, $minor, $patch
    }
    else {
        $version = $rawVersion
    }
}
else {
    $version = "0000"
}

Write-Host "Building $packageName v$version ($rawVersion)..."

# 3. Clean and Build (Capture output to prevent RemoteException)
# Single-thread build (-j 1) for stability and error capturing
Write-Host "Running cargo build..."
$buildProcess = Start-Process -FilePath "cargo" -ArgumentList "build", "--release", "-j", "1" -NoNewWindow -PassThru -Wait
if ($buildProcess.ExitCode -ne 0) {
    Write-Error "Build failed with exit code $($buildProcess.ExitCode)"
    exit 1
}

# 4. Locate Artifact
# Use cargo metadata to find the exact target directory (works for both workspace and single project)
Write-Host "Locating target directory..."
try {
    $metadataJson = cargo metadata --format-version 1 --no-deps | Out-String
    $metadata = $metadataJson | ConvertFrom-Json
    $workspaceTarget = $metadata.target_directory
    Write-Host "Target Dir: $workspaceTarget"
}
catch {
    Write-Warning "Failed to query cargo metadata. Fallback to 'target'."
    $workspaceTarget = "target"
}

$elfPath = Join-Path $workspaceTarget "xtensa-esp32s3-none-elf\release\$packageName"
if (Test-Path $elfPath) {
    # Found extensionless file (common on some configs)
    Write-Verbose "Found extensionless artifact: $elfPath"
}
elseif (Test-Path "$elfPath.elf") {
    # Found .elf file
    $elfPath = "$elfPath.elf"
}

if (-not (Test-Path $elfPath)) {
    Write-Error "Could not locate compiled ELF file at: $elfPath"
    Write-Host "Attempting scan..."
    $found = Get-ChildItem -Path $workspaceTarget -Recurse -Filter $packageName | Where-Object { $_.FullName -like "*xtensa-esp32s3-none-elf\release\*" } | Select-Object -First 1
    if ($found) {
        $elfPath = $found.FullName
        Write-Host "Found at: $elfPath"
    }
    else {
        exit 1
    }
}

Write-Host "Artifact found: $elfPath"

# 5. Generate Binary
# Define output folder (same as ELF location)
$outputDir = Split-Path -Parent $elfPath
$binName = "${packageName}_v${version}.bin"
$binPath = Join-Path $outputDir $binName
$factoryBinName = "${packageName}_v${version}_factory.bin"
$factoryBinPath = Join-Path $outputDir $factoryBinName

Write-Host "Generating artifacts in: $outputDir"

# App Image (App Only - for OTA or 0x10000)
Write-Host "  - App Image: $binName"
cmd /c "espflash save-image --chip esp32s3 `"$elfPath`" `"$binPath`""

# Factory Image (Merged - for 0x0)
Write-Host "  - Factory Image: $factoryBinName"
cmd /c "espflash save-image --merge --chip esp32s3 `"$elfPath`" `"$factoryBinPath`""

if ($LASTEXITCODE -eq 0) {
    Write-Host "SUCCESS: Artifacts generated."
    Write-Host "To flash factory image: espflash write-bin 0x0 `"$factoryBinPath`" --monitor"

    # 7. Show Resource Usage (PlatformIO Style)
    Write-Host "`n[Resource Usage]"
    try {
        # Try generic 'size' (GNU Binutils) which is often in PATH for Windows/Git/MinGW
        $sizeOutput = size "$elfPath" | Select-Object -Last 1
        
        # Output format (Berkeley): text data bss dec hex filename
        $parts = $sizeOutput -split '\s+' | Where-Object { $_ -ne "" }
        if ($parts.Count -ge 3) {
            $text = [int]$parts[0]
            $data = [int]$parts[1]
            $bss = [int]$parts[2]

            # ESP32-S3-N16R8 Specs
            $maxFlash = 16777216 # 16MB
            $maxRam = 524288     # 512KB (Internal SRAM)

            # Flash = .text + .data
            $usedFlash = $text + $data
            # RAM = .data + .bss
            $usedRam = $data + $bss

            $flashPercent = ($usedFlash / $maxFlash) * 100
            $ramPercent = ($usedRam / $maxRam) * 100

            function Get-ProgressBar {
                param ($percent)
                $barLen = 20
                $filled = [math]::Round(($percent / 100) * $barLen)
                if ($filled -gt $barLen) { $filled = $barLen }
                if ($filled -lt 0) { $filled = 0 }
                $empty = $barLen - $filled
                return "[" + ("=" * $filled) + (" " * $empty) + "]"
            }

            $ramBar = Get-ProgressBar $ramPercent
            $flashBar = Get-ProgressBar $flashPercent
            
            Write-Host ("RAM:   {0} {1:N1}% (used {2} bytes from {3} bytes)" -f $ramBar, $ramPercent, $usedRam, $maxRam)
            Write-Host ("Flash: {0} {1:N1}% (used {2} bytes from {3} bytes)" -f $flashBar, $flashPercent, $usedFlash, $maxFlash)
        }
    }
    catch {
        Write-Warning "To see memory usage, ensure 'size' (GNU Binutils) is in your PATH."
    }
}
else {
    Write-Error "espflash failed."
    exit 1
}
