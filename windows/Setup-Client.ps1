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

function Get-WowExecutableVersion([string]$WowExe) {
    $info = (Get-Item -LiteralPath $WowExe).VersionInfo
    return [pscustomobject]@{
        Major = [int]$info.FileMajorPart
        Minor = [int]$info.FileMinorPart
        Patch = [int]$info.FileBuildPart
        Build = [int]$info.FilePrivatePart
        FileVersion = [string]$info.FileVersion
        ProductVersion = [string]$info.ProductVersion
    }
}

function Assert-WowClient([string]$WowExe, [pscustomobject]$ClientManifest) {
    $version = Get-WowExecutableVersion -WowExe $WowExe
    $expected = "3.3.5.$($ClientManifest.build)"
    $partsMatch = $version.Major -eq 3 -and $version.Minor -eq 3 -and $version.Patch -eq 5 -and $version.Build -eq [int]$ClientManifest.build

    # Some old executables expose incomplete numeric FileVersionInfo parts but still carry the
    # full version in FileVersion/ProductVersion, so accept that exact normalized value as a
    # fallback instead of silently trusting the folder name.
    $versionText = (($version.FileVersion + " " + $version.ProductVersion) -replace '[^0-9]+', '.').Trim('.')
    $textMatch = $versionText -match '(^|\.)3\.3\.5\.' + [regex]::Escape([string]$ClientManifest.build) + '(\.|$)'

    if (-not $partsMatch -and -not $textMatch) {
        throw "Unsupported Wow.exe. Expected WoW 3.3.5a build $($ClientManifest.build), but executable metadata reported FileVersion='$($version.FileVersion)' ProductVersion='$($version.ProductVersion)' numeric=$($version.Major).$($version.Minor).$($version.Patch).$($version.Build)."
    }

    return [pscustomobject]@{
        Expected = $expected
        DetectedNumeric = "$($version.Major).$($version.Minor).$($version.Patch).$($version.Build)"
        FileVersion = $version.FileVersion
        ProductVersion = $version.ProductVersion
    }
}

function Get-TocInterfaceValues([System.IO.DirectoryInfo]$AddonRoot) {
    $values = @()
    $tocFiles = Get-ChildItem -LiteralPath $AddonRoot.FullName -Filter "*.toc" -File -ErrorAction SilentlyContinue
    foreach ($toc in $tocFiles) {
        foreach ($line in (Get-Content -LiteralPath $toc.FullName -ErrorAction Stop)) {
            $clean = ([string]$line).TrimStart([char]0xFEFF)
            if ($clean -match '^\s*##\s*Interface:\s*([0-9]+)') {
                $values += [int]$Matches[1]
            }
        }
    }
    return @($values | Select-Object -Unique)
}

function Assert-AddonRoot(
    [System.IO.DirectoryInfo]$AddonRoot,
    [int]$ExpectedInterface
) {
    $tocFiles = Get-ChildItem -LiteralPath $AddonRoot.FullName -Filter "*.toc" -File -ErrorAction SilentlyContinue
    if (-not $tocFiles) {
        throw "'$($AddonRoot.FullName)' is not an addon root (no top-level .toc file)."
    }

    $interfaces = @(Get-TocInterfaceValues -AddonRoot $AddonRoot)
    if ($interfaces.Count -eq 0) {
        throw "'$($AddonRoot.FullName)' has .toc files but none declare ## Interface."
    }
    if ($interfaces -notcontains $ExpectedInterface) {
        throw "'$($AddonRoot.Name)' is not validated for client interface $ExpectedInterface. Declared interface value(s): $($interfaces -join ', ')."
    }
}

