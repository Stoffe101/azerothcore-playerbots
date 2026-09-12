<#
.SYNOPSIS
  Install/configure the AzerothCore LAN server on Windows via WSL2 + Docker Desktop.
.DESCRIPTION
  Run from an ELEVATED PowerShell. Configures the Windows-side bits (firewall, host LAN IP)
  and runs the repo's ./setup.sh inside WSL. The containers/compose are unchanged.
.PARAMETER WslPath
  Path to the cloned repo inside WSL. Default: ~/AzerothCore
.PARAMETER Distro
  WSL distro name. If omitted, the helper auto-selects the single non-Docker user distro.
.PARAMETER LanIp
  Override the auto-detected Windows host LAN IPv4.
.EXAMPLE
  .\Setup-AzerothCore.ps1
.EXAMPLE
  .\Setup-AzerothCore.ps1 -Distro Ubuntu -WslPath ~/AzerothCore -LanIp 192.168.1.50
#>
# Keep this file ASCII-only: Windows PowerShell 5.1 treats UTF-8 without a BOM as ANSI.
[CmdletBinding()]
param(
    [string]$WslPath = '~/AzerothCore',
    [string]$Distro,
    [string]$LanIp
)

. "$PSScriptRoot\_common.ps1"

Write-Host "== AzerothCore Windows (WSL2 + Docker Desktop) installer ==" -ForegroundColor Cyan
Assert-Admin

# --- Preflight: WSL present ---
if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
    throw "WSL is not installed. Run 'wsl --install' (then reboot) and install a distro like Ubuntu."
}

# --- Preflight: repo present in WSL ---
$abs = Resolve-RepoPath -RepoPath $WslPath -Distro $Distro
if (-not $abs -or -not (Test-RepoHasSetup -AbsRepoPath $abs -Distro $Distro)) {
    throw @"
Repo not found at '$WslPath' inside WSL.
Open a WSL terminal and clone it into your WSL home first, e.g.:
  git clone <REPO_URL> ~/AzerothCore
Then re-run this script (or pass -WslPath <path> and -Distro <name>).
"@
}
Write-Host "Repo: $abs" -ForegroundColor Green
if ($abs -like '/mnt/*') {
    Write-Warning "Repo is on the Windows filesystem ($abs). For speed and correct Docker bind-mount permissions, clone it into the WSL native filesystem (e.g. ~/AzerothCore) instead."
}

# Resolve the distro once for all direct WSL calls below.
$wslPrefix = @(Get-WslPrefix $Distro)

# --- Preflight: Docker reachable from WSL ---
if (-not (Test-DockerReady -Distro $Distro)) {
    throw @"
Docker is not reachable from WSL. Make sure:
  1. Docker Desktop is running.
  2. Settings -> Resources -> WSL Integration is ON for your distro.
Then re-run this script.
"@
}
Write-Host "Docker Desktop: reachable from WSL." -ForegroundColor Green

# --- Detect the Windows host LAN IPv4 (default-route adapter; skip virtual/WSL/APIPA) ---
if (-not $LanIp) {
    # Pick the IPv4 of the real LAN adapter that owns the default route. Exclude WSL/Hyper-V/
    # virtual adapters because their NAT IPs are not what LAN clients should use.
    $route = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object {
            $a = Get-NetAdapter -InterfaceIndex $_.ifIndex -ErrorAction SilentlyContinue
            $a -and $a.Status -eq 'Up' -and $a.InterfaceDescription -notmatch 'Hyper-V|WSL|Virtual|Loopback'
        } |
        Sort-Object RouteMetric |
        Select-Object -First 1
    if ($route) {
        $ip = Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $route.ifIndex -ErrorAction SilentlyContinue |
            Where-Object { $_.IPAddress -notlike '169.254.*' } |
            Select-Object -First 1
        if ($ip) { $LanIp = $ip.IPAddress }
    }
}
if (-not $LanIp) {
    throw "Could not auto-detect the Windows host LAN IP. Re-run with -LanIp <your.host.ip> (see 'ipconfig')."
}
Write-Host "Windows host LAN IP: $LanIp" -ForegroundColor Green

