param(
    [Parameter(Mandatory = $true)]
    [string]$WowPath,

    [string]$TargetResolution = "3440x1440"
)

$ErrorActionPreference = "Stop"

$TidyPlatesRepo = "hypopheria2k/TidyPlates_3.3.5a"
$TidyPlatesCommit = "02956c68068b2c01bfdc3972345eb59a357447d7"
$TidyPlatesArchive = "https://github.com/$TidyPlatesRepo/archive/$TidyPlatesCommit.zip"

function Write-Step([string]$Message) {
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Copy-AddonFolder([System.IO.DirectoryInfo]$Source, [string]$DestinationRoot, [string]$BackupRoot) {
    $toc = Get-ChildItem -LiteralPath $Source.FullName -Filter "*.toc" -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $toc) { return }

    $destination = Join-Path $DestinationRoot $Source.Name
    if (Test-Path -LiteralPath $destination) {
        New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null
        Copy-Item -LiteralPath $destination -Destination $BackupRoot -Recurse -Force
        Remove-Item -LiteralPath $destination -Recurse -Force
    }

    Copy-Item -LiteralPath $Source.FullName -Destination $destination -Recurse -Force
    Write-Host "    Installed $($Source.Name)"
}

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
$zipPath = Join-Path $tempRoot "tidyplates.zip"
$extractDir = Join-Path $tempRoot "tidyplates"

try {
    New-Item -ItemType Directory -Force -Path $tempRoot, $extractDir | Out-Null

    Write-Step "Installing pinned TidyPlates 3.3.5a build"
    Write-Host "    Source: https://github.com/$TidyPlatesRepo"
    Write-Host "    Commit: $TidyPlatesCommit"

    Invoke-WebRequest -UseBasicParsing -Uri $TidyPlatesArchive -OutFile $zipPath
    Expand-Archive -LiteralPath $zipPath -DestinationPath $extractDir -Force

    $repoRoot = Get-ChildItem -LiteralPath $extractDir -Directory | Select-Object -First 1
    if (-not $repoRoot) {
        throw "The TidyPlates archive did not contain an extracted repository folder."
    }

    $addonFolders = Get-ChildItem -LiteralPath $repoRoot.FullName -Directory |
        Where-Object { Get-ChildItem -LiteralPath $_.FullName -Filter "*.toc" -File -ErrorAction SilentlyContinue }

    if (-not $addonFolders) {
        throw "No addon folders with .toc files were found in the TidyPlates archive."
    }

    foreach ($folder in $addonFolders) {
        Copy-AddonFolder -Source $folder -DestinationRoot $addonsDir -BackupRoot $backupDir
    }

    $marker = [ordered]@{
        installedBy = "AzerothGuild client setup"
        wowPath = $WowPath
        targetResolution = $TargetResolution
        uiPreset = "Naowh-inspired-ultrawide"
        tidyPlates = [ordered]@{
            repository = $TidyPlatesRepo
            commit = $TidyPlatesCommit
            preferredTheme = "TidyPlates_ThreatPlates"
        }
        installedAt = (Get-Date).ToString("o")
    }

    $markerPath = Join-Path $WowPath ".azerothguild-client.json"
    $marker | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $markerPath -Encoding UTF8

    Write-Host ""
    Write-Host "Client addon setup complete." -ForegroundColor Green
    Write-Host "Primary UI target: $TargetResolution"
    Write-Host "Preferred nameplate theme: TidyPlates_ThreatPlates"
    if (Test-Path -LiteralPath $backupDir) {
        Write-Host "Existing addon folders were backed up under: $backupDir"
    }
    Write-Host ""
    Write-Host "ElvUI / RestedXP / WeakAuras / BigWigs pins and the actual 3440x1440 preset will be layered into this installer as they are validated."
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
