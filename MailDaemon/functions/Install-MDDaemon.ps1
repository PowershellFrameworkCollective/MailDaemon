function Install-MDDaemon
{
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
		
		.PARAMETER Task
			Create the scheduled task.

		.PARAMETER TaskUser
			The credentials of the user the scheduled task will be executed as.
		
		.PARAMETER PickupPath
			The folder in which emails are queued for delivery.

		.PARAMETER SentPath
			The folder in which emails that were successfully sent are stored for aa specified time before being deleted.

		.PARAMETER DaemonUser
			The user to grant permissions needed to function as the Daemon account.
			This grants read/write access to all working folders.

		.PARAMETER WriteUser
			The user/group to grant permissions to needed to queue emaail.
			This grants write-only access to the mail inbox.
		
		.PARAMETER MailSentRetention
			The time to keep successfully sent emails around.

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

		.EXAMPLE
			PS C:\> Install-MDDaemon -ComputerName DC1, DC2, DC3 -Task -TaskUser $cred -DaemonUser "DOMAIN\MailDaemon" -SmtpServer 'mail.domain.org' -SenderDefault 'daemon@domain.org' -RecipientDefault 'helpdesk-t2@domain.org'

			Configures the mail daemon task on the servers DC1, DC2 and DC3
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	Param (
		[string[]]
		$ComputerName = $env:COMPUTERNAME,

		[switch]
		$Task,

		[PSCredential]
		$TaskUser,

		[string]
		$PickupPath,

		[string]
		$SentPath,

		[string]
		$DaemonUser,

		[string[]]
		$WriteUser,

		[Timespan]
		$MailSentRetention,

		[string]
		$SmtpServer,

		[string]
		$SenderDefault,

		[PSCredential]
		$SenderCredential,

		[string]
		$RecipientDefault
	)
	
	$tempPath = "$($env:TEMP)\$(New-Guid).zip"
	Compress-Archive -Path $script:ModuleRoot\* -DestinationPath $tempPath
	$archiveData = [convert]::ToBase64String([System.IO.File]::ReadAllBytes($tempPath))
	Remove-Item $tempPath

	$parameters = @{}
	foreach ($key in $PSBoundParameters.Keys)
	{
		if ($key -eq "ComputerName") { continue }
		if ($key -eq "Task") { continue }
		if ($key -eq "TaskUser") { continue }
		if ($key -eq "SenderCredential") { continue }
		$parameters[$key] = $PSBoundParameters[$key]
	}

	$invokeCommandParameters = @{
		ArgumentList = @($parameters, $script:ModuleVersion, $archiveData)
	}
	if ($env:COMPUTERNAME -ne $ComputerName)
	{
		$invokeCommandParameters["ComputerName"] = $ComputerName
	}
	
	#region Scriptblock
	$invokeCommandParameters["ScriptBlock"] = {
		param (
			$Parameters,

			$ModuleVersion,

			$ModuleData
		)

		# Update the module if needed
		$installNeeded = $false
		if ($modules = Get-Module MailDaemon -ListAvailable)
		{
			if (-not ($modules | Where-Object Version -gt $ModuleVersion)) { $installNeeded = $true }
		}
		else { $installNeeded = $true }

		if ($installNeeded)
		{
			$installRoot = "$($env:ProgramFiles)\WindowsPowerShell\Modules"
			if (-not (Test-Path "$($installRoot)\MailDaemon")) { $null = New-Item -Path $installRoot -Name MailDaemon -ItemType Directory -Force }
			$root = New-Item -Path "$($installRoot)\MailDaemon" -Name $ModuleVersion -ItemType Directory -Force
			$tempPath = "$($env:TEMP)\$(New-Guid).zip"
			[System.IO.File]::WriteAllBytes($tempPath, ([convert]::FromBase64String($ModuleData)))
			Expand-Archive -Path $tempPath -DestinationPath $root.FullName -Force
			Remove-Item $tempPath
		}
		
		# Update configuration
		$_Config = @{ SenderCredentialPath = "" }
		if (Test-Path "$($env:ProgramData)\PowerShell\MailDaemon\config.clixml")
		{
			$data = Import-Clixml "$($env:ProgramData)\PowerShell\MailDaemon\config.clixml"
			foreach ($property in $data.PSObject.Properties)
			{
				$_Config[$property.Name] = $property.Value
			}
		}
		foreach ($key in $Parameters.Keys)
		{
			switch ($key)
			{
				'DaemonUser' { continue }
				'WriteUser' { continue }
				default { $_Config[$key] = $Parameters[$key] }
			}
		}
		if (-not (Test-Path "$($env:ProgramData)\PowerShell\MailDaemon"))
		{
			$null = New-Item -Path "$($env:ProgramData)\PowerShell\MailDaemon" -ItemType Directory -Force
		}
		[PSCustomObject]$_Config | Export-Clixml -Path "$($env:ProgramData)\PowerShell\MailDaemon\config.clixml"

		#region Set file permissions
		$_Config = @{
			MailPickupPath = "$($env:ProgramData)\PowerShell\MailDaemon\Pickup"
			MailSentPath = "$($env:ProgramData)\PowerShell\MailDaemon\Sent"
			MailSentRetention = (New-TimeSpan -Days 7)
			SenderCredentialPath = ""
			SmtpServer = "mail.domain.com"
			SenderDefault = 'maildaemon@domain.com'
			RecipientDefault = 'support@domain.com'
		}
		
		# Load from export using Export-Clixml (high maintainability using PowerShell)
		if (Test-Path "$($env:ProgramData)\PowerShell\MailDaemon\config.clixml")
		{
			$data = Import-Clixml "$($env:ProgramData)\PowerShell\MailDaemon\config.clixml"
			foreach ($property in $data.PSObject.Properties)
			{
				$_Config[$property.Name] = $property.Value
			}
		}
		
		# Load from json file if possible (high readability)
		if (Test-Path "$($env:ProgramData)\PowerShell\MailDaemon\config.json")
		{
			$data = Get-Content "$($env:ProgramData)\PowerShell\MailDaemon\config.json" | ConvertFrom-Json
			foreach ($property in $data.PSObject.Properties)
			{
				$_Config[$property.Name] = $property.Value
			}
		}
		if (-not (Test-Path $_Config.MailPickupPath)) {$null = New-Item $_Config.MailPickupPath -Force -ItemType Directory }
		if (-not (Test-Path $_Config.MailSentPath)) {$null = New-Item $_Config.MailSentPath -Force -ItemType Directory }

		if ($Parameters.DaemonUser)
		{
			$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($Parameters.DaemonUser, 'Read, Write', 'Allow')
			$acl = Get-Acl -Path $_Config.MailPickupPath
			$acl.AddAccessRule($rule)
			$acl | Set-Acl -Path $_Config.MailPickupPath
			$acl = Get-Acl -Path $_Config.MailSentPath
			$acl.AddAccessRule($rule)
			$acl | Set-Acl -Path $_Config.MailSentPath
		}
		if ($Parameters.WriteUser)
		{
			$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($Parameters.WriteUser, 'Write', 'Allow')
			$acl = Get-Acl -Path $_Config.MailPickupPath
			$acl.AddAccessRule($rule)
			$acl | Set-Acl -Path $_Config.MailPickupPath
		}
		#endregion Set file permissions
	}
	#endregion Scriptblock

	Invoke-Command @invokeCommandParameters

	if ($PSBoundParameters.ContainsKey('SenderCredential'))
	{
		$parametersSave = @{
			ComputerName = $ComputerName
			Credential = $SenderCredential
			Path = 'C:\ProgramData\PowerShell\MailDaemon\senderCredentials.clixml'
		}
		if ($TaskUser) { $parametersSave['AccessAccount'] = $TaskUser }
		Save-MDCredential @parametersSave

		$parametersInvoke = @{ }
		if ($env:COMPUTERNAME -ne $ComputerName) { $parametersInvoke['ComputerName'] = $ComputerName }
		Invoke-Command @parametersInvoke -ScriptBlock {
			$data = Import-Clixml -Path "$($env:ProgramData)\PowerShell\MailDaemon\config.clixml"
			$data.SenderCredentialPath  = "C:\ProgramData\PowerShell\MailDaemon\senderCredentials.clixml"
			$data | Export-Clixml -Path "$($env:ProgramData)\PowerShell\MailDaemon\config.clixml"
		}
	}

	#region Setup Task
	if ($Task)
	{
		$action = New-ScheduledTaskAction -Execute powershell.exe -Argument "-NoProfile -Command Invoke-MDDaemon"
		$triggers = @()
		$triggers += New-ScheduledTaskTrigger -AtStartup -RandomDelay "00:15:00"
		$triggers += New-ScheduledTaskTrigger -At "00:00:00" -Daily

		if ($TaskUser) { $principal = New-ScheduledTaskPrincipal -UserId $TaskUser.UserName -LogonType Interactive }
		else { $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType Interactive }

		$taskItem = New-ScheduledTask -Action $action -Principal $principal -Trigger $triggers -Description "Mail Daemon task, checks for emails to send at a specified interval. Uses the internal MailDaemon module."
		$taskItem.Author = "Company IT Department"
		
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
		$taskItem.Triggers[1].Repetition = [System.Management.Automation.PSSerializer]::Deserialize($object)
		#endregion Repetitions (ugly)

		$parametersRegister = @{
			TaskName = 'MailDaemon'
			InputObject = $taskItem
		}
		if ($TaskUser)
		{
			$parametersRegister["User"] = $TaskUser.UserName
			$parametersRegister["Password"] = $TaskUser.GetNetworkCredential().Password
		}
		if ($ComputerName -ne $env:COMPUTERNAME)
		{
			$parametersRegister["CimSession"] = $ComputerName
		}
		$null = Register-ScheduledTask @parametersRegister
	}
	#endregion Setup Task
}