function Force-EnableAddon([System.IO.DirectoryInfo]$AddonRoot) {
    $tocFiles = Get-ChildItem -LiteralPath $AddonRoot.FullName -Filter "*.toc" -File -ErrorAction SilentlyContinue
    foreach ($toc in $tocFiles) {
        $lines = @(Get-Content -LiteralPath $toc.FullName -ErrorAction Stop)
        $filtered = @($lines | Where-Object {
            $clean = ([string]$_).TrimStart([char]0xFEFF)
            $clean -notmatch '^\s*##\s*DefaultState:\s*disabled\s*$'
        })
        if ($filtered.Count -ne $lines.Count) {
            Set-Content -LiteralPath $toc.FullName -Value $filtered -Encoding UTF8
        }
    }
}

function Stage-AddonRoot(
    [System.IO.DirectoryInfo]$Source,
    [string]$StagingRoot,
    [int]$ExpectedInterface,
    [string]$DestinationName = "",
    [bool]$ForceEnabled = $false
) {
    Assert-AddonRoot -AddonRoot $Source -ExpectedInterface $ExpectedInterface

    $name = if ($DestinationName) { $DestinationName } else { $Source.Name }
    $destination = Join-Path $StagingRoot $name
    if (Test-Path -LiteralPath $destination) {
        throw "Duplicate addon destination '$name' was produced by the client manifest."
    }

    Copy-Item -LiteralPath $Source.FullName -Destination $destination -Recurse -Force
    $staged = Get-Item -LiteralPath $destination
    if ($ForceEnabled) {
        Force-EnableAddon -AddonRoot $staged
    }
    Assert-AddonRoot -AddonRoot $staged -ExpectedInterface $ExpectedInterface
    Write-Host "    Staged $name"
}

function Stage-PinnedGithubAddon(
    [pscustomobject]$Addon,
    [string]$StagingRoot,
    [string]$WorkingRoot,
    [int]$ExpectedInterface
) {
    if ($Addon.installMode -notin @("github-archive", "github-archive-root-addon")) {
        throw "Unsupported installMode '$($Addon.installMode)' for $($Addon.id)."
    }

    $repoUri = [Uri]$Addon.repository
    if ($repoUri.Host -ne "github.com") {
        throw "Only github.com repositories are supported by the pinned client installer: $($Addon.repository)"
    }

    $repoSlug = $repoUri.AbsolutePath.Trim('/')
    if ($repoSlug.Split('/').Count -ne 2) {
        throw "Invalid GitHub repository URL '$($Addon.repository)'."
    }

    if ([string]::IsNullOrWhiteSpace([string]$Addon.ref) -or ([string]$Addon.ref) -notmatch '^[0-9a-fA-F]{40}$') {
        throw "$($Addon.name) must be pinned to an exact 40-character Git commit SHA."
    }

    $archive = "https://github.com/$repoSlug/archive/$($Addon.ref).zip"
    $addonWork = Join-Path $WorkingRoot $Addon.id
    $zipPath = Join-Path $addonWork "$($Addon.id).zip"
    $extractDir = Join-Path $addonWork "extract"
    New-Item -ItemType Directory -Force -Path $addonWork, $extractDir | Out-Null

    Write-Step "Validating $($Addon.name)"
    Write-Host "    Source: $($Addon.repository)"
    Write-Host "    Commit: $($Addon.ref)"

    Invoke-WebRequest -UseBasicParsing -Uri $archive -OutFile $zipPath
    Expand-Archive -LiteralPath $zipPath -DestinationPath $extractDir -Force

    $repoDirectories = @(Get-ChildItem -LiteralPath $extractDir -Directory)
    if ($repoDirectories.Count -ne 1) {
        throw "$($Addon.name) archive should contain exactly one repository root, found $($repoDirectories.Count)."
    }
    $extractedRepo = $repoDirectories[0]

    $forceEnabled = $false
    if ($Addon.PSObject.Properties.Name -contains "forceEnabled") {
        $forceEnabled = [bool]$Addon.forceEnabled
    }

    if ($Addon.installMode -eq "github-archive-root-addon") {
        if ([string]::IsNullOrWhiteSpace([string]$Addon.rootAddonName)) {
            throw "$($Addon.name) uses github-archive-root-addon but rootAddonName is empty."
        }
        Stage-AddonRoot -Source $extractedRepo -StagingRoot $StagingRoot -ExpectedInterface $ExpectedInterface -DestinationName $Addon.rootAddonName -ForceEnabled $forceEnabled
        return
    }

    $topLevelAddonFolders = @(Get-ChildItem -LiteralPath $extractedRepo.FullName -Directory | Where-Object {
        Get-ChildItem -LiteralPath $_.FullName -Filter "*.toc" -File -ErrorAction SilentlyContinue | Select-Object -First 1
    })
    if ($topLevelAddonFolders.Count -eq 0) {
        throw "No top-level addon folders with .toc files were found for $($Addon.name)."
    }

    $selected = @()
    $hasExplicitFolders = $Addon.PSObject.Properties.Name -contains "addonFolders" -and @($Addon.addonFolders).Count -gt 0
    if ($hasExplicitFolders) {
        foreach ($folderName in @($Addon.addonFolders)) {
            $match = @($topLevelAddonFolders | Where-Object { $_.Name -eq [string]$folderName })
            if ($match.Count -ne 1) {
                throw "$($Addon.name) expected top-level addon folder '$folderName', but it was not found exactly once at commit $($Addon.ref)."
            }
            $selected += $match[0]
        }
    }
    elseif ($Addon.PSObject.Properties.Name -contains "installAllTopLevelTocFolders" -and [bool]$Addon.installAllTopLevelTocFolders) {
        $selected = $topLevelAddonFolders
    }
    else {
        throw "$($Addon.name) must declare addonFolders or installAllTopLevelTocFolders=true."
    }

    foreach ($folder in $selected) {
        Stage-AddonRoot -Source $folder -StagingRoot $StagingRoot -ExpectedInterface $ExpectedInterface -ForceEnabled $forceEnabled
    }
}

