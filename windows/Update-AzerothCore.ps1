<#
.SYNOPSIS  Update AzerothCore (pull latest fork + modules and rebuild) on Windows via WSL2 +
           Docker Desktop. No admin needed. Your config and database volume are preserved.
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
Write-Host "Updating (pull latest + rebuild; this can take a while)..." -ForegroundColor Cyan
Invoke-WslScript -RepoPath $abs -ScriptName 'update.sh' -Distro $Distro
