function Set-MDDaemon {
	<#
	.SYNOPSIS
		Configures the Daemon settings on the target computer(s)
	
	.DESCRIPTION
		Command that governs the Mail Daemon settings.
	
	.PARAMETER PickupPath
		The folder in which emails are queued for delivery.
	
	.PARAMETER SentPath
		The folder in which emails that were successfully sent are stored for a specified time before being deleted.

	.PARAMETER FailedPath
		The path where mails that could repeatedly not be sent are moved to.
	
	.PARAMETER MailSentRetention
		The time to keep successfully sent emails around.

	.PARAMETER MailAbandonThreshold
		How long we attempt to send an email before abandoning it and moving it to -FailedPath.

	.PARAMETER MailFailedRetention
		How long we keep an abandoned email around before removing it entirely.

	.PARAMETER Type
		In what fundamental way should emails be sent?
		- SMTP: Via classic SMTP relay (authenticated or not so)
		- Graph: Via Graph API (using Application authentication)
		The different modes need different configuration parameters.
	
	.PARAMETER SmtpServer
		The mailserver to use for sending emails.
	
	.PARAMETER SenderDefault
		The default email address to use as sender.
		This is used for mails queued by a task that did not specify a sender.
	
	.PARAMETER RecipientDefault
		Default email address to send the email to, if the individual script queuing the email does not specify one.
	
	.PARAMETER SenderCredentialPath
		The path to where the credentials file can be found, that should be used by the daemon.

	.PARAMETER UseSSL
		Use SSL for sending emails.

	.PARAMETER ClientID
		The ClientID of the Application to use for sending emails via Graph API.

	.PARAMETER TenantID
		The TenantID of the Application to use for sending emails via Graph API.

	.PARAMETER Identity
		When authenticating to Entra for sending emails via Graph API, use the current Managed Identity to authenticate.

	.PARAMETER Federated
		When authenticating to Entra for sending emails via Graph API, use Federated Credentials to authenticate.
		This uses the current Managed Identity to get a token they can use to authenticate to the application with the actual permissions.

	.PARAMETER CertificateThumbprint
		When authenticating to Entra for sending emails via Graph API, use the certificate with the specified thumbprint.
		The certificate must be stored in one of the local certificate stores.

	.PARAMETER CertificateName
		When authenticating to Entra for sending emails via Graph API, use the newest certificate with the specified subject.
		The certificate must be stored in one of the local certificate stores.
	
	.PARAMETER ComputerName
		The computer(s) to work against.
		Defaults to localhost, but can be used to update the module settings across a wide range of computers.
	
	.PARAMETER Credential
		The credentials to use when connecting to computers.
	
	.EXAMPLE
		PS C:\> Set-MDDaemon -PickupPath 'C:\MailDaemon\Pickup'
		
		Updates the configuration to now pickup incoming emails from 'C:\MailDaemon\Pickup'.
		Will not move pending email jobs.
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "")]
	[CmdletBinding()]
	param (
		[string]
		$PickupPath,
		
		[string]
		$SentPath,

		[string]
		$FailedPath,
		
		[Timespan]
		$MailSentRetention,

		[Timespan]
		$MailAbandonThreshold,
		
		[Timespan]
		$MailFailedRetention,

		[ValidateSet('Graph', 'Smtp')]
		[string]
		$Type,
		
		[string]
		$SmtpServer,
		
		[string]
		$SenderDefault,
		
		[string]
		$RecipientDefault,
		
		[string]
		$SenderCredentialPath,

		[switch]
		$UseSSL,

		[string]
		$ClientID,

		[string]
		$TenantID,

		[switch]
		$Identity,

		[switch]
		$Federated,

		[string]
		$CertificateThumbprint,

		[string]
		$CertificateName,
		
		[Parameter(ValueFromPipeline = $true)]
		[PSFComputer[]]
		$ComputerName = $env:COMPUTERNAME,
		
		[PSCredential]
		$Credential
	)
	
	begin {
		#region Configuration Script
		$configurationScript = {
			param (
				$Parameters
			)
			
			# Import module so settings are initialized
			if (-not (Get-Module MailDaemon)) { Import-Module MailDaemon }
			
			foreach ($key in $Parameters.Keys) {
				Write-PSFMessage -String 'Set-MDDaemon.UpdateSetting' -StringValues $key, $Parameters[$key]
				switch ($key) {
					'PickupPath' {
						Set-PSFConfig -Module MailDaemon -Name 'Daemon.MailPickupPath' -Value $Parameters[$key]
						if (-not (Test-Path $Parameters[$key])) { $null = New-Item $Parameters[$key] -Force -ItemType Directory }
					}
					'SentPath' {
						Set-PSFConfig -Module MailDaemon -Name 'Daemon.MailSentPath' -Value $Parameters[$key]
						if (-not (Test-Path $Parameters[$key])) { $null = New-Item $Parameters[$key] -Force -ItemType Directory }
					}
					'FailedPath' {
						Set-PSFConfig -Module MailDaemon -Name 'Daemon.MailFailedPath' -Value $Parameters[$key]
						if (-not (Test-Path $Parameters[$key])) { $null = New-Item $Parameters[$key] -Force -ItemType Directory }
					}
					'MailSentRetention' { Set-PSFConfig -Module MailDaemon -Name 'Daemon.MailSentRetention' -Value $Parameters[$key] }
					'MailAbandonThreshold' { Set-PSFConfig -Module MailDaemon -Name 'Daemon.MailAbandonThreshold' -Value $Parameters[$key] }
					'MailFailedRetention' { Set-PSFConfig -Module MailDaemon -Name 'Daemon.MailFailedRetention' -Value $Parameters[$key] }
					'SmtpServer' { Set-PSFConfig -Module MailDaemon -Name 'Daemon.SmtpServer' -Value $Parameters[$key] }
					'SenderDefault' { Set-PSFConfig -Module MailDaemon -Name 'Daemon.SenderDefault' -Value $Parameters[$key] }
					'SenderCredentialPath' { Set-PSFConfig -Module MailDaemon -Name 'Daemon.SenderCredentialPath' -Value $Parameters[$key] }
					'RecipientDefault' { Set-PSFConfig -Module MailDaemon -Name 'Daemon.RecipientDefault' -Value $Parameters[$key] }
					'UseSSL' { Set-PSFConfig -Module MailDaemon -Name 'Daemon.UseSSL' -Value $Parameters[$key].ToBool() }
					'Type' { Set-PSFConfig -Module MailDaemon -Name 'Daemon.Type' -Value $Parameters[$key] }
					'ClientID' { Set-PSFConfig -Module MailDaemon -Name 'Daemon.Graph.ClientID' -Value $Parameters[$key] }
					'TenantID' { Set-PSFConfig -Module MailDaemon -Name 'Daemon.Graph.TenantID' -Value $Parameters[$key] }
					'Identity' { Set-PSFConfig -Module MailDaemon -Name 'Daemon.Graph.Identity' -Value $Parameters[$key] }
					'Federated' { Set-PSFConfig -Module MailDaemon -Name 'Daemon.Graph.Federated' -Value $Parameters[$key] }
					'CertificateThumbprint' { Set-PSFConfig -Module MailDaemon -Name 'Daemon.Graph.CertificateThumbprint' -Value $Parameters[$key] }
					'CertificateName' { Set-PSFConfig -Module MailDaemon -Name 'Daemon.Graph.CertificateName' -Value $Parameters[$key] }
				}
			}
			
			Get-PSFConfig -Module MailDaemon -Name Daemon.* | Where-Object Unchanged -EQ $false | Register-PSFConfig -Scope SystemDefault
		}
		#endregion Configuration Script
		
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Exclude ComputerName, Credential
		$connect = $PSBoundParameters | ConvertTo-PSFHashtable -Include ComputerName, Credential
	}
	process {
		#region Modules must be installed and current
		if ($moduleResult = Test-Module @connect -Module @{
				MailDaemon  = $script:ModuleVersion
				PSFramework = (Get-Module -Name PSFramework).Version
			} | Where-Object Success -EQ $false) {
			Stop-PSFFunction -String 'General.ModuleMissing' -StringValues ($moduleResult.ComputerName -join ", ") -EnableException $true -Cmdlet $PSCmdlet
		}
		#endregion Modules must be installed and current
		
		Write-PSFMessage -String 'Set-MDDaemon.UpdatingSettings' -StringValues ($ComputerName -join ", ")
		Invoke-PSFCommand @connect -ScriptBlock $configurationScript -ArgumentList $parameters
	}
}