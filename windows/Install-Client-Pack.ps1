param(
    [Parameter(Mandatory = $true)]
    [string]$PackZip,

    [string]$WowPath = "D:\wow private server\TheraWoW wotlk"
)

$ErrorActionPreference = "Stop"
$FixedWowRoot = "D:\wow private server\TheraWoW wotlk"
$FixedAddOnsRoot = "D:\wow private server\TheraWoW wotlk\Interface\AddOns"
$RetiredClientAddons = @(
    "Mapster"
)

function Write-Step([string]$Message) {
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Canonical([string]$Path) {
    return ([IO.Path]::GetFullPath($Path)).TrimEnd('\')
}

function Assert-FixedTarget([string]$Requested) {
    $expected = Canonical $FixedWowRoot
    $actual = Canonical $Requested
    if ($actual -ine $expected) {
        throw @"
REFUSING TO INSTALL.
This project is hard-locked to the private-server client:
  $FixedWowRoot
Requested target was:
  $Requested
Retail/other WoW installations are intentionally never auto-discovered or modified.
"@
    }

    $addons = Canonical (Join-Path $actual "Interface\AddOns")
    if ($addons -ine (Canonical $FixedAddOnsRoot)) {
        throw "Safety check failed: AddOns destination resolved to '$addons' instead of '$FixedAddOnsRoot'."
    }

    if (-not (Test-Path -LiteralPath (Join-Path $actual "Wow.exe") -PathType Leaf)) {
        throw "Private-server Wow.exe not found at '$actual'. No fallback search will be attempted."
    }
    if (-not (Test-Path -LiteralPath (Join-Path $actual "Data") -PathType Container)) {
        throw "Private-server Data folder not found at '$actual'."
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
                    throw "TheraWoW is currently running from '$Root'. Close it completely before installing addons/data patches."
                }
            }
        } catch {
            if ($_.Exception.Message -like 'TheraWoW is currently running*') { throw }
        }
    }
}

function Assert-Wow335([string]$Root) {
    $exe = Join-Path $Root "Wow.exe"
    $info = (Get-Item -LiteralPath $exe).VersionInfo
    $text = "$($info.FileVersion) $($info.ProductVersion)".Trim()
    if ($text -match '3\.3\.5' -or $text -match '12340') {
        Write-Host "    Client version: $text"
        return
    }

    # Some private 3.3.5 executables have stripped/odd Windows version metadata. The exact path
    # lock above is the primary safety boundary, so warn rather than redirecting to another client.
    Write-Host "    WARNING: Wow.exe metadata did not explicitly show 3.3.5/12340: '$text'" -ForegroundColor Yellow
    Write-Host "    Continuing ONLY because the target exactly matches the hard-locked TheraWoW path." -ForegroundColor Yellow
}

