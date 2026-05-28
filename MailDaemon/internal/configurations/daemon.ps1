Set-PSFConfig -Module 'MailDaemon' -Name 'Daemon.MailPickupPath' -Value "$(Get-PSFPath -Name ProgramData)\PowerShell\MailDaemon\Pickup" -Initialize -Validation 'string' -SimpleExport -Description "The folder from which the daemon will pickup email tasks."
Set-PSFConfig -Module 'MailDaemon' -Name 'Daemon.MailSentPath' -Value "$(Get-PSFPath -Name ProgramData)\PowerShell\MailDaemon\Sent" -Initialize -Validation 'string' -SimpleExport -Description "The folder into which completed tasks are moved"
Set-PSFConfig -Module 'MailDaemon' -Name 'Daemon.MailFailedPath' -Value "$(Get-PSFPath -Name ProgramData)\PowerShell\MailDaemon\Sent" -Initialize -Validation 'string' -SimpleExport -Description "The folder into which failed tasks are moved"
Set-PSFConfig -Module 'MailDaemon' -Name 'Daemon.MailSentRetention' -Value (New-TimeSpan -Days 7) -Initialize -Validation 'timespan' -SimpleExport -Description "How long sent email tasks are retained"
Set-PSFConfig -Module 'MailDaemon' -Name 'Daemon.MailAbandonThreshold' -Value (New-TimeSpan -Days 14) -Initialize -Validation 'timespan' -SimpleExport -Description "How long we try to send failing tasks, before abandoning them"
Set-PSFConfig -Module 'MailDaemon' -Name 'Daemon.MailFailedRetention' -Value (New-TimeSpan -Days 14) -Initialize -Validation 'timespan' -SimpleExport -Description "How long failed email tasks are retained"
Set-PSFConfig -Module 'MailDaemon' -Name 'Daemon.SenderDefault' -Value "maildaemon@$($env:USERDNSDOMAIN)" -Initialize -Validation 'string' -SimpleExport -Description "The default sending email address."

Set-PSFConfig -Module 'MailDaemon' -Name 'Daemon.Type' -Value 'SMTP' -Initialize -Validation 'MailDaemon.Protocol' -SimpleExport -Description 'The protocol used to send email. Supports either "SMTP" or "Graph". The choice determines what authentication options must be specified.'

# SMTP
Set-PSFConfig -Module 'MailDaemon' -Name 'Daemon.SmtpServer' -Value "mail.$($env:USERDNSDOMAIN)" -Initialize -Validation 'string' -SimpleExport -Description "The mail server to use."
Set-PSFConfig -Module 'MailDaemon' -Name 'Daemon.SenderCredentialPath' -Value '' -Initialize -Validation 'string' -SimpleExport -Description "The path to the credentials to use for authenticated mail sending."
Set-PSFConfig -Module 'MailDaemon' -Name 'Daemon.RecipientDefault' -Value "support@$($env:USERDNSDOMAIN)" -Initialize -Validation 'string' -SimpleExport -Description "The default recipient to receive emails."
Set-PSFConfig -Module 'MailDaemon' -Name 'Daemon.UseSSL' -Value $false -Initialize -Validation 'bool' -SimpleExport -Description "Whether mails should be sent using SSL."

# Graph
Set-PSFConfig -Module 'MailDaemon' -Name 'Daemon.Graph.ClientID' -Value $null -Initialize -Validation guid -SimpleExport -Description 'The client ID of the Application to use for authentication to graph.'
Set-PSFConfig -Module 'MailDaemon' -Name 'Daemon.Graph.TenantID' -Value $null -Initialize -Validation guid -SimpleExport -Description 'The tenant ID of the Application to use for authentication to graph.'
Set-PSFConfig -Module 'MailDaemon' -Name 'Daemon.Graph.CertificateThumbprint' -Value '' -Initialize -Validation string -SimpleExport -Description 'Authenticate using the specified certificate (by thumbprint). The account must have read access to the private key.'
Set-PSFConfig -Module 'MailDaemon' -Name 'Daemon.Graph.CertificateName' -Value '' -Initialize -Validation string -SimpleExport -Description 'Authenticate using the specified certificate (by subject). The account must have read access to the private key.'
Set-PSFConfig -Module 'MailDaemon' -Name 'Daemon.Graph.Federated' -Value $false -Initialize -Validation bool -SimpleExport -Description 'Authenticate using Federated Credentials. Generally requires running as admin for access.'
Set-PSFConfig -Module 'MailDaemon' -Name 'Daemon.Graph.Identity' -Value $false -Initialize -Validation bool -SimpleExport -Description 'Authenticate using the Managed Identity of the current environment. Generally requires running as admin for access.'
Set-PSFConfig -Module 'MailDaemon' -Name 'Daemon.Graph.NoAuth' -Value $false -Initialize -Validation bool -SimpleExport -Description 'Do not authenticate at all during processing. This assumes you have handled graph authentication before calling Invoke-MDDaemon - something the default task the module sets up will not do. Use with care'