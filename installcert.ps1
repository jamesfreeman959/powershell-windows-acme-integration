# Get the FQDN of the system
$fqdn =  [System.Net.DNS]::GetHostByName('').HostName

$directoryPath = "C:\Cert\Posh-ACME"
$thumbprintPath = "C:\Cert\$fqdn-thumbprint.txt"

$contactEmail = 'sysadmin@hkskies.com'
$pluginVarsFile = Join-Path -Path $PSScriptRoot -ChildPath 'plugin-variables.ps1'

if (Test-Path -Path $pluginVarsFile) {
	. $pluginVarsFile
	Write-Output $pArgs
	Write-Output $contactEmail
	Write-Output $pluginName
} else {
	Write-Output "Plugin variables file $pluginVarsFile not found. Exiting."
	exit 1
}

# Check if the directory exists
if (-not (Test-Path -Path $directoryPath)) {
    # Directory does not exist, so create it
    New-Item -Path $directoryPath -ItemType Directory
    Write-Output "Directory created at $directoryPath"
} else {
    Write-Output "Directory already exists at $directoryPath"
}

$env:POSHACME_HOME = $directoryPath
Import-Module Posh-ACME -Force

# Check if the module is loaded
if (Get-Module -Name Posh-ACME) {
    Write-Output "Posh-ACME module successfully imported."
    
    # You can now use the cmdlets from the Posh-ACME module
    # Example: Retrieve a certificate thumbprint
    $thumbprint = Get-PACertificate -MainDomain $fqdn | Select -ExpandProperty Thumbprint
    
    Write-Output "Thumbprint: $thumbprint"
} else {
    Write-Output "Failed to import Posh-ACME module."
}

# Check if the file exists
if (Test-Path -Path $thumbprintPath) {
    # File exists, read the contents into a variable
    $oldThumbprint = Get-Content -Path $thumbprintPath
    
    Write-Output "Old thumbprint retrieved from file: $oldThumbprint"
    
    # You can add additional commands to process the thumbprint
} else {
    # File does not exist, perform another action
    Write-Output "Thumbprint file does not exist. Assuming install needed."
    
    # Add your alternative commands here
    # Example: Log a message, create the file, etc.
}

# If the thumbprint exists and is the same as the old thumbprint, try running a renewal in case it's needed
# Without -Force it won't happen if not needed
# We'll do this separately as we can then take appropriate install action using the block below.
if ($thumbprint -and ($thumbprint -eq $oldThumbprint)) {
	Submit-Renewal

	# Update the thumbprint variable in case it has changed
	$thumbprint = Get-PACertificate -MainDomain $fqdn | Select -ExpandProperty Thumbprint
}

if ($thumbprint -and ($thumbprint -ne $oldThumbprint)) {
	# Thumbprint exists, run additional commands
	Write-Output "Thumbprint exists: $thumbprint"

	# Get the path to the RDP server and update the certificate
	$path = (Get-WmiObject -class "Win32_TSGeneralSetting" -Namespace root\cimv2\terminalservices -Filter "TerminalName='RDP-tcp'").__path
	Set-WmiInstance -Path $path -argument @{SSLCertificateSHA1Hash=$thumbprint}

	# Update the HTTPS lisentener for WinRM assuming it already exists
	Set-WSManInstance -ResourceURI winrm/config/Listener -SelectorSet @{Address="*"; Transport="HTTPS"} -ValueSet @{CertificateThumbprint=$thumbprint}

	# Restart the WinRM service
	Restart-Service -Force -Name WinRM

	# Write the current thumbprint to the old thumbprint file
	Set-Content -Path $thumbprintPath -Value $thumbprint -Force
} elseif (-not $thumbprint) {
	Write-Output "No thumbprint found for the specified domain. Assuming initial setup required."	
	# Generate a new ACME certificate
	New-PACertificate $fqdn -AcceptTOS -Contact $contactEmail -Plugin $pluginName -PluginArgs $pArgs -Install

	# Get the thumbprint of the certificate just installed and write it to the old thumbprint store file
	$thumbprint = Get-PACertificate -MainDomain $fqdn | Select -ExpandProperty Thumbprint
	# Write the current thumbprint to the old thumbprint file
	Set-Content -Path $thumbprintPath -Value $thumbprint -Force

	# Get the current HTTPS listener if it exists
	$httpsListener = Get-WSManInstance -ResourceURI winrm/config/Listener -Enumerate | Where-Object { $_.Transport -eq "HTTPS" }

	# Check if an HTTPS listener exists
	if (-not $httpsListener) {
		# No HTTPS listener exists, so create a new one
		# Set up a new WinRM listener on HTTPS - note this will fail if it's already set up
		New-Item -Path WSMan:\Localhost\Listener -Transport HTTPS -Address * -CertificateThumbprint $thumbprint -Force

		# Enable basic auth
		Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true

		# Restart the WinRM service
		Restart-Service -Force -Name WinRM

		Write-Output "New HTTPS WSMan listener created."
	} else {
		Write-Output "An HTTPS WSMan listener already exists - updating."

		# Update the HTTPS lisentener for WinRM assuming it already exists
		Set-WSManInstance -ResourceURI winrm/config/Listener -SelectorSet @{Address="*"; Transport="HTTPS"} -ValueSet @{CertificateThumbprint=$thumbprint}

		# Enable basic auth
		Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true

		# Restart the WinRM service
		Restart-Service -Force -Name WinRM
	}
	# Check if a firewall rule exists for local port 5986, is inbound, and is an allow rule
	$rule = Get-NetFirewallRule | Where-Object {
  		($_ | Get-NetFirewallPortFilter | Where-Object { $_.LocalPort -eq 5986 }) -and
		($_.Direction -eq 'Inbound') -and
		($_.Action -eq 'Allow')
	}

	if ($rule) {
    		Write-Output "An inbound allow firewall rule exists for local port 5986."
	} else {
    		Write-Output "No inbound allow firewall rule exists for local port 5986 - creating."
		# Open the firewall port for WinRM over HTTPS
		New-NetFirewallRule -Name "Allow WinRM HTTPS" -DisplayName "Allow WinRM HTTPS" -Protocol TCP -LocalPort 5986 -Action Allow -Direction Inbound
	}

	# Simply assume we've got RDP enabled - more complex configurations are out of scope
	# Get the path to the RDP server and update the certificate
	$path = (Get-WmiObject -class "Win32_TSGeneralSetting" -Namespace root\cimv2\terminalservices -Filter "TerminalName='RDP-tcp'").__path
	Set-WmiInstance -Path $path -argument @{SSLCertificateSHA1Hash=$thumbprint}
	
} elseif ($thumbprint -eq $oldThumbprint) {
	Write-Output "Old and current thumbprints are the same - no installation required"
}