function Install-StagedAddons(
    [string]$StagingRoot,
    [string]$DestinationRoot,
    [string]$BackupRoot,
    [int]$ExpectedInterface
) {
    $stagedFolders = @(Get-ChildItem -LiteralPath $StagingRoot -Directory | Sort-Object Name)
    if ($stagedFolders.Count -eq 0) {
        throw "The validated staging directory is empty. Refusing to modify the live client."
    }

    # Validate the entire staged set again before the first live addon is touched.
    foreach ($folder in $stagedFolders) {
        Assert-AddonRoot -AddonRoot $folder -ExpectedInterface $ExpectedInterface
    }

    $applied = @()
    try {
        foreach ($folder in $stagedFolders) {
            $name = $folder.Name
            $destination = Join-Path $DestinationRoot $name
            $backupTarget = Join-Path $BackupRoot $name
            $hadOriginal = Test-Path -LiteralPath $destination

            if ($hadOriginal) {
                New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null
                if (Test-Path -LiteralPath $backupTarget) {
                    Remove-Item -LiteralPath $backupTarget -Recurse -Force
                }
                Copy-Item -LiteralPath $destination -Destination $backupTarget -Recurse -Force
            }

            # Record the rollback information before the destructive step.
            $applied += [pscustomobject]@{
                Name = $name
                Destination = $destination
                Backup = $backupTarget
                HadOriginal = $hadOriginal
            }

            if (Test-Path -LiteralPath $destination) {
                Remove-Item -LiteralPath $destination -Recurse -Force
            }
            Copy-Item -LiteralPath $folder.FullName -Destination $destination -Recurse -Force
            Write-Host "    Installed $name"
        }
    }
    catch {
        Write-Host "Install failed. Rolling back addon folders already touched..." -ForegroundColor Yellow
        for ($i = $applied.Count - 1; $i -ge 0; --$i) {
            $entry = $applied[$i]
            if (Test-Path -LiteralPath $entry.Destination) {
                Remove-Item -LiteralPath $entry.Destination -Recurse -Force -ErrorAction SilentlyContinue
            }
            if ($entry.HadOriginal -and (Test-Path -LiteralPath $entry.Backup)) {
                Copy-Item -LiteralPath $entry.Backup -Destination $entry.Destination -Recurse -Force
            }
        }
        throw
    }
}

