New-Item -Path "C:\Cert" -ItemType Directory
Copy-Item -Path "AutoRenewal.ps1" -Destination "C:\cert"

# Prompt for credentials (username and password)
$credential = Get-Credential

# Extract the password as a SecureString
$password = $credential.Password

$Trigger = New-ScheduledTaskTrigger -At 10:00am -Daily
$Action= New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "C:\Cert\AutoRenewal.ps1"
Register-ScheduledTask -TaskName "Certificate AutoRenewal" -Trigger $Trigger -User $credential.UserName -Password $credential.GetNetworkCredential().Password -Action $Action -RunLevel Highest -Force