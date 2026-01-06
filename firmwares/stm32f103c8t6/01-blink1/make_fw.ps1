$ErrorActionPreference = "Continue"

# 1. Read Cargo.toml
$cargoToml = Get-Content -Path "Cargo.toml" -Raw

# 2. Extract Name and Version (Simple Regex)
if ($cargoToml -match 'name\s*=\s*"([^"]+)"') {
    $packageName = $matches[1]
}
else {
    Write-Error "Could not find package name in Cargo.toml"
}

if ($cargoToml -match 'version\s*=\s*"(\d+)\.(\d+)\.(\d+)"') {
    $major = $matches[1]
    $minor = $matches[2]
    $patch = $matches[3]
}
else {
    Write-Error "Could not find version in Cargo.toml"
}

# 3. Format Output Name
# Format: f103-{name}_v{major}{minor}{patch:02}.bin
# Example: blink1, 0.1.2 -> f103-blink1_v0102.bin
$patchFormatted = "{0:D2}" -f [int]$patch
$outputName = "f103-${packageName}_v${major}${minor}${patchFormatted}.bin"

Write-Output "Target Firmware Name: $outputName"

# 4. Build Release
Write-Output "Building firmware..."
cargo build --release --package $packageName 2>&1 | ForEach-Object { "$_" } | Write-Output
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# 5. Define Paths
# specific to this project structure
$targetDir = "target/thumbv7m-none-eabi/release" 
# Depending on workspace, target might be higher up.
# We can try to detect or just assume standard relative path if run from project root.
# If workspace is used, it might be in ../../../target/...
# Let's check if target dir exists locally, if not check upper dirs.
if (-not (Test-Path "target")) {
    # Check if we are in a workspace member and target is in root
    if (Test-Path "../../target") { $targetDir = "../../target/thumbv7m-none-eabi/release" }
    elseif (Test-Path "../../../target") { $targetDir = "../../../target/thumbv7m-none-eabi/release" }
}

$elfPath = "$targetDir/$packageName"
$binPath = "$targetDir/$outputName"

if (-not (Test-Path $elfPath)) {
    # Try with .exe extension for windows host tools acting weird? No, ELF outputs don't have .exe usually for cross compile.
    # But let's check.
    Write-Error "Could not find compiled ELF file at $elfPath"
}

# 6. Convert to BIN
Write-Output "Converting to binary..."
arm-none-eabi-objcopy -O binary "$elfPath" "$binPath" 2>&1 | ForEach-Object { "$_" } | Write-Output



if ($LASTEXITCODE -eq 0) {
    Write-Output "SUCCESS: Firmware created at $binPath"
    
    # 7. Show Resource Usage (PlatformIO Style)
    Write-Output "`n[Resource Usage]"
    try {
        $sizeOutput = arm-none-eabi-size "$elfPath" | Select-Object -Last 1
        # Output format: text data bss dec hex filename
        $parts = $sizeOutput -split '\s+' | Where-Object { $_ -ne "" }
        if ($parts.Count -ge 3) {
            $text = [int]$parts[0]
            $data = [int]$parts[1]
            $bss = [int]$parts[2]

            # STM32F103C8T6 Specs
            $maxFlash = 65536 # 64KB
            $maxRam = 20480 # 20KB

            $usedFlash = $text + $data
            $usedRam = $data + $bss

            $flashPercent = ($usedFlash / $maxFlash) * 100
            $ramPercent = ($usedRam / $maxRam) * 100

            function Get-ProgressBar {
                param ($percent)
                $barLen = 20
                $filled = [math]::Round(($percent / 100) * $barLen)
                $empty = $barLen - $filled
                return "[" + ("=" * $filled) + (" " * $empty) + "]"
            }

            $ramBar = Get-ProgressBar $ramPercent
            $flashBar = Get-ProgressBar $flashPercent

            Write-Output ("RAM:   {0} {1:N1}% (used {2} bytes from {3} bytes)" -f $ramBar, $ramPercent, $usedRam, $maxRam)
            Write-Output ("Flash: {0} {1:N1}% (used {2} bytes from {3} bytes)" -f $flashBar, $flashPercent, $usedFlash, $maxFlash)
        }
    }
    catch {
        Write-Warning "To see memory usage, ensure 'arm-none-eabi-size' is in your PATH."
    }
}
else {
    Write-Error "Failed to create binary file."
}
