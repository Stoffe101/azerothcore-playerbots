[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PackZip,

    # Keep the project's usual private-client path as a convenience, but do not hard-lock the
    # installer to one drive/folder. Any explicitly supplied client is accepted only after the
    # same 3.3.5a safety checks pass.
    [string]$WowPath = "D:\wow private server\TheraWoW wotlk",

    # Some private 3.3.5a executables have stripped Windows version metadata. This switch is only
    # for an explicitly selected private-server client. It never enables client auto-discovery.
    [switch]$AllowUnknownClientVersion
)

$ErrorActionPreference = "Stop"
$LegacyDefaultWowRoot = "D:\wow private server\TheraWoW wotlk"
$RetiredClientAddons = @("Mapster")

function Write-Step([string]$Message) {
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Canonical([string]$Path) {
    return ([IO.Path]::GetFullPath($Path)).TrimEnd('\')
}

function Assert-ChildPath([string]$Parent, [string]$Child, [string]$Label) {
    $parentPath = (Canonical $Parent) + '\'
    $childPath = Canonical $Child
    if (-not $childPath.StartsWith($parentPath, [StringComparison]::OrdinalIgnoreCase)) {
        throw "$Label escaped the selected WoW client root: '$childPath'."
    }
}

function Assert-WowTarget([string]$Requested) {
    if ([string]::IsNullOrWhiteSpace($Requested)) {
        throw "A WoW 3.3.5a client path is required. No client auto-discovery is performed."
    }

    $actual = Canonical $Requested
    if (-not (Test-Path -LiteralPath $actual -PathType Container)) {
        throw "Selected WoW client folder does not exist: '$actual'."
    }

    $exe = Join-Path $actual "Wow.exe"
    $data = Join-Path $actual "Data"
    if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) {
        throw "Wow.exe was not found in the selected client: '$actual'."
    }
    if (-not (Test-Path -LiteralPath $data -PathType Container)) {
        throw "Data folder was not found in the selected client: '$actual'."
    }

    # Reject a recognizable non-3.3.5 executable. Retail/Classic installations are never searched
    # for and an arbitrary target cannot silently pass this check.
    $info = (Get-Item -LiteralPath $exe).VersionInfo
    $versionText = "$($info.FileVersion) $($info.ProductVersion)".Trim()
    if ($versionText -match '3\.3\.5' -or $versionText -match '12340') {
        Write-Host "    Client version: $versionText"
    } else {
        $isLegacyDefault = $actual -ieq (Canonical $LegacyDefaultWowRoot)
        if (-not $AllowUnknownClientVersion -and -not $isLegacyDefault) {
            throw @"
The selected Wow.exe did not identify itself as WoW 3.3.5a / build 12340:
  $actual
  Version metadata: '$versionText'
No files were changed. If this is a private 3.3.5a client with stripped metadata, re-run with
-AllowUnknownClientVersion and the explicit -WowPath. Retail/Classic clients must not use that switch.
"@
        }
        Write-Host "    WARNING: Wow.exe metadata did not expose 3.3.5/12340: '$versionText'" -ForegroundColor Yellow
        Write-Host "    Continuing because this is the known project client or -AllowUnknownClientVersion was explicitly supplied." -ForegroundColor Yellow
    }

    return $actual
}

function Assert-WowClosed([string]$Root) {
    foreach ($p in @(Get-Process Wow -ErrorAction SilentlyContinue)) {
        try {
            $exe = $p.MainModule.FileName
            if ($exe) {
                $runningRoot = Canonical (Split-Path -Parent $exe)
                if ($runningRoot -ieq (Canonical $Root)) {
                    throw "WoW is currently running from '$Root'. Close it completely before installing addons/data patches."
                }
            }
        } catch {
            if ($_.Exception.Message -like 'WoW is currently running*') { throw }
        }
    }
}

$RequiredClientFiles = @(
    "Interface\AddOns\ElvUI\ElvUI.toc",
    "Interface\AddOns\ElvUI_OptionsUI\ElvUI_OptionsUI.toc",
    "Interface\AddOns\AdminPanel\AdminPanel.toc",
    "Interface\AddOns\AdventureGuide\AdventureGuide.toc",
    "Interface\AddOns\ExtendedCharacterStats\ExtendedCharacterStats.toc",
    "Interface\AddOns\EraTalents\EraTalents.toc",
    "Interface\AddOns\DBM-Core\DBM-Core.toc",
    "Interface\AddOns\TidyPlates\TidyPlates.toc",
    "Interface\AddOns\Pawn\Pawn.toc",
    "Interface\AddOns\MinimapButtonButton\MinimapButtonButton.toc"
)

function Assert-ClientTree([string]$Root, [string]$Label) {
    $missing = @()
    foreach ($relative in $RequiredClientFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $Root $relative) -PathType Leaf)) {
            $missing += $relative
        }
    }
    if ($missing.Count -gt 0) {
        throw "$Label validation failed. Missing:`n  - $($missing -join "`n  - ")"
    }
}

function Backup-And-CopyFolder([string]$Source, [string]$Destination, [string]$Backup) {
    if (Test-Path -LiteralPath $Destination) {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Backup) | Out-Null
        if (Test-Path -LiteralPath $Backup) { Remove-Item -LiteralPath $Backup -Recurse -Force }
        Copy-Item -LiteralPath $Destination -Destination $Backup -Recurse -Force
        Remove-Item -LiteralPath $Destination -Recurse -Force
    }
    Copy-Item -LiteralPath $Source -Destination $Destination -Recurse -Force
}

function Backup-And-RemoveFolder([string]$Destination, [string]$Backup) {
    if (-not (Test-Path -LiteralPath $Destination -PathType Container)) { return $false }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Backup) | Out-Null
    if (Test-Path -LiteralPath $Backup) { Remove-Item -LiteralPath $Backup -Recurse -Force }
    Copy-Item -LiteralPath $Destination -Destination $Backup -Recurse -Force
    Remove-Item -LiteralPath $Destination -Recurse -Force
    return $true
}

function Set-LegacyAddonLoading([string]$Root) {
    $wtf = Join-Path $Root "WTF\Config.wtf"
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $wtf) | Out-Null
    $line = 'SET checkAddonVersion "0"'

    if (Test-Path -LiteralPath $wtf) {
        $content = @(Get-Content -LiteralPath $wtf -ErrorAction Stop)
        $found = $false
        for ($i = 0; $i -lt $content.Count; $i++) {
            if ($content[$i] -match '^\s*SET\s+checkAddonVersion\s+') {
                $content[$i] = $line
                $found = $true
            }
        }
        if (-not $found) { $content += $line }
        Set-Content -LiteralPath $wtf -Value $content -Encoding ASCII
    } else {
        Set-Content -LiteralPath $wtf -Value $line -Encoding ASCII
    }

    if (-not (Select-String -LiteralPath $wtf -Pattern '^SET checkAddonVersion "0"$' -Quiet)) {
        throw "Failed to persist checkAddonVersion=0 in $wtf"
    }
}

function Get-TopLevelAddonFolders([string]$AddOnsRoot) {
    $result = @()
    foreach ($dir in @(Get-ChildItem -LiteralPath $AddOnsRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name)) {
        if (@(Get-ChildItem -LiteralPath $dir.FullName -File -Filter '*.toc' -ErrorAction SilentlyContinue).Count -gt 0) {
            $result += $dir.Name
        }
    }
    return $result
}

$resolvedZip = (Resolve-Path -LiteralPath $PackZip -ErrorAction Stop).Path
$resolvedWow = Assert-WowTarget $WowPath
$destAddons = Canonical (Join-Path $resolvedWow "Interface\AddOns")
Assert-ChildPath $resolvedWow $destAddons "AddOns destination"

Write-Host "Azeroth 3.3.5a client installer" -ForegroundColor Green
Write-Host "WoW root : $resolvedWow"
Write-Host "AddOns   : $destAddons"
Write-Host "Client auto-discovery: DISABLED" -ForegroundColor Yellow
Assert-WowClosed $resolvedWow

$temp = Join-Path ([IO.Path]::GetTempPath()) ("AzerothClientPack-" + [guid]::NewGuid().ToString("N"))
$extract = Join-Path $temp "pack"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupRoot = Join-Path $resolvedWow "_AzerothGuildBackup\$timestamp"

try {
    New-Item -ItemType Directory -Force -Path $extract | Out-Null
    Write-Step "Extracting and validating generated pack"
    Expand-Archive -LiteralPath $resolvedZip -DestinationPath $extract -Force
    Assert-ClientTree $extract "Generated client pack"
    Write-Host "    Pack validation: OK" -ForegroundColor Green

    $sourceAddons = Join-Path $extract "Interface\AddOns"
    New-Item -ItemType Directory -Force -Path $destAddons | Out-Null
    Assert-ChildPath $resolvedWow $destAddons "AddOns destination"

    Write-Step "Removing retired/redundant addons from the selected private client"
    foreach ($retired in $RetiredClientAddons) {
        $dest = Join-Path $destAddons $retired
        Assert-ChildPath $resolvedWow $dest "Retired addon destination"
        $backup = Join-Path $backupRoot ("Interface\AddOns\" + $retired)
        if (Backup-And-RemoveFolder $dest $backup) {
            Write-Host "    - $retired (backed up first)" -ForegroundColor Yellow
        } else {
            Write-Host "    - $retired (not installed)"
        }
    }

    Write-Step "Installing addons into $destAddons"
    $installed = @()
    foreach ($addon in @(Get-ChildItem -LiteralPath $sourceAddons -Directory | Sort-Object Name)) {
        if ($RetiredClientAddons -contains $addon.Name) { continue }
        $dest = Join-Path $destAddons $addon.Name
        Assert-ChildPath $resolvedWow $dest "Addon destination"
        $backup = Join-Path $backupRoot ("Interface\AddOns\" + $addon.Name)
        Backup-And-CopyFolder $addon.FullName $dest $backup
        $installed += $addon.Name
        Write-Host "    + $($addon.Name)"
    }

    $sourceData = Join-Path $extract "Data"
    $destData = Canonical (Join-Path $resolvedWow "Data")
    if (Test-Path -LiteralPath $sourceData -PathType Container) {
        Write-Step "Installing required client data patches into the selected private client"
        foreach ($file in @(Get-ChildItem -LiteralPath $sourceData -File -Recurse)) {
            $relative = $file.FullName.Substring($sourceData.Length).TrimStart('\')
            $dest = Join-Path $destData $relative
            Assert-ChildPath $destData $dest "Data patch destination"
            $backup = Join-Path $backupRoot ("Data\" + $relative)
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null
            if (Test-Path -LiteralPath $dest) {
                New-Item -ItemType Directory -Force -Path (Split-Path -Parent $backup) | Out-Null
                Copy-Item -LiteralPath $dest -Destination $backup -Force
            }
            Copy-Item -LiteralPath $file.FullName -Destination $dest -Force
            Write-Host "    + Data\$relative"
        }
    }

    Write-Step "Enabling compatible legacy 3.3.5 addons"
    Set-LegacyAddonLoading $resolvedWow

    Write-Step "Verifying installed client"
    Assert-ClientTree $resolvedWow "Installed 3.3.5a client"
    $detectedAddons = @(Get-TopLevelAddonFolders $destAddons)
    foreach ($mustShow in @('ElvUI', 'ElvUI_OptionsUI', 'AdminPanel', 'AdventureGuide', 'ExtendedCharacterStats', 'EraTalents', 'DBM-Core', 'TidyPlates', 'Pawn', 'MinimapButtonButton')) {
        if ($detectedAddons -notcontains $mustShow) {
            throw "Post-install scan could not see '$mustShow' in $destAddons"
        }
    }
    foreach ($retired in $RetiredClientAddons) {
        if (Test-Path -LiteralPath (Join-Path $destAddons $retired)) {
            throw "Post-install cleanup failed: retired addon '$retired' is still present in $destAddons"
        }
    }

    $marker = [ordered]@{
        installedAt = (Get-Date).ToString("o")
        wowPath = $resolvedWow
        addonPath = $destAddons
        clientAutoDiscovery = "disabled"
        sourceZip = $resolvedZip
        installedAddonFolders = $installed
        retiredAddonFolders = $RetiredClientAddons
        detectedTocAddonFolders = $detectedAddons
        backup = $backupRoot
        validation = "passed"
    }
    $marker | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $resolvedWow ".azerothguild-client.json") -Encoding UTF8

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor DarkGray
    Write-Host "CLIENT READY - VALIDATION PASSED" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor DarkGray
    Write-Host "Installed into: $destAddons" -ForegroundColor Green
    Write-Host "No other WoW installation was searched or modified." -ForegroundColor Yellow
    Write-Host "Backup: $backupRoot"
    Write-Host "Start: $(Join-Path $resolvedWow 'Wow.exe')" -ForegroundColor Yellow
}
finally {
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue }
}
