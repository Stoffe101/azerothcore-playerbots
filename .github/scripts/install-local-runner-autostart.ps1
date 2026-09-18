# Registers the WSL GitHub Actions runner to start automatically at Windows logon.
# Run once from Windows PowerShell. No GitHub token is required.
[CmdletBinding()]
param(
    [string]$TaskName = "WoW Local CI Runner",
    [string]$Distro = "Ubuntu",
    [string]$RunnerDir = "~/actions-runner"
)

$ErrorActionPreference = "Stop"

$distros = @(
    (& wsl.exe -l -q 2>$null) |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ }
)

if ($distros -notcontains $Distro) {
    $ubuntu = $distros | Where-Object { $_ -like "Ubuntu*" } | Select-Object -First 1
    if (-not $ubuntu) {
        throw "Could not find a WSL Ubuntu distribution. Installed distributions: $($distros -join ', ')"
    }

    Write-Host "Requested distro '$Distro' was not found. Using '$ubuntu' instead."
    $Distro = $ubuntu
}

& wsl.exe -d $Distro -- bash -lc "test -x $RunnerDir/run.sh"
if ($LASTEXITCODE -ne 0) {
    throw "GitHub runner was not found at $RunnerDir/run.sh inside WSL distro '$Distro'."
}

$userId = if ($env:USERDOMAIN) {
    "$env:USERDOMAIN\$env:USERNAME"
} else {
    $env:USERNAME
}

$runnerCommand = "cd $RunnerDir && exec ./run.sh"
$action = New-ScheduledTaskAction `
    -Execute "$env:SystemRoot\System32\wsl.exe" `
    -Argument "-d $Distro -- bash -lc `"$runnerCommand`""

$trigger = New-ScheduledTaskTrigger -AtLogOn -User $userId
$principal = New-ScheduledTaskPrincipal `
    -UserId $userId `
    -LogonType Interactive `
    -RunLevel Limited

$settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -ExecutionTimeLimit ([TimeSpan]::Zero) `
    -MultipleInstances IgnoreNew

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Settings $settings `
    -Description "Starts the Stoffe101 AzerothCore GitHub Actions runner in WSL at Windows logon." `
    -Force | Out-Null

Write-Host ""
Write-Host "Registered scheduled task: $TaskName"
Write-Host "WSL distro: $Distro"
Write-Host "Runner command: $runnerCommand"
Write-Host ""
Write-Host "The runner will start automatically on your next Windows logon."
Write-Host "Your currently running ./run.sh can stay open for this session."
Write-Host ""
Write-Host "To remove the task later:"
Write-Host "  Unregister-ScheduledTask -TaskName '$TaskName' -Confirm:`$false"