# --- Read auth/world ports from .env with direct cat, then parse in PowerShell ---
# Avoid awk/bash command strings here. Windows PowerShell 5.1 can mangle nested shell quotes.
$envPath = $abs.TrimEnd('/') + '/.env'
$envExamplePath = $abs.TrimEnd('/') + '/.env.example'
& wsl.exe @wslPrefix '-e' '/usr/bin/test' '-f' $envPath *> $null
if ($LASTEXITCODE -eq 0) {
    $portSource = $envPath
} else {
    $portSource = $envExamplePath
}

$envLines = @(& wsl.exe @wslPrefix '-e' '/bin/cat' $portSource)
if ($LASTEXITCODE -ne 0) {
    throw "Failed to read '$portSource'."
}

$authPort = '3724'
$worldPort = '8085'
foreach ($line in $envLines) {
    $s = [string]$line
    if ($s -match '^DOCKER_AUTH_EXTERNAL_PORT=([0-9]+)') { $authPort = $Matches[1] }
    elseif ($s -match '^DOCKER_WORLD_EXTERNAL_PORT=([0-9]+)') { $worldPort = $Matches[1] }
}
Write-Host "Ports: auth=$authPort world=$worldPort" -ForegroundColor Green

# --- Idempotent Windows Firewall inbound rules ---
foreach ($r in @(
    @{ Name = 'AzerothCore Auth';  Port = $authPort },
    @{ Name = 'AzerothCore World'; Port = $worldPort }
)) {
    Get-NetFirewallRule -DisplayName $r.Name -ErrorAction SilentlyContinue |
        Remove-NetFirewallRule -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName $r.Name -Group 'AzerothCore' -Direction Inbound `
        -Action Allow -Protocol TCP -LocalPort $r.Port -Profile Any | Out-Null
    Write-Host "Firewall: allowed inbound TCP $($r.Port) ($($r.Name))." -ForegroundColor Green
}

# --- Persist LAN_IP into the WSL-side env using direct Linux tools ---
# Repo-root .env is the source of truth. Create it from the template if needed.
& wsl.exe @wslPrefix '-e' '/usr/bin/test' '-f' $envPath *> $null
if ($LASTEXITCODE -ne 0) {
    & wsl.exe @wslPrefix '-e' '/bin/cp' $envExamplePath $envPath
    if ($LASTEXITCODE -ne 0) { throw "Failed to create '$envPath' from .env.example." }
}

& wsl.exe @wslPrefix '-e' '/usr/bin/grep' '-q' '^LAN_IP=' $envPath
$grepExit = $LASTEXITCODE
if ($grepExit -eq 0) {
    $sedExpr = "s|^LAN_IP=.*$|LAN_IP=$LanIp|"
    & wsl.exe @wslPrefix '-e' '/usr/bin/sed' '-i' $sedExpr $envPath
    if ($LASTEXITCODE -ne 0) { throw "Failed to write LAN_IP to '$envPath'." }
} elseif ($grepExit -eq 1) {
    throw "'$envPath' has no LAN_IP= entry. Restore it from .env.example before continuing."
} else {
    throw "Failed to inspect LAN_IP in '$envPath'."
}
Write-Host "Set LAN_IP=$LanIp in .env" -ForegroundColor Green

# --- Run the install inside WSL ---
Write-Host "Running ./setup.sh inside WSL (first run can take a long time)..." -ForegroundColor Cyan
Invoke-WslScript -RepoPath $abs -ScriptName 'setup.sh' -Distro $Distro

Write-Host ""
Write-Host "Done. On each player's PC, set realmlist to:" -ForegroundColor Cyan
Write-Host "    set realmlist $LanIp" -ForegroundColor Yellow
Write-Host "Daily ops:  .\Start-AzerothCore.ps1   /   .\Stop-AzerothCore.ps1" -ForegroundColor Cyan