if (-not (Test-Path -LiteralPath $ManifestPath)) {
    throw "Client manifest not found: $ManifestPath"
}
$manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
if (-not $manifest.client.interface) {
    throw "Client manifest is missing client.interface."
}
$expectedInterface = [int]$manifest.client.interface

$resolved = Resolve-Path -LiteralPath $WowPath -ErrorAction Stop
$WowPath = $resolved.Path
$wowExe = Join-Path $WowPath "Wow.exe"
if (-not (Test-Path -LiteralPath $wowExe -PathType Leaf)) {
    throw "Wow.exe was not found in '$WowPath'. Point -WowPath at the root of a legitimate WoW 3.3.5a client."
}

$validatedClient = Assert-WowClient -WowExe $wowExe -ClientManifest $manifest.client

$addonsDir = Join-Path $WowPath "Interface\AddOns"
New-Item -ItemType Directory -Force -Path $addonsDir | Out-Null

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = Join-Path $WowPath "_AzerothGuildBackup\$timestamp\AddOns"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("AzerothGuild-Client-" + [guid]::NewGuid().ToString("N"))
$stagingRoot = Join-Path $tempRoot "validated-addons"
$downloadRoot = Join-Path $tempRoot "downloads"

try {
    New-Item -ItemType Directory -Force -Path $stagingRoot, $downloadRoot | Out-Null

    Write-Host "AzerothGuild client setup" -ForegroundColor Green
    Write-Host "WoW: $WowPath"
    Write-Host "Validated executable: $($validatedClient.Expected)"
    Write-Host "Addon interface: $expectedInterface"
    Write-Host "Target UI: $TargetResolution"
    Write-Host ""

    # Phase 1: download, extract and validate every pinned addon without changing the live client.
    foreach ($addon in $manifest.addons) {
        Stage-PinnedGithubAddon -Addon $addon -StagingRoot $stagingRoot -WorkingRoot $downloadRoot -ExpectedInterface $expectedInterface
    }

    # Phase 2: apply the already-validated set. Any copy failure rolls back touched folders.
    Write-Step "Applying validated addon set"
    Install-StagedAddons -StagingRoot $stagingRoot -DestinationRoot $addonsDir -BackupRoot $backupDir -ExpectedInterface $expectedInterface

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
        wowBuild = [int]$manifest.client.build
        wowInterface = $expectedInterface
        detectedWowNumericVersion = $validatedClient.DetectedNumeric
        detectedWowFileVersion = $validatedClient.FileVersion
        detectedWowProductVersion = $validatedClient.ProductVersion
        targetResolution = $TargetResolution
        uiPreset = $manifest.client.preset
        addons = $markerAddons
        preferredNameplates = "TidyPlates_ThreatPlates"
        bossMod = "DBM-Core"
        installedAt = (Get-Date).ToString("o")
    }

    $markerPath = Join-Path $WowPath ".azerothguild-client.json"
    $marker | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $markerPath -Encoding UTF8

    Write-Host ""
    Write-Host "Client addon setup complete." -ForegroundColor Green
    Write-Host "Installed pinned ElvUI, TidyPlates/ThreatPlates, RestedXP, WeakAuras and complete TBC/WotLK DBM builds."
    Write-Host "Primary UI target: $TargetResolution"
    if (Test-Path -LiteralPath $backupDir) {
        Write-Host "Previous addon folders were backed up under: $backupDir"
    }
    Write-Host ""
    Write-Host "NOTE: the 3440x1440 Naowh-inspired SavedVariables profile is intentionally applied only after in-client validation. The installer pins, validates and installs the addon stack without modifying the WoW client executable."
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
