$pArgs = @{
    CFAuthEmail = 'xxx@example.com'
    CFAuthKeySecure = ConvertTo-SecureString 'xxxxxxxx' -AsPlainText -Force
}
$fqdn =  [System.Net.DNS]::GetHostByName('').HostName
$email = 'xxxx@example.com'

New-PACertificate $fqdn -AcceptTOS -Contact $email -Plugin Cloudflare -PluginArgs $pArgs -Install
