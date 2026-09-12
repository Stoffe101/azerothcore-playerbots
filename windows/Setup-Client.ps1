param(
    [Parameter(Mandatory = $true)]
    [string]$WowPath,

    [string]$TargetResolution = "3440x1440"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$ManifestPath = Join-Path $RepoRoot "client-pack\addons.json"

function Write-Step([string]$Message) {
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Backup-And-CopyAddon(
    [System.IO.DirectoryInfo]$Source,
    [string]$DestinationRoot,
    [string]$BackupRoot,
    [string]$DestinationName = ""
) {
    $toc = Get-ChildItem -LiteralPath $Source.FullName -Filter "*.toc" -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $toc) { throw "'$($Source.FullName)' is not an addon root (no .toc)." }

    $name = if ($DestinationName) { $DestinationName } else { $Source.Name }
    $destination = Join-Path $DestinationRoot $name
    if (Test-Path -LiteralPath $destination) {
        New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null
        $backupTarget = Join-Path $BackupRoot $name
        if (Test-Path -LiteralPath $backupTarget) { Remove-Item -LiteralPath $backupTarget -Recurse -Force }
        Copy-Item -LiteralPath $destination -Destination $backupTarget -Recurse -Force
        Remove-Item -LiteralPath $destination -Recurse -Force
    }

    Copy-Item -LiteralPath $Source.FullName -Destination $destination -Recurse -Force
    Write-Host "    Installed $name"
}

function Install-PinnedGithubAddon(
    [pscustomobject]$Addon,
    [string]$DestinationRoot,
    [string]$BackupRoot,
    [string]$WorkingRoot
) {
    if ($Addon.installMode -notin @("github-archive", "github-archive-root-addon")) {
        throw "Unsupported installMode '$($Addon.installMode)' for $($Addon.id)."
    }

    $repoUri = [Uri]$Addon.repository
    $repoSlug = $repoUri.AbsolutePath.Trim('/')
    $archive = "https://github.com/$repoSlug/archive/$($Addon.ref).zip"
    $addonWork = Join-Path $WorkingRoot $Addon.id
    $zipPath = Join-Path $addonWork "$($Addon.id).zip"
    $extractDir = Join-Path $addonWork "extract"
    New-Item -ItemType Directory -Force -Path $addonWork, $extractDir | Out-Null

    Write-Step "Installing $($Addon.name)"
    Write-Host "    Source: $($Addon.repository)"
    Write-Host "    Commit: $($Addon.ref)"

    Invoke-WebRequest -UseBasicParsing -Uri $archive -OutFile $zipPath
    Expand-Archive -LiteralPath $zipPath -DestinationPath $extractDir -Force

    $extractedRepo = Get-ChildItem -LiteralPath $extractDir -Directory | Select-Object -First 1
    if (-not $extractedRepo) { throw "$($Addon.name) archive did not contain a repository directory." }

    if ($Addon.installMode -eq "github-archive-root-addon") {
        $rootToc = Get-ChildItem -LiteralPath $extractedRepo.FullName -Filter "*.toc" -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $rootToc) { throw "$($Addon.name) was expected to be a root addon, but no root .toc was found." }
        Backup-And-CopyAddon -Source $extractedRepo -DestinationRoot $DestinationRoot -BackupRoot $BackupRoot -DestinationName $Addon.rootAddonName
        return
    }

    $folders = Get-ChildItem -LiteralPath $extractedRepo.FullName -Directory | Where-Object {
        Get-ChildItem -LiteralPath $_.FullName -Filter "*.toc" -File -ErrorAction SilentlyContinue
    }

    if (-not $folders) { throw "No top-level addon folders with .toc files were found for $($Addon.name)." }
    foreach ($folder in $folders) {
        Backup-And-CopyAddon -Source $folder -DestinationRoot $DestinationRoot -BackupRoot $BackupRoot
    }
}

if (-not (Test-Path -LiteralPath $ManifestPath)) {
    throw "Client manifest not found: $ManifestPath"
}
$manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json

$resolved = Resolve-Path -LiteralPath $WowPath -ErrorAction Stop
$WowPath = $resolved.Path
$wowExe = Join-Path $WowPath "Wow.exe"
if (-not (Test-Path -LiteralPath $wowExe)) {
    throw "Wow.exe was not found in '$WowPath'. Point -WowPath at the root of a legitimate WoW 3.3.5a client."
}

$addonsDir = Join-Path $WowPath "Interface\AddOns"
New-Item -ItemType Directory -Force -Path $addonsDir | Out-Null

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = Join-Path $WowPath "_AzerothGuildBackup\$timestamp\AddOns"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("AzerothGuild-Client-" + [guid]::NewGuid().ToString("N"))

try {
    New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null

    Write-Host "AzerothGuild client setup" -ForegroundColor Green
    Write-Host "WoW: $WowPath"
    Write-Host "Target UI: $TargetResolution"
    Write-Host ""

    foreach ($addon in $manifest.addons) {
        Install-PinnedGithubAddon -Addon $addon -DestinationRoot $addonsDir -BackupRoot $backupDir -WorkingRoot $tempRoot
    }

    $markerAddons = @()
    foreach ($addon in $manifest.addons) {
        $markerAddons += [ordered]@{
            id = $addon.id
            repository = $addon.repository
            ref = $addon.ref
        }
    }

    $marker = [ordered]@{
        installedBy = "AzerothGuild client setup"
        wowPath = $WowPath
        wowVersion = $manifest.client.wowVersion
        wowBuild = $manifest.client.build
        targetResolution = $TargetResolution
        uiPreset = $manifest.client.preset
        addons = $markerAddons
        preferredNameplates = "TidyPlates_ThreatPlates"
        installedAt = (Get-Date).ToString("o")
    }

    $markerPath = Join-Path $WowPath ".azerothguild-client.json"
    $marker | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $markerPath -Encoding UTF8

    Write-Host ""
    Write-Host "Client addon setup complete." -ForegroundColor Green
    Write-Host "Installed pinned ElvUI, TidyPlates/ThreatPlates, RestedXP, WeakAuras and BigWigs builds."
    Write-Host "Primary UI target: $TargetResolution"
    if (Test-Path -LiteralPath $backupDir) {
        Write-Host "Previous addon folders were backed up under: $backupDir"
    }
    Write-Host ""
    Write-Host "NOTE: the 3440x1440 Naowh-inspired SavedVariables profile is intentionally applied only after in-client validation. The installer already pins and installs the complete addon stack."
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
