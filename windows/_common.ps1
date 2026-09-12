# windows/_common.ps1
# Shared helpers for the AzerothCore Windows (WSL2 + Docker Desktop) scripts.
# Dot-sourced by Setup/Start/Stop/Update - not meant to be run directly.
# Keep this file ASCII-only: Windows PowerShell 5.1 treats UTF-8 without a BOM as ANSI.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Ask wsl.exe for UTF-8 output. Some older combinations still emit NULs; Get-WslPrefix strips them.
$env:WSL_UTF8 = '1'

# wsl.exe tries to translate the current Windows working directory into a Linux path.
# A PowerShell cwd under \\wsl$ or \\wsl.localhost can break otherwise-valid WSL commands.
# The scripts use $PSScriptRoot for their own files, so moving the cwd to C:\ is safe.
$currentPath = (Get-Location).Path
if ($currentPath -like '\\wsl$\*' -or $currentPath -like '\\wsl.localhost\*') {
    Set-Location -LiteralPath ($env:SystemDrive + '\')
}

function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    return ([Security.Principal.WindowsPrincipal]$id).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-Admin {
    if (-not (Test-IsAdmin)) {
        throw "Run this from an ELEVATED PowerShell (right-click -> 'Run as administrator'). Firewall changes need admin rights."
    }
}

# Return the wsl.exe prefix for the requested user distro. If -Distro is omitted, auto-select
# the single non-Docker distro. Docker Desktop can make docker-desktop the WSL default, but that
# internal distro is not a normal Linux userspace for running this server.
function Get-WslPrefix {
    param([string]$Distro)

    if ($Distro) { return @('-d', $Distro) }

    $userDistros = @()
    $rawDistros = @(& wsl.exe -l -q 2>$null)
    if ($LASTEXITCODE -ne 0) {
        throw "Could not list WSL distributions. Run 'wsl -l -v' and verify WSL is healthy."
    }

    foreach ($line in $rawDistros) {
        # Windows PowerShell 5.1 can surface WSL list output with embedded NUL characters.
        # Regex replacement avoids String.Replace(char, char), which cannot accept an empty char.
        $name = ([regex]::Replace(([string]$line), '\x00', '')).Trim()
        if ($name -and $name -notlike 'docker-desktop*') {
            $userDistros += $name
        }
    }

    if ($userDistros.Count -eq 1) {
        return @('-d', $userDistros[0])
    }

    if ($userDistros.Count -gt 1) {
        throw "Multiple WSL user distros were found ($($userDistros -join ', ')). Re-run with -Distro <name>."
    }

    throw "No normal WSL user distro was found. Install Ubuntu (or pass -Distro <name>) before running this script."
}

# Resolve a WSL repo path without shell quoting. ~/... is expanded using HOME from /usr/bin/env.
function Resolve-RepoPath {
    param([Parameter(Mandatory)][string]$RepoPath, [string]$Distro)

    $prefix = @(Get-WslPrefix $Distro)
    $envLines = @(& wsl.exe @prefix '-e' '/usr/bin/env')
    if ($LASTEXITCODE -ne 0) { return $null }

    $home = $null
    foreach ($line in $envLines) {
        $s = [string]$line
        if ($s.StartsWith('HOME=')) {
            $home = $s.Substring(5).Trim()
            break
        }
    }
    if ([string]::IsNullOrWhiteSpace($home)) { return $null }

    if ($RepoPath -eq '~') {
        $abs = $home
    } elseif ($RepoPath.StartsWith('~/')) {
        $abs = $home.TrimEnd('/') + '/' + $RepoPath.Substring(2)
    } elseif ($RepoPath.StartsWith('/')) {
        $abs = $RepoPath
    } else {
        $abs = $home.TrimEnd('/') + '/' + $RepoPath
    }

    & wsl.exe @prefix '-e' '/usr/bin/test' '-d' $abs *> $null
    if ($LASTEXITCODE -ne 0) { return $null }
    return $abs
}

# True if $AbsRepoPath/setup.sh exists in WSL.
function Test-RepoHasSetup {
    param([Parameter(Mandatory)][string]$AbsRepoPath, [string]$Distro)
    $prefix = @(Get-WslPrefix $Distro)
    & wsl.exe @prefix '-e' '/usr/bin/test' '-f' ($AbsRepoPath.TrimEnd('/') + '/setup.sh') *> $null
    return ($LASTEXITCODE -eq 0)
}

# True if docker compose works from WSL (Docker Desktop running + WSL integration on).
function Test-DockerReady {
    param([string]$Distro)
    $prefix = @(Get-WslPrefix $Distro)
    & wsl.exe @prefix '-e' '/usr/bin/docker' 'compose' 'version' *> $null
    return ($LASTEXITCODE -eq 0)
}

# Ensure Docker Desktop is running and reachable from WSL; launch it and wait (up to 3 min) if not.
function Start-DockerDesktopIfNeeded {
    param([string]$Distro)
    if (Test-DockerReady -Distro $Distro) { return }
    Write-Host "Starting Docker Desktop..." -ForegroundColor Cyan
    $dd = Join-Path $env:ProgramFiles 'Docker\Docker\Docker Desktop.exe'
    if (Test-Path $dd) { Start-Process $dd }
    else { Write-Warning "Docker Desktop.exe not found at '$dd' - start Docker Desktop manually." }
    $deadline = (Get-Date).AddMinutes(3)
    while (-not (Test-DockerReady -Distro $Distro)) {
        if ((Get-Date) -gt $deadline) { throw "Docker Desktop did not become ready within 3 minutes." }
        Start-Sleep -Seconds 5
    }
}

# Run one repo-root Bash script directly by absolute path. This deliberately avoids bash -lc
# command strings, so Windows PowerShell 5.1 cannot mangle nested shell quoting.
function Invoke-WslScript {
    param(
        [Parameter(Mandatory)][string]$RepoPath,
        [Parameter(Mandatory)][string]$ScriptName,
        [string[]]$ScriptArgs = @(),
        [string]$Distro
    )

    if ($ScriptName -notmatch '^[A-Za-z0-9._-]+$') {
        throw "Unsupported script name '$ScriptName'."
    }

    $prefix = @(Get-WslPrefix $Distro)
    $scriptPath = $RepoPath.TrimEnd('/') + '/' + $ScriptName
    & wsl.exe @prefix '-e' '/bin/bash' $scriptPath @ScriptArgs
    if ($LASTEXITCODE -ne 0) {
        throw "WSL script '$ScriptName' failed (exit $LASTEXITCODE)."
    }
}
