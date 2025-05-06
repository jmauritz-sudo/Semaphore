# Set execution policy to allow script execution
Set-ExecutionPolicy RemoteSigned -Scope Process -Force

# Check for updates
$Updates = Get-WindowsUpdate -Online -EA 0

# Download updates if available
if ($Updates) {
    Write-Host "Downloading Updates..."
    Install-WindowsUpdate -Online -AcceptEula -EA 0
    Write-Host "Updates Downloaded and Installed"
} else {
    Write-Host "No updates available."
}

# Check if a reboot is required
if ((Get-WmiObject win32_operatingsystem).SystemUpTime -lt (New-TimeSpan -Hours 2)) {
    Write-Host "A reboot was recently performed, skipping reboot."
}
elseif ((Get-WindowsUpdateLog) -match "reboot is required") {
    Write-Host "Rebooting system..."
    Restart-Computer -Force
}
else {
    Write-Host "No reboot required."
}

Write-Host "Windows patching process completed."
