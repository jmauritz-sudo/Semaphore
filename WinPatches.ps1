# List of remote servers
$RemoteServers = @("HFOIT2421-M")

# Get credentials once
$Cred = Get-Credential

# Define the update script content
$UpdateScript = @'
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force

# Configure WinRM if needed
try {
    & cmd.exe /c "winrm quickconfig -q"
} catch {
    Write-EventLog -LogName Application -Source "PSWindowsUpdateTask" -EntryType Warning -EventId 1001 -Message "Failed to run winrm quickconfig: $($_.Exception.Message)"
}

# Disable UAC token filtering (optional, depending on setup)
try {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "LocalAccountTokenFilterPolicy" -Value 1 -Type DWord
} catch {
    Write-EventLog -LogName Application -Source "PSWindowsUpdateTask" -EntryType Warning -EventId 1002 -Message "Failed to set LocalAccountTokenFilterPolicy."
}

# Install update module
try {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser
    Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser -AllowClobber
} catch {
    Write-EventLog -LogName Application -Source "PSWindowsUpdateTask" -EntryType Error -EventId 1003 -Message "Failed to install PSWindowsUpdate: $($_.Exception.Message)"
    exit
}

Import-Module PSWindowsUpdate

# Install all updates and auto reboot if needed
Install-WindowsUpdate -AcceptAll -AutoReboot -IgnoreReboot
'@

# Save the update script to a temp file on the remote machine
$RemoteScriptPath = "C:\Temp\InstallUpdates.ps1"

foreach ($Server in $RemoteServers) {
    Write-Host "Copying script to $Server..." -ForegroundColor Cyan

    Invoke-Command -ComputerName $Server -Credential $Cred -ScriptBlock {
        param($scriptContent, $path)
        if (-not (Test-Path "C:\Temp")) { New-Item -Path "C:\Temp" -ItemType Directory }
        Set-Content -Path $path -Value $scriptContent -Force
    } -ArgumentList $UpdateScript, $RemoteScriptPath

    Write-Host "Registering scheduled task on $Server..." -ForegroundColor Cyan

    Invoke-Command -ComputerName $Server -Credential $Cred -ScriptBlock {
        $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$using:RemoteScriptPath`""
        $Trigger = New-ScheduledTaskTrigger -Once -At ((Get-Date).AddMinutes(1))  # Starts in 1 minute
        $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
        $TaskName = "InstallUpdates"

        Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Force
        Start-ScheduledTask -TaskName $TaskName
    }
}
