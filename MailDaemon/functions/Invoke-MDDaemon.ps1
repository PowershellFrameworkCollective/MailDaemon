function Invoke-MDDaemon {
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

		.PARAMETER NoLogging
			Disables Eventlog logging.
			By default, the mail invocation is logged to the Windows Eventlog.

		.EXAMPLE
			PS C:\> Invoke-MDDaemon

			Processes the email queue and sends emails
	#>
	[CmdletBinding()]
	param (
		[switch]
		$NoLogging
	)
	
	begin {
		if (-not (Test-Path (Get-PSFConfigValue -FullName 'MailDaemon.Daemon.MailPickupPath'))) {
			$null = New-Item -Path (Get-PSFConfigValue -FullName 'MailDaemon.Daemon.MailPickupPath') -ItemType Directory
		}
		if (-not (Test-Path (Get-PSFConfigValue -FullName 'MailDaemon.Daemon.MailSentPath'))) {
			$null = New-Item -Path (Get-PSFConfigValue -FullName 'MailDaemon.Daemon.MailSentPath') -ItemType Directory
		}
		$failedPath = Get-PSFConfigValue -FullName 'MailDaemon.Daemon.MailFailedPath'
		$abandonThreshold = Get-PSFConfigValue -FullName 'MailDaemon.Daemon.MailAbandonThreshold'
		if (-not (Test-Path $failedPath)) {
			$null = New-Item -Path $failedPath -ItemType Directory
		}

		if (-not $NoLogging -and ($PSVersionTable.PSVersion.Major -lt 6 -or $IsWindows)) {
			Set-PSFLoggingProvider -Name eventlog -InstanceName MailDaemonInvoke -LogName MailDaemon -Source MailDaemon -Enabled $true -Wait
		}

		$type = Get-PSFConfigValue -FullName 'MailDaemon.Daemon.Type' -Fallback 'Smtp'
		$useSmtp = 'Smtp' -eq $type
		$useGraph = 'Graph' -eq $type
	}
	process {
		trap {
			Write-PSFMessage -Level Warning -String 'Invoke-MDDaemon.Error.General' -ErrorRecord $_
			Disable-PSFLoggingProvider -Name eventlog -InstanceName MailDaemonInvoke
			throw $_
		}

		if ($useGraph) { Connect-MDGraph }
		

		#region Send mails
		foreach ($item in (Get-ChildItem -Path (Get-PSFConfigValue -FullName 'MailDaemon.Daemon.MailPickupPath') -Filter "*.clixml")) {
			$email = Import-PSFClixml -Path $item.FullName
			# Skip emails that should not yet be processed
			if ($email.NotBefore -gt (Get-Date)) { continue }

			# Build email parameters
			$parameters = @{
				ErrorAction = 'Stop'
			}
			
			
			#region General
			if ($email.To) { $parameters["To"] = $email.To }
			else { $parameters["To"] = Get-PSFConfigValue -FullName 'MailDaemon.Daemon.RecipientDefault' }
			if ($email.From) { $parameters["From"] = $email.From }
			else { $parameters["From"] = Get-PSFConfigValue -FullName 'MailDaemon.Daemon.SenderDefault' }
			if ($email.Cc) { $parameters["Cc"] = $email.Cc }
			if ($email.Bcc) { $parameters["Bcc"] = $email.Bcc }
			if ($email.Subject) { $parameters["Subject"] = $email.Subject }
			else { $parameters["Subject"] = "<no subject>" }
			if ($email.Priority) { $parameters["Priority"] = $email.Priority }
			if ($email.Body) { $parameters["Body"] = $email.Body }
			if ($null -ne $email.BodyAsHtml) { $parameters["BodyAsHtml"] = $email.BodyAsHtml }
			if ($email.Attachments) {
				if ($email.AttachmentsBinary) {
					$tempAttachmentParentDir = New-Item (Join-Path $item.Directory $item.BaseName) -Force -ItemType Directory
					$attachmentCounter = 0
					$parameters["Attachments"] = @()
					# Using multiple subfolders to allow for duplicate attachment names
					foreach ($binaryAttachment in $email.AttachmentsBinary) {
						$tempAttachmentDir = New-Item (Join-Path $tempAttachmentParentDir $attachmentCounter) -Force -ItemType Directory
						$tempAttachmentPath = Join-Path $tempAttachmentDir $binaryAttachment.Name
						$null = [System.IO.File]::WriteAllBytes($tempAttachmentPath, $binaryAttachment.Data)
						$parameters["Attachments"] = @($parameters["Attachments"]) + $tempAttachmentPath
						$attachmentCounter = $attachmentCounter + 1
					}
				}
				else {
					$parameters["Attachments"] = $email.Attachments
				}
			}
			#endregion General

			#region Smtp
			if ($useSmtp) {
				$parameters += @{
					SmtpServer = Get-PSFConfigValue -FullName 'MailDaemon.Daemon.SmtpServer'
					Encoding   = [System.Text.Encoding]::UTF8
				}
				if (Get-PSFConfigValue -FullName 'MailDaemon.Daemon.UseSSL' -Fallback $false) { $parameters['UseSSL'] = $true }
				if (Get-PSFConfigValue -FullName 'MailDaemon.Daemon.SenderCredentialPath') { $parameters["Credential"] = Import-Clixml -Path (Get-PSFConfigValue -FullName 'MailDaemon.Daemon.SenderCredentialPath') }

				$sendCommand = Get-Command -Name Send-MailMessage
			}
			#endregion Smtp

			#region Graph
			if ($useGraph) {
				$sendCommand = Get-Command -Name Send-GraphMail
			}
			#endregion Graph
			
			Write-PSFMessage -Level Verbose -String 'Invoke-MDDaemon.SendMail.Start' -StringValues @($email.Taskname, $parameters['Subject'], $parameters['From'], ($parameters['To'] -join ",")) -Target $email.Taskname
			try { & $sendCommand @parameters }
			catch {
				"$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') : $_" | Set-PSFFileContent -Path ($item.FullName -replace '.clixml', '.txt') -Append
				#region Abandon Email if beyond threshold
				if ($item.CreationTime.Add($abandonThreshold) -lt (Get-Date)) {
					Write-PSFMessage -String 'Invoke-MDDaemon.SendMail.Abandon' -StringValues $email.Taskname, $abandonThreshold
					$item.LastWriteTime = Get-Date
					Move-Item -LiteralPath $item.FullName -Destination $failedPath
					Move-Item -LiteralPath ($item.FullName -replace '.clixml', '.txt') -Destination $failedPath
					if ($email.Attachments -and $email.RemoveAttachments) {
						foreach ($attachment in $email.Attachments) {
							Remove-Item $attachment -Force
						}
					}
				}
				# Remove temp deserialized attachments if used
				if ($email.AttachmentsBinary) {
					$null = Remove-Item -Path $tempAttachmentParentDir -Recurse -Force
				}
				
				#endregion Abandon Email if beyond threshold
				Stop-PSFFunction -String 'Invoke-MDDaemon.SendMail.Failed' -StringValues $email.Taskname -ErrorRecord $_ -Continue -Target $email.Taskname
			}
			Write-PSFMessage -Level Verbose -String 'Invoke-MDDaemon.SendMail.Success' -StringValues $email.Taskname -Target $email.Taskname

			# Remove attachments only if ordered and mail was sent successfully
			if ($email.Attachments -and $email.RemoveAttachments) {
				foreach ($attachment in $email.Attachments) {
					Remove-Item $attachment -Force
				}
			}
			# Remove temp deserialized attachments if used
			if ($email.AttachmentsBinary) {
				$null = Remove-Item -Path $tempAttachmentParentDir -Recurse -Force
			}

			# Update the timestamp (the timeout for deletion uses this) and move it to the sent items folder
			$item.LastWriteTime = Get-Date
			try { Move-Item -Path $item.FullName -Destination (Get-PSFConfigValue -FullName 'MailDaemon.Daemon.MailSentPath') -Force -ErrorAction Stop }
			catch {
				Write-PSFMessage -Level Warning -String 'Invoke-MDDaemon.ManageSuccessJob.Failed' -StringValues $email.Taskname -Target $email.Taskname
			}
		}
		#endregion Send mails

		Disable-PSFLoggingProvider -Name eventlog -InstanceName MailDaemonInvoke
	}
	end {
		#region Cleanup expired mails
		$sentRetention = Get-PSFConfigValue -FullName 'MailDaemon.Daemon.MailSentRetention'
		foreach ($item in (Get-ChildItem -Path (Get-PSFConfigValue -FullName 'MailDaemon.Daemon.MailSentPath'))) {
			if ($item.LastWriteTime.Add($sentRetention) -lt (Get-Date)) {
				Remove-Item $item.FullName
			}
		}

		$failedRetention = Get-PSFConfigValue -FullName 'MailDaemon.Daemon.MailFailedRetention'
		foreach ($item in (Get-ChildItem -Path $failedPath)) {
			if ($item.LastWriteTime.Add($failedRetention) -lt (Get-Date)) {
				Remove-Item $item.FullName
			}
		}
		#endregion Cleanup expired mails
	}
}