$RequiredClientFiles = @(
    "Interface\AddOns\ElvUI\ElvUI.toc",
    "Interface\AddOns\ElvUI_OptionsUI\ElvUI_OptionsUI.toc",
    "Interface\AddOns\AdminPanel\AdminPanel.toc",
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
    if (-not (Test-Path -LiteralPath $Destination -PathType Container)) {
        return $false
    }

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
$resolvedWow = Assert-FixedTarget $WowPath
$destAddons = Canonical (Join-Path $resolvedWow "Interface\AddOns")

Write-Host "Azeroth client installer" -ForegroundColor Green
Write-Host "SAFETY MODE: HARD-LOCKED PRIVATE CLIENT" -ForegroundColor Green
Write-Host "WoW root : $resolvedWow"
Write-Host "AddOns   : $destAddons"
Write-Host "Retail WoW discovery/install: DISABLED" -ForegroundColor Yellow
Assert-WowClosed $resolvedWow
Assert-Wow335 $resolvedWow

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

    # Re-check immediately before the first write. This is intentionally redundant: it makes it
    # impossible for an accidental path edit higher in the script to redirect files into retail.
    if ((Canonical $destAddons) -ine (Canonical $FixedAddOnsRoot)) {
        throw "WRITE BLOCKED: destination is not the fixed TheraWoW AddOns folder."
    }

    Write-Step "Removing retired/redundant addons from the private client"
    foreach ($retired in $RetiredClientAddons) {
        $dest = Join-Path $destAddons $retired
        $backup = Join-Path $backupRoot ("Interface\AddOns\" + $retired)
        if (Backup-And-RemoveFolder $dest $backup) {
            Write-Host "    - $retired (backed up first)" -ForegroundColor Yellow
        } else {
            Write-Host "    - $retired (not installed)"
        }
    }

    Write-Step "Installing addons into D:\wow private server\TheraWoW wotlk\Interface\AddOns"
    $installed = @()
    foreach ($addon in @(Get-ChildItem -LiteralPath $sourceAddons -Directory | Sort-Object Name)) {
        if ($RetiredClientAddons -contains $addon.Name) {
            Write-Host "    x $($addon.Name) (retired; intentionally skipped)" -ForegroundColor DarkGray
            continue
        }

        $dest = Join-Path $destAddons $addon.Name
        $backup = Join-Path $backupRoot ("Interface\AddOns\" + $addon.Name)
        Backup-And-CopyFolder $addon.FullName $dest $backup
        $installed += $addon.Name
        Write-Host "    + $($addon.Name)"
    }

    $sourceData = Join-Path $extract "Data"
    if (Test-Path -LiteralPath $sourceData -PathType Container) {
        Write-Step "Installing required client data patches into the SAME fixed private client"
        foreach ($file in @(Get-ChildItem -LiteralPath $sourceData -File -Recurse)) {
            $relative = $file.FullName.Substring($sourceData.Length).TrimStart('\')
            $dest = Join-Path (Join-Path $resolvedWow "Data") $relative
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

    Write-Step "Verifying the installed TheraWoW client"
    Assert-ClientTree $resolvedWow "Installed TheraWoW client"
    $detectedAddons = @(Get-TopLevelAddonFolders $destAddons)
    Write-Host "    Installed client validation: OK" -ForegroundColor Green
    Write-Host "    Found $($detectedAddons.Count) top-level addon folders with a .toc"

    foreach ($mustShow in @('ElvUI', 'ElvUI_OptionsUI', 'AdminPanel', 'ExtendedCharacterStats', 'EraTalents', 'DBM-Core', 'TidyPlates', 'Pawn', 'MinimapButtonButton')) {
        if ($detectedAddons -notcontains $mustShow) {
            throw "Post-install scan could not see '$mustShow' in $FixedAddOnsRoot"
        }
        Write-Host "    [OK] $mustShow"
    }

    foreach ($retired in $RetiredClientAddons) {
        if (Test-Path -LiteralPath (Join-Path $destAddons $retired)) {
            throw "Post-install cleanup failed: retired addon '$retired' is still present in $FixedAddOnsRoot"
        }
        Write-Host "    [REMOVED] $retired"
    }

    $marker = [ordered]@{
        installedAt = (Get-Date).ToString("o")
        wowPath = $resolvedWow
        addonPath = $destAddons
        hardLockedTarget = $FixedWowRoot
        retailDiscovery = "disabled"
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
    Write-Host "Installed ONLY into:"
    Write-Host "  $FixedAddOnsRoot" -ForegroundColor Green
    Write-Host "Retail/other WoW installations were not searched or modified." -ForegroundColor Yellow
    Write-Host "Backup of replaced private-client files/folders:"
    Write-Host "  $backupRoot"
    Write-Host ""
    Write-Host "Start: D:\wow private server\TheraWoW wotlk\Wow.exe" -ForegroundColor Yellow
    Write-Host "At character select, AddOns should include ElvUI, Azeroth Control, Pawn, MinimapButtonButton and the rest."
}
finally {
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue }
}
