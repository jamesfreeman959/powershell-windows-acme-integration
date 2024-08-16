$contactEmail = 'xxx@example.com'
$pArgs = @{
    CFAuthEmail = 'xxx@example.com'
    CFAuthKeySecure = ConvertTo-SecureString 'xxxxxxxxx' -AsPlainText -Force
}
$pluginName = 'Cloudflare'