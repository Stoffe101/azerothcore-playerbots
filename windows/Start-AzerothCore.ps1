<#
.SYNOPSIS  Start/resume the AzerothCore server (WSL2 + Docker Desktop). No admin needed.
.PARAMETER WslPath  Repo path inside WSL. Default: ~/AzerothCore
.PARAMETER Distro   WSL distro name. Auto-selects the single non-Docker distro when omitted.
#>
# Keep this file ASCII-only for Windows PowerShell 5.1.
[CmdletBinding()]
param([string]$WslPath = '~/AzerothCore', [string]$Distro)

. "$PSScriptRoot\_common.ps1"

$abs = Resolve-RepoPath -RepoPath $WslPath -Distro $Distro
if (-not $abs -or -not (Test-RepoHasSetup -AbsRepoPath $abs -Distro $Distro)) {
    throw "Repo not found at '$WslPath' in WSL. Run Setup-AzerothCore.ps1 first."
}

Start-DockerDesktopIfNeeded -Distro $Distro
Invoke-WslScript -RepoPath $abs -ScriptName 'start.sh' -Distro $Distro
Write-Host "Started. Watch the worldserver logs from Ubuntu with:" -ForegroundColor Cyan
Write-Host "  cd ~/AzerothCore/azerothcore-wotlk && docker compose logs -f ac-worldserver" -ForegroundColor Yellow
