# PowerShell verification script for Windows
# Usage:
#   ./scripts/verify.ps1
#   ./scripts/verify.ps1 --latest

param(
    [string]$Target = "",
    [switch]$Latest
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$KnownGood = Join-Path $Root "tests\known-good.json"
$ProtoCache = Join-Path $env:TEMP "proto-verify-cache"
$ProtoBin = Join-Path $ProtoCache "bin\proto.exe"

function Write-Log($msg) {
    Write-Host $msg -ForegroundColor Gray
}

function Write-Pass($msg) {
    Write-Host "PASS $msg" -ForegroundColor Green
}

function Write-Fail($msg) {
    Write-Host "FAIL $msg" -ForegroundColor Red
}

function Install-Proto {
    if (Test-Path $ProtoBin) { return }

    Write-Log "Installing proto into $ProtoCache ..."
    $installer = Join-Path $env:TEMP "proto-install.ps1"
    Invoke-WebRequest -Uri "https://moonrepo.dev/install/proto.ps1" -OutFile $installer
    # proto.ps1 reads PROTO_HOME for the install location; it does NOT accept --dir.
    # Any unrecognised positional arg is treated as the version string -> 404.
    $env:PROTO_HOME = $ProtoCache
    & $installer --yes | Out-Null

    if (-not (Test-Path $ProtoBin)) {
        throw "Failed to install proto"
    }
    & $ProtoBin --version
}

function Get-Version($plugin, $useLatest) {
    if ($useLatest) { return "latest" }

    if (Test-Path $KnownGood) {
        $json = Get-Content $KnownGood | ConvertFrom-Json
        if ($json.PSObject.Properties.Name -contains $plugin) {
            return $json.$plugin
        }
    }
    return "latest"
}

function Verify-One($plugin, $useLatest) {
    $toml = Join-Path $Root "plugins\$plugin.toml"
    if (-not (Test-Path $toml)) {
        Write-Fail "$plugin : no such plugin file"
        return $false
    }

    $ver = Get-Version $plugin $useLatest

    $runDir = Join-Path $env:TEMP "proto-verify-run-$PID\$plugin"
    if (Test-Path $runDir) { Remove-Item $runDir -Recurse -Force }
    New-Item -ItemType Directory -Path $runDir | Out-Null
    Set-Location $runDir

    # proto on Windows rejects file:///D:/... URIs (plugin::loader::file::missing).
    # Copy the plugin TOML beside .prototools and reference it with a plain
    # relative file:// URL.
    Copy-Item $toml (Join-Path $runDir "$plugin.toml")
    $tomlUri = "file://./$plugin.toml"

    $config = @"
$plugin = "$ver"

[plugins]
$plugin = "$tomlUri"
"@
    $config | Out-File ".prototools" -Encoding utf8

    $phome = Join-Path $runDir "proto-home"
    New-Item -ItemType Directory -Path $phome | Out-Null
    $env:PROTO_HOME = $phome

    & $ProtoBin plugin add $plugin $tomlUri -c local --yes | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "$plugin@$ver : plugin add failed"
        return $false
    }

    Write-Host "  Attempting proto install for $plugin@$ver on Windows" -ForegroundColor DarkGray
    & $ProtoBin install -c local -y $plugin
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "$plugin@$ver : install failed"
        return $false
    }

    # Collect candidates: prefer the real binary under tools\<plugin>\<ver>\,
    # fall back to the shim. Some plugins ship a binary whose name differs
    # from the plugin id (aliyun-cli -> aliyun, tektoncd-cli -> tkn, etc.).
    $candidates = @()
    $toolsDir = Join-Path $phome "tools\$plugin"
    if (Test-Path $toolsDir) {
        Get-ChildItem $toolsDir -Recurse -File | ForEach-Object {
            $name = $_.Name
            # Skip non-binary artifacts and macOS metadata (`._foo`).
            if ($name -like '._*') { return }
            if ($name -match '^(checksums|CHECKSUM|LICENSE|README|\.last-used)' -or
                $name -match '\.(md|txt|json|toml|sha256|sig|asc)$') { return }
            # Only files that look executable on Windows.
            if ($name -notmatch '\.(exe|cmd|bat|com|ps1)$') { return }
            $candidates += $_.FullName
        }
    }
    $shim    = Join-Path $phome "shims\$plugin.exe"
    if (Test-Path $shim) { $candidates += $shim }
    $shim2   = Join-Path $phome "shims\$plugin"
    if (Test-Path $shim2) { $candidates += $shim2 }

    if ($candidates.Count -eq 0) {
        Write-Fail "$plugin@$ver : binary not found after install"
        return $false
    }

    # Try each candidate. PASS requires exit code 0 from one of
    # --version / version / --help (`unknown flag` etc. should NOT pass).
    foreach ($bin in $candidates) {
        foreach ($flagSet in @(@('--version'), @('version'), @('--help'))) {
            $out = $null
            try {
                $global:LASTEXITCODE = 0
                $out = & $bin @flagSet 2>&1 | Select-Object -First 1
            } catch {
                continue
            }
            if ($LASTEXITCODE -eq 0) {
                $label = if ($out) { "$out" } else { "runs" }
                Write-Pass "$plugin@$ver : $label  ($bin)"
                return $true
            }
        }
    }

    Write-Fail "$plugin@$ver : smoke test failed (no candidate ran successfully)"
    return $false
}

# Main
Install-Proto

$useLatest = $Latest.IsPresent
$failures = 0
$total = 0

if ($Target) {
    $total = 1
    if (-not (Verify-One $Target $useLatest)) { $failures = 1 }
} else {
    $plugins = Get-ChildItem "$Root\plugins\*.toml" | ForEach-Object { $_.BaseName } | Sort-Object
    foreach ($p in $plugins) {
        $total++
        if (-not (Verify-One $p $useLatest)) { $failures++ }
    }
}

Write-Host ""
if ($failures -eq 0) {
    Write-Host "All $total plugins verified successfully." -ForegroundColor Green
    exit 0
} else {
    Write-Host "$failures / $total plugins failed." -ForegroundColor Red
    exit 1
}