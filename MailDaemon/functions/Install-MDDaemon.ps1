function Install-MDDaemon {
	<#
	.SYNOPSIS
		Configures a computer for using the Mail Daemon
	
	.DESCRIPTION
		Configures a computer for using the Mail Daemon.
		This can include:
		- Installing the scheduled task
		- Creating folder and permission structure
		- Setting up the mail daemon configuration
		
		This action can be performed both locally or against remote computers
	
	.PARAMETER ComputerName
		The computer(s) to work against.
		Defaults to localhost, but can be used to install the module and set up the task across a wide range of computers.
	
	.PARAMETER Credential
		The credentials to use when connecting to computers.
	
	.PARAMETER NoTask
		Create the scheduled task.
	
	.PARAMETER TaskUser
		The credentials of the user the scheduled task will be executed as.
	
	.PARAMETER PickupPath
		The folder in which emails are queued for delivery.
	
	.PARAMETER SentPath
		The folder in which emails that were successfully sent are stored for a specified time before being deleted.

	.PARAMETER FailedPath
		The path where mails that could repeatedly not be sent are moved to.
	
	.PARAMETER DaemonUser
		The user to grant permissions needed to function as the Daemon account.
		This grants read/write access to all working folders.
	
	.PARAMETER WriteUser
		The user/group to grant permissions to needed to queue email.
		This grants write-only access to the mail inbox.
	
	.PARAMETER MailSentRetention
		The time to keep successfully sent emails around.

	.PARAMETER MailAbandonThreshold
		How long we attempt to send an email before abandoning it and moving it to -FailedPath.

	.PARAMETER MailFailedRetention
		How long we keep an abandoned email around before removing it entirely.
	
	.PARAMETER SmtpServer
		The mailserver to use for sending emails.
	
	.PARAMETER SenderDefault
		The default email address to use as sender.
		This is used for mails queued by a task that did not specify a sender.
	
	.PARAMETER SenderCredential
		The credentials to use to send emails.
		Will be stored in an encrypted file that can only be opened by the taskuser and from the computer it is installed on.
	
	.PARAMETER RecipientDefault
		Default email address to send the email to, if the individual script queuing the email does not specify one.
	
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

	.PARAMETER NoLogging
		Disables logging.
		Unless specified, this setup step will also prepare the windows eventlog by creating a dedicated eventlog for MailDaemon.

	.EXAMPLE
		PS C:\> Install-MDDaemon -ComputerName DC1, DC2, DC3 -TaskUser $cred -DaemonUser "DOMAIN\MailDaemon" -SmtpServer 'mail.domain.org' -SenderDefault 'daemon@domain.org' -RecipientDefault 'helpdesk-t2@domain.org'
		
		Configures the mail daemon NoTask on the servers DC1, DC2 and DC3
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true)]
		[PSFComputer[]]
		$ComputerName = $env:COMPUTERNAME,
		
		[PSCredential]
		$Credential,
		
		[switch]
		$NoTask,
		
		[PSCredential]
		$TaskUser,
		
		[string]
		$PickupPath,
		
		[string]
		$SentPath,

		[string]
		$FailedPath,
		
		[string]
		$DaemonUser,
		
		[string[]]
		$WriteUser,
		
		[Timespan]
		$MailSentRetention,

		[Timespan]
		$MailAbandonThreshold,
		
		[Timespan]
		$MailFailedRetention,
		
		[string]
		$SmtpServer,
		
		[string]
		$SenderDefault,
		
		[PSCredential]
		$SenderCredential,
		
		[string]
		$RecipientDefault,

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

		[switch]
		$NoLogging
	)
	
	begin {
		#region Repetitions (ugly)
		# Specifying repetitions directly in the commandline is ugly.
		# It ignores explicit settings and requires copying the repetition object from another task.
		# Since we do not want to rely on another task being available, instead I chose to store an object in its XML form.
		# By deserializing this back into an object at runtime we can carry an object in scriptcode.
		$object = @'
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
<Obj RefId="0">
	<TN RefId="0">
	<T>Microsoft.Management.Infrastructure.CimInstance#Root/Microsoft/Windows/TaskScheduler/MSFT_TaskRepetitionPattern</T>
	<T>Microsoft.Management.Infrastructure.CimInstance#MSFT_TaskRepetitionPattern</T>
	<T>Microsoft.Management.Infrastructure.CimInstance</T>
	<T>System.Object</T>
	</TN>
	<ToString>MSFT_TaskRepetitionPattern</ToString>
	<Props>
	<S N="Duration">P1D</S>
	<S N="Interval">PT30M</S>
	<B N="StopAtDurationEnd">false</B>
	<Nil N="PSComputerName" />
	</Props>
	<MS>
	<Obj N="__ClassMetadata" RefId="1">
		<TN RefId="1">
		<T>System.Collections.ArrayList</T>
		<T>System.Object</T>
		</TN>
		<LST>
		<Obj RefId="2">
			<MS>
			<S N="ClassName">MSFT_TaskRepetitionPattern</S>
			<S N="Namespace">Root/Microsoft/Windows/TaskScheduler</S>
			<S N="ServerName">C0020127</S>
			<I32 N="Hash">-1401671928</I32>
			<S N="MiXml">&lt;CLASS NAME="MSFT_TaskRepetitionPattern"&gt;&lt;PROPERTY NAME="Duration" TYPE="string"&gt;&lt;/PROPERTY&gt;&lt;PROPERTY NAME="Interval" TYPE="string"&gt;&lt;/PROPERTY&gt;&lt;PROPERTY NAME="StopAtDurationEnd" TYPE="boolean"&gt;&lt;/PROPERTY&gt;&lt;/CLASS&gt;</S>
			</MS>
		</Obj>
		</LST>
	</Obj>
	</MS>
</Obj>
</Objs>
'@
		$repetitionObject = [System.Management.Automation.PSSerializer]::Deserialize($object)
		#endregion Repetitions (ugly)
		
		#region Setup Task Configuration
		if (-not $NoTask) {
			$action = New-ScheduledTaskAction -Execute powershell.exe -Argument "-NoProfile -Command Invoke-MDDaemon"
			if ($NoLogging) { $action = New-ScheduledTaskAction -Execute powershell.exe -Argument "-NoProfile -Command Invoke-MDDaemon -NoLogging" }
			$triggers = @()
			$triggers += New-ScheduledTaskTrigger -AtStartup -RandomDelay "00:15:00"
			$triggers += New-ScheduledTaskTrigger -At "00:00:00" -Daily
			
			if ($TaskUser) { $principal = New-ScheduledTaskPrincipal -UserId $TaskUser.UserName -LogonType Interactive }
			else { $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType Interactive }
			
			$taskItem = New-ScheduledTask -Action $action -Principal $principal -Trigger $triggers -Description "Mail Daemon task, checks for emails to send at a specified interval. Uses the internal MailDaemon module."
			$taskItem.Author = Get-PSFConfigValue -FullName 'MailDaemon.Task.Author' -Fallback "$($env:USERDOMAIN) IT Department"
			$taskItem.Triggers[1].Repetition = $repetitionObject
			
			$parametersRegister = @{
				TaskName    = 'MailDaemon'
				InputObject = $taskItem
			}
			if ($TaskUser) {
				$parametersRegister["User"] = $TaskUser.UserName
				$parametersRegister["Password"] = $TaskUser.GetNetworkCredential().Password
			}
		}
		#endregion Setup Task Configuration
		
		#region Preparing Parameters
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include 'PickupPath', 'SentPath', 'FailedPath', 'MailSentRetention', 'MailAbandonThreshold', 'MailFailedRetention', 'SmtpServer', 'SenderDefault', 'RecipientDefault', 'UseSSL', 'ClientID', 'TenantID', 'Identity', 'Federated', 'CertificateThumbprint', 'CertificateName'
		if ($parameters.Federated -or $parameters.Identity -or $parameters.ClientID) { $parameters.Type = 'Graph' }
		
		$paramMainInstallCall = @{
			ArgumentList = $parameters
			Credential   = $Credential
		}
		#endregion Preparing Parameters
		
		#region The Main Setup Scriptblock
		$paramMainInstallCall["ScriptBlock"] = {
			param (
				$Parameters
			)
			
			Import-Module -Name PSFramework
			Import-Module -Name MailDaemon
			
			Set-MDDaemon @Parameters
			
			#region Set file permissions
			if (-not (Test-Path (Get-PSFConfigValue -FullName 'MailDaemon.Daemon.MailPickupPath'))) { $null = New-Item (Get-PSFConfigValue -FullName 'MailDaemon.Daemon.MailPickupPath') -Force -ItemType Directory }
			if (-not (Test-Path (Get-PSFConfigValue -FullName 'MailDaemon.Daemon.MailSentPath'))) { $null = New-Item (Get-PSFConfigValue -FullName 'MailDaemon.Daemon.MailSentPath') -Force -ItemType Directory }
			
			if ($Parameters.DaemonUser) { Update-MDFolderPermission -DaemonUser $Parameters.DaemonUser }
			if ($Parameters.WriteUser) { Update-MDFolderPermission -WriteUser $Parameters.WriteUser }
			#endregion Set file permissions
		}
		#endregion The Main Setup Scriptblock
	}
	
	process {
		#region Ensure Modules are installed
		$testResults = Test-Module -ComputerName $ComputerName -Credential $Credential -Module @{
			MailDaemon  = $script:ModuleVersion
			PSFramework = (Get-Module -Name PSFramework).Version
		}
		
		$failedTests = $testResults | Where-Object Success -EQ $false
		
		if ($failedTests) {
			$grouped = $failedTests | Group-Object Name
			foreach ($groupSet in $grouped) {
				Copy-Module -ModuleName (Get-Module $groupSet.Name).ModuleBase -ToComputer $groupSet.Group.ComputerName
			}
		}
		#endregion Ensure Modules are installed
		
		$paramMainInstallCall['ComputerName'] = $ComputerName
		
		Invoke-PSFCommand @paramMainInstallCall
		
		#region Securely store credentials
		if ($PSBoundParameters.ContainsKey('SenderCredential')) {
			$parametersSave = @{
				ComputerName     = $ComputerName
				TargetCredential = $SenderCredential
				Path             = 'C:\ProgramData\PowerShell\MailDaemon\senderCredentials.clixml'
			}
			if ($Credential) { $parametersSave['Credential'] = $Credential }
			if ($TaskUser) { $parametersSave['AccessAccount'] = $TaskUser }
			Save-MDCredential @parametersSave
			
			$parametersInvoke = @{ ComputerName = $ComputerName }
			if ($Credential) { $parametersInvoke['Credential'] = $Credential }
			Invoke-PSFCommand @parametersInvoke -ScriptBlock {
				Set-MDDaemon -SenderCredentialPath "C:\ProgramData\PowerShell\MailDaemon\senderCredentials.clixml"
			}
		}
		#endregion Securely store credentials

		#region Setup Logging
		if (-not $NoLogging) {
			Invoke-PSFCommand @parametersInvoke -ScriptBlock {
				if ($PSVersionTable.PSVersion.Major -gt 5 -and -not $IsWindows) { return }
				Set-PSFLoggingProvider -Name eventlog -InstanceName MailDaemonInvoke -LogName MailDaemon -Source MailDaemon -Enabled $true -Wait
				Write-PSFMessage -Message "Setting up MailDaemon logging"
				Disable-PSFLoggingProvider -Name eventlog -InstanceName MailDaemonInvoke
			}
		}
		#endregion Setup Logging
		
		#region Setup Task
		if (-not $NoTask) {
			Invoke-PSFCommand @parametersInvoke -ScriptBlock {
				param ($ParametersRegister)

				$taskObject = Get-ScheduledTask -TaskName $ParametersRegister.TaskName -ErrorAction Ignore
				if ($taskObject) { $taskObject | Unregister-ScheduledTask }

				$null = Register-ScheduledTask @ParametersRegister
			} -ArgumentList $parametersRegister
		}
		#endregion Setup Task
	}
}