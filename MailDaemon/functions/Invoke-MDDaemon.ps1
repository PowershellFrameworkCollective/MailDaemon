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
		if (-not (Test-Path $script:_Config.MailPickupPath))
		{
			$null = New-Item -Path $script:_Config.MailPickupPath -ItemType Directory
		}
		if (-not (Test-Path $script:_Config.MailSentPath))
		{
			$null = New-Item -Path $script:_Config.MailSentPath -ItemType Directory
		}
	}
	process
	{
		#region Send mails
		foreach ($item in (Get-ChildItem -Path $script:_Config.MailPickupPath))
		{
			$email = Import-Clixml -Path $item.FullName
			# Skip emails that should not yet be processed
			if ($email.NotBefore -gt (Get-Date)) { continue }

			# Build email parameters
			$parameters = @{
				SmtpServer = $script:_Config.SmtpServer
				Encoding = ([System.Text.Encoding]::UTF8)
				ErrorAction = 'Stop'
			}
			if ($email.To) { $parameters["To"] = $email.To }
			else { $parameters["To"] = $script:_Config.RecipientDefault }
			if ($email.From) { $parameters["From"] = $email.From }
			else { $parameters["From"] = $script:_Config.SenderDefault }
			if ($email.Cc) { $parameters["Cc"] = $email.Cc }
			if ($email.Subject) { $parameters["Subject"] = $email.Subject }
			else { $parameters["Subject"] = "<no subject>" }
			if ($email.Body) { $parameters["Body"] = $email.Body }
			if ($null -ne $email.BodyAsHtml) { $parameters["BodyAsHtml"] = $email.BodyAsHtml }
			if ($email.Attachments) { $parameters["Attachments"] = $email.Attachments }
			if ($script:_Config.SenderCredentialPath) { $parameters["Credential"] = Import-Clixml $script:_Config.SenderCredentialPath }

			try { Send-MailMessage @parameters }
			catch
			{
				Write-Log -Type Error -Message "Failed to send email! $_"
				continue
			}
			Write-Log -Message "Email sent for $($email.Taskname)"

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
			try { Move-Item -Path $item.FullName -Destination $script:_Config.MailSentPath -Force -ErrorAction Stop }
			catch
			{
				Write-Log -Type Error -Message "Failed to move email to sent folder: $_"
			}
		}
		#endregion Send mails
	}
	end
	{
		#region Cleanup expired mails
		foreach ($item in (Get-ChildItem -Path $script:_Config.MailSentPath))
		{
			if ($item.LastWriteTime -lt (Get-Date).Add((-1 * ([timespan]$script:_Config.MailSentRetention))))
			{
				Remove-Item $item.FullName
			}
		}
		#endregion Cleanup expired mails
	}
}
