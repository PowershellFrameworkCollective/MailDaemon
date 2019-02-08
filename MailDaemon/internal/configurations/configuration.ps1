# Default configuration
$script:_Config = @{
    MailPickupPath = "$($env:ProgramData)\PowerShell\MailDaemon\Pickup"
    MailSentPath = "$($env:ProgramData)\PowerShell\MailDaemon\Sent"
    MailSentRetention = (New-TimeSpan -Days 7)
    SmtpServer = "mail.domain.com"
    SenderDefault = 'maildaemon@domain.com'
    SenderCredentialPath = ''
    RecipientDefault = 'support@domain.com'
}

# Load from export using Export-Clixml (high maintainability using PowerShell)
if (Test-Path "$($env:ProgramData)\PowerShell\MailDaemon\config.clixml")
{
    $data = Import-Clixml "$($env:ProgramData)\PowerShell\MailDaemon\config.clixml"
    foreach ($property in $data.PSObject.Properties)
    {
        $script:_Config[$property.Name] = $property.Value
    }
}

# Load from json file if possible (high readability)
if (Test-Path "$($env:ProgramData)\PowerShell\MailDaemon\config.json")
{
    $data = Get-Content "$($env:ProgramData)\PowerShell\MailDaemon\config.json" | ConvertFrom-Json
    foreach ($property in $data.PSObject.Properties)
    {
        $script:_Config[$property.Name] = $property.Value
    }
}