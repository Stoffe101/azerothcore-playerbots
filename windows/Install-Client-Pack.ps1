param(
    [Parameter(Mandatory = $true)]
    [string]$PackZip,

    [string]$WowPath = ""
)

$ErrorActionPreference = "Stop"

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

    $running = Get-RunningWowRoot
    if ($running) { return $running }

    $candidates = New-Object 'System.Collections.Generic.List[string]'
    $home = [Environment]::GetFolderPath('UserProfile')
    $desktop = [Environment]::GetFolderPath('Desktop')
    $documents = [Environment]::GetFolderPath('MyDocuments')

    foreach ($root in @(
        "C:\\Games", "C:\\WoW", "C:\\World of Warcraft", "D:\\Games", "D:\\WoW", "D:\\World of Warcraft",
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
        if (Test-WowRoot $candidate) {
            # Prefer an obvious 3.3.5/private-client path if several are found.
            if ($candidate -match '(?i)(3\.3\.5|335|wotlk|wrath|azeroth)') { return $candidate }
        }
    }
    foreach ($candidate in $candidates) {
        if (Test-WowRoot $candidate) { return $candidate }
    }
    return $null
}

function Assert-Wow335([string]$Root) {
    $exe = Join-Path $Root "Wow.exe"
    $info = (Get-Item -LiteralPath $exe).VersionInfo
    $text = "$($info.FileVersion) $($info.ProductVersion)"
    if ($text -match '3\.3\.5' -or $text -match '12340') {
        Write-Host "    Client version: $text"
        return
    }

    # Old/private 3.3.5 executables sometimes have stripped Windows version metadata. Do not block
    # a legitimate client solely on that, but make a retail-folder mistake very obvious.
    Write-Host "    WARNING: Wow.exe metadata did not explicitly say 3.3.5/12340: '$text'" -ForegroundColor Yellow
    Write-Host "    Continuing because Wow.exe + Data were found at the selected root." -ForegroundColor Yellow
}

function Assert-Pack([string]$Root) {
    $required = @(
        "Interface\AddOns\ElvUI\ElvUI.toc",
        "Interface\AddOns\ElvUI_OptionsUI\ElvUI_OptionsUI.toc",
        "Interface\AddOns\AdminPanel\AdminPanel.toc",
        "Interface\AddOns\ExtendedCharacterStats\ExtendedCharacterStats.toc",
        "Interface\AddOns\EraTalents\EraTalents.toc",
        "Interface\AddOns\DBM-Core\DBM-Core.toc",
        "Interface\AddOns\TidyPlates\TidyPlates.toc"
    )
    foreach ($relative in $required) {
        if (-not (Test-Path -LiteralPath (Join-Path $Root $relative) -PathType Leaf)) {
            throw "Client pack validation failed: missing $relative"
        }
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

$resolvedZip = (Resolve-Path -LiteralPath $PackZip -ErrorAction Stop).Path
$resolvedWow = Find-WowRoot $WowPath
if (-not $resolvedWow) {
    throw @"
Could not find your WoW 3.3.5a folder automatically.
Run again with the exact client root, for example from WSL:
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File <installer> -PackZip <zip> -WowPath 'C:\path\to\WoW 3.3.5a'
Or set the Windows environment variable WOW_CLIENT_PATH to that folder once.
"@
}

Write-Host "Azeroth client installer" -ForegroundColor Green
Write-Host "WoW root: $resolvedWow"
Assert-Wow335 $resolvedWow

$temp = Join-Path ([IO.Path]::GetTempPath()) ("AzerothClientPack-" + [guid]::NewGuid().ToString("N"))
$extract = Join-Path $temp "pack"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupRoot = Join-Path $resolvedWow "_AzerothGuildBackup\$timestamp"

try {
    New-Item -ItemType Directory -Force -Path $extract | Out-Null
    Write-Step "Extracting and validating pack"
    Expand-Archive -LiteralPath $resolvedZip -DestinationPath $extract -Force
    Assert-Pack $extract

    $sourceAddons = Join-Path $extract "Interface\AddOns"
    $destAddons = Join-Path $resolvedWow "Interface\AddOns"
    New-Item -ItemType Directory -Force -Path $destAddons | Out-Null

    Write-Step "Installing addons"
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
            $relative = $file.FullName.Substring($sourceData.Length).TrimStart('\\')
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

    Write-Step "Enabling legacy 3.3.5 addons"
    $wtf = Join-Path $resolvedWow "WTF\Config.wtf"
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

    $marker = [ordered]@{
        installedAt = (Get-Date).ToString("o")
        wowPath = $resolvedWow
        sourceZip = $resolvedZip
        addons = $installed
        backup = $backupRoot
    }
    $marker | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $resolvedWow ".azerothguild-client.json") -Encoding UTF8

    Write-Host ""
    Write-Host "CLIENT READY." -ForegroundColor Green
    Write-Host "Installed $($installed.Count) addon folders into: $destAddons"
    Write-Host "Backup of overwritten files/folders: $backupRoot"
    Write-Host ""
    Write-Host "Close WoW completely if it is open, then relaunch it." -ForegroundColor Yellow
    Write-Host "At character select you should now see AddOns, including ElvUI, AdminPanel and ExtendedCharacterStats."
}
finally {
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue }
}
