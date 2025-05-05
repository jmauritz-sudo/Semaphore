# Make sure the execution policy is set to All Signed
Set-ExecutionPolicy -ExecutionPolicy AllSigned

Write-Output "Checking to see if the Windows Update cmdlets are installed"
Install-Module PSWindowsUpdate -Confirm

Write-Output "Installing Windows Updates"
Get-WindowsUpdate -AcceptAll -Install -AutoReboot
