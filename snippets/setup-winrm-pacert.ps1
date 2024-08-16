$thumbprint = Get-PACertificate -MainDomain $fqdn | Select -ExpandProperty Thumbprint

echo $thumbprint

New-Item -Path WSMan:\Localhost\Listener -Transport HTTPS -Address * -CertificateThumbprint $thumbprint -Force

New-NetFirewallRule -Name "Allow WinRM HTTPS" -DisplayName "Allow WinRM HTTPS" -Protocol TCP -LocalPort 5986 -Action Allow -Direction Inbound
