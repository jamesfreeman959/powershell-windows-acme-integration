$directoryPath = "C:\cert"
# Check if the directory exists
if (-not (Test-Path -Path $directoryPath)) {
    # Directory does not exist, so create it
    New-Item -Path $directoryPath -ItemType Directory
    Write-Output "Directory created at $directoryPath"
} else {
    Write-Output "Directory already exists at $directoryPath"
}
Copy-Item -Path "installcert.ps1" -Destination "C:\cert"
Copy-Item -Path "plugin-variables.ps1" -Destination "C:\cert"

$Trigger = New-ScheduledTaskTrigger -At 02:00am -Daily
$Action= New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument '-executionpolicy bypass -file "C:\Cert\installcert.ps1"'
Register-ScheduledTask -TaskName "Certificate AutoRenewal" -Action $Action -Trigger $Trigger -User "NT AUTHORITY\SYSTEM" -RunLevel Highest -Force

