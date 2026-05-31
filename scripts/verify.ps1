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
    & $installer --yes --dir $ProtoCache | Out-Null

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

    $config = @"
$plugin = "$ver"

[plugins]
$plugin = "file://$toml"
"@
    $config | Out-File ".prototools" -Encoding utf8

    $phome = Join-Path $runDir "proto-home"
    New-Item -ItemType Directory -Path $phome | Out-Null
    $env:PROTO_HOME = $phome

    & $ProtoBin plugin add $plugin "file://$toml" -c local --yes | Out-Null
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

    # Find the binary
    $bin = Get-ChildItem -Path $phome -Recurse -Filter "$plugin.exe" | Select-Object -First 1 -ExpandProperty FullName
    if (-not $bin) {
        $bin = Get-ChildItem -Path $phome -Recurse -Filter "$plugin" | Select-Object -First 1 -ExpandProperty FullName
    }
    if (-not $bin) {
        Write-Fail "$plugin@$ver : binary not found after install"
        return $false
    }

    # Smoke test
    $out = & $bin --version 2>&1 | Select-Object -First 1
    if ($out) {
        Write-Pass "$plugin@$ver : $out  ($bin)"
        return $true
    }

    $out = & $bin --help 2>&1 | Select-Object -First 1
    if ($out) {
        Write-Pass "$plugin@$ver : runs (help)  ($bin)"
        return $true
    }

    Write-Fail "$plugin@$ver : smoke test failed"
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