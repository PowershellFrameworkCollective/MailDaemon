function Invoke-MDDaemon
{
	<#
		.SYNOPSIS
			Processes the email queue and sends emails

		.DESCRIPTION
			Processes the email queue and sends emails.
			Should be scheduled using a scheduled task.
			Recommended Setting:
			- Launch on boot with delay
			- Launch on Midnight
			- Repeat every 30 minutes for one day

		.EXAMPLE
			PS C:\> Invoke-MDDaemon

			Processes the email queue and sends emails
	#>
	[CmdletBinding()]
	Param (
	
	)
	
	begin
	{
		if (-not (Test-Path (Get-PSFConfigValue -FullName 'MailDaemon.Daemon.MailPickupPath')))
		{
			$null = New-Item -Path (Get-PSFConfigValue -FullName 'MailDaemon.Daemon.MailPickupPath') -ItemType Directory
		}
		if (-not (Test-Path (Get-PSFConfigValue -FullName 'MailDaemon.Daemon.MailSentPath')))
		{
			$null = New-Item -Path (Get-PSFConfigValue -FullName 'MailDaemon.Daemon.MailSentPath') -ItemType Directory
		}
	}
	process
	{
		#region Send mails
		foreach ($item in (Get-ChildItem -Path (Get-PSFConfigValue -FullName 'MailDaemon.Daemon.MailPickupPath')))
		{
			$email = Import-Clixml -Path $item.FullName
			# Skip emails that should not yet be processed
			if ($email.NotBefore -gt (Get-Date)) { continue }

			# Build email parameters
			$parameters = @{
				SmtpServer = Get-PSFConfigValue -FullName 'MailDaemon.Daemon.SmtpServer'
				Encoding = ([System.Text.Encoding]::UTF8)
				ErrorAction = 'Stop'
			}
			if ($email.To) { $parameters["To"] = $email.To }
			else { $parameters["To"] = Get-PSFConfigValue -FullName 'MailDaemon.Daemon.RecipientDefault' }
			if ($email.From) { $parameters["From"] = $email.From }
			else { $parameters["From"] = Get-PSFConfigValue -FullName 'MailDaemon.Daemon.SenderDefault' }
			if ($email.Cc) { $parameters["Cc"] = $email.Cc }
			if ($email.Subject) { $parameters["Subject"] = $email.Subject }
			else { $parameters["Subject"] = "<no subject>" }
			if ($email.Body) { $parameters["Body"] = $email.Body }
			if ($null -ne $email.BodyAsHtml) { $parameters["BodyAsHtml"] = $email.BodyAsHtml }
			if ($email.Attachments) { $parameters["Attachments"] = $email.Attachments }
			if ($script:_Config.SenderCredentialPath) { $parameters["Credential"] = Import-Clixml (Get-PSFConfigValue -FullName 'MailDaemon.Daemon.SenderCredentialPath') }
			
			Write-PSFMessage -Level Verbose -String 'Invoke-MDDaemon.SendMail.Start' -StringValues @($email.Taskname, $parameters['Subject'], $parameters['From'], ($parameters['To'] -join ",")) -Target $email.Taskname
			try { Send-MailMessage @parameters }
			catch { Stop-PSFFunction -String 'Invoke-MDDaemon.SendMail.Failed' -StringValues $email.Taskname -ErrorRecord $_ -Continue -Target $email.Taskname }
			Write-PSFMessage -Level Verbose -String 'Invoke-MDDaemon.SendMail.Success' -StringValues $email.Taskname -Target $email.Taskname

			# Remove attachments only if ordered and maail was sent successfully
			if ($email.Attachments -and $email.RemoveAttachments)
			{
				foreach ($attachment in $email.Attachments)
				{
					Remove-Item $attachment -Force
				}
			}

			# Update the timestamp (the timeout for deletion uses this) and move it to the sent items folder
			$item.LastWriteTime = Get-Date
			try { Move-Item -Path $item.FullName -Destination (Get-PSFConfigValue -FullName 'MailDaemon.Daemon.MailSentPath') -Force -ErrorAction Stop }
			catch
			{
				Write-PSFMessage -Level Warning -String 'Invoke-MDDaemon.ManageSuccessJob.Failed' -StringValues $email.Taskname -Target $email.Taskname
			}
		}
		#endregion Send mails
	}
	end
	{
		#region Cleanup expired mails
		foreach ($item in (Get-ChildItem -Path (Get-PSFConfigValue -FullName 'MailDaemon.Daemon.MailSentPath')))
		{
			if ($item.LastWriteTime -lt (Get-Date).AddTicks((-1 * (Get-PSFConfigValue -FullName 'MailDaemon.Daemon.MailSentRetention').Ticks)))
			{
				Remove-Item $item.FullName
			}
		}
		#endregion Cleanup expired mails
	}
}
