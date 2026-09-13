param(
    [Parameter(Mandatory = $true)]
    [string]$PackZip,

    [string]$WowPath = ""
)

$ErrorActionPreference = "Stop"
$KnownProjectWowRoot = "D:\wow private server\TheraWoW wotlk"

function Write-Step([string]$Message) {
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Test-WowRoot([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    try { $full = [IO.Path]::GetFullPath($Path) } catch { return $false }
    return (Test-Path -LiteralPath (Join-Path $full "Wow.exe") -PathType Leaf) -and
           (Test-Path -LiteralPath (Join-Path $full "Data") -PathType Container)
}

function Get-RunningWowRoot {
    $processes = @(Get-Process Wow -ErrorAction SilentlyContinue)
    foreach ($p in $processes) {
        try {
            $exe = $p.MainModule.FileName
            if ($exe) {
                $root = Split-Path -Parent $exe
                if (Test-WowRoot $root) { return $root }
            }
        } catch { }
    }
    return $null
}

function Add-Candidate([System.Collections.Generic.List[string]]$List, [string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) { return }
    try { $full = [IO.Path]::GetFullPath($Path) } catch { return }
    if (-not $List.Contains($full)) { $List.Add($full) }
}

function Find-WowRoot([string]$Explicit) {
    if (Test-WowRoot $Explicit) { return [IO.Path]::GetFullPath($Explicit) }

    if ($env:WOW_CLIENT_PATH -and (Test-WowRoot $env:WOW_CLIENT_PATH)) {
        return [IO.Path]::GetFullPath($env:WOW_CLIENT_PATH)
    }

    # This project already has a known client location. Prefer it before broad disk discovery so a
    # second WoW install can never accidentally receive the private-server addons/data patches.
    if (Test-WowRoot $KnownProjectWowRoot) {
        return [IO.Path]::GetFullPath($KnownProjectWowRoot)
    }

    $running = Get-RunningWowRoot
    if ($running) { return $running }

    $candidates = New-Object 'System.Collections.Generic.List[string]'
    $home = [Environment]::GetFolderPath('UserProfile')
    $desktop = [Environment]::GetFolderPath('Desktop')
    $documents = [Environment]::GetFolderPath('MyDocuments')

    foreach ($root in @(
        "C:\Games", "C:\WoW", "C:\World of Warcraft", "D:\Games", "D:\WoW", "D:\World of Warcraft",
        (Join-Path $home "Downloads"), $desktop, $documents
    )) {
        if (-not (Test-Path -LiteralPath $root -PathType Container)) { continue }
        Add-Candidate $candidates $root
        foreach ($child in @(Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue)) {
            Add-Candidate $candidates $child.FullName
            foreach ($grandChild in @(Get-ChildItem -LiteralPath $child.FullName -Directory -ErrorAction SilentlyContinue)) {
                Add-Candidate $candidates $grandChild.FullName
            }
        }
    }

    foreach ($candidate in $candidates) {
        if (Test-WowRoot $candidate -and $candidate -match '(?i)(3\.3\.5|335|wotlk|wrath|azeroth|private)') {
            return $candidate
        }
    }
    foreach ($candidate in $candidates) {
        if (Test-WowRoot $candidate) { return $candidate }
    }
    return $null
}

function Assert-WowClosed([string]$Root) {
    foreach ($p in @(Get-Process Wow -ErrorAction SilentlyContinue)) {
        try {
            $exe = $p.MainModule.FileName
            if ($exe -and ([IO.Path]::GetFullPath((Split-Path -Parent $exe))).TrimEnd('\') -ieq ([IO.Path]::GetFullPath($Root)).TrimEnd('\')) {
                throw "WoW is currently running from '$Root'. Close WoW completely, then run the installer again. Installing while the client is open is exactly how addons end up invisible until the next launch."
            }
        } catch {
            if ($_.Exception.Message -like 'WoW is currently running*') { throw }
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

    Write-Host "    WARNING: Wow.exe metadata did not explicitly say 3.3.5/12340: '$text'" -ForegroundColor Yellow
    Write-Host "    Continuing because this is the selected private-server client root." -ForegroundColor Yellow
}

$RequiredClientFiles = @(
    "Interface\AddOns\ElvUI\ElvUI.toc",
    "Interface\AddOns\ElvUI_OptionsUI\ElvUI_OptionsUI.toc",
    "Interface\AddOns\AdminPanel\AdminPanel.toc",
    "Interface\AddOns\ExtendedCharacterStats\ExtendedCharacterStats.toc",
    "Interface\AddOns\EraTalents\EraTalents.toc",
    "Interface\AddOns\DBM-Core\DBM-Core.toc",
    "Interface\AddOns\TidyPlates\TidyPlates.toc"
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
$resolvedWow = Find-WowRoot $WowPath
if (-not $resolvedWow) {
    throw @"
Could not find the WoW 3.3.5a folder automatically.
Expected project client: D:\wow private server\TheraWoW wotlk
You can also run with -WowPath '<exact WoW root>' or set WOW_CLIENT_PATH once.
"@
}

Write-Host "Azeroth client installer" -ForegroundColor Green
Write-Host "WoW root: $resolvedWow"
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
    $destAddons = Join-Path $resolvedWow "Interface\AddOns"
    New-Item -ItemType Directory -Force -Path $destAddons | Out-Null

    Write-Step "Installing addon folders into the actual client"
    $installed = @()
    foreach ($addon in @(Get-ChildItem -LiteralPath $sourceAddons -Directory | Sort-Object Name)) {
        $dest = Join-Path $destAddons $addon.Name
        $backup = Join-Path $backupRoot ("Interface\AddOns\" + $addon.Name)
        Backup-And-CopyFolder $addon.FullName $dest $backup
        $installed += $addon.Name
        Write-Host "    + $($addon.Name)"
    }

    $sourceData = Join-Path $extract "Data"
    if (Test-Path -LiteralPath $sourceData -PathType Container) {
        Write-Step "Installing required client data patches"
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

    Write-Step "Enabling compatible legacy addons"
    Set-LegacyAddonLoading $resolvedWow

    Write-Step "Verifying the INSTALLED client, not just the zip"
    Assert-ClientTree $resolvedWow "Installed WoW client"
    $detectedAddons = @(Get-TopLevelAddonFolders $destAddons)
    Write-Host "    Installed client validation: OK" -ForegroundColor Green
    Write-Host "    WoW currently has $($detectedAddons.Count) top-level addon folders with a .toc"

    foreach ($mustShow in @('ElvUI', 'ElvUI_OptionsUI', 'AdminPanel', 'ExtendedCharacterStats', 'EraTalents', 'DBM-Core', 'TidyPlates')) {
        if ($detectedAddons -notcontains $mustShow) {
            throw "Post-install addon scan could not see '$mustShow' in $destAddons"
        }
        Write-Host "    [OK] $mustShow"
    }

    $marker = [ordered]@{
        installedAt = (Get-Date).ToString("o")
        wowPath = $resolvedWow
        sourceZip = $resolvedZip
        installedAddonFolders = $installed
        detectedTocAddonFolders = $detectedAddons
        backup = $backupRoot
        validation = "passed"
    }
    $marker | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $resolvedWow ".azerothguild-client.json") -Encoding UTF8

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor DarkGray
    Write-Host "CLIENT READY - VALIDATION PASSED" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor DarkGray
    Write-Host "Installed $($installed.Count) pack folders into:"
    Write-Host "  $destAddons"
    Write-Host "Backup of replaced files/folders:"
    Write-Host "  $backupRoot"
    Write-Host ""
    Write-Host "Start Wow.exe now. At character select the AddOns button should show ElvUI, Azeroth Control, Extended Character Stats and the rest." -ForegroundColor Yellow
    Write-Host "If the AddOns button is still missing after this validation passes, do NOT reinstall blindly; capture the character-select screen and the generated .azerothguild-client.json instead."
}
finally {
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue }
}
