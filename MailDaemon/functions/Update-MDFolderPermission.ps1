function Update-MDFolderPermission
{
<#
	.SYNOPSIS
		Assigns permissions for the mail daemon working folders.
	
	.DESCRIPTION
		Assigns permissions for the mail daemon working folders.
		Enables simple assignment of privileges in case regular accounts need to write to protected pickup paths and helps implementing least privilege.
	
	.PARAMETER ComputerName
		The computer(s) to work against.
		Defaults to localhost.
	
	.PARAMETER Credential
		The credentials to use when connecting to computers.
	
	.PARAMETER DaemonUser
		The user to grant the necessary access to manage submitted mail items.
	
	.PARAMETER WriteUser
		Users that should be able to submit mails.
	
	.PARAMETER Confirm
		If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.
	
	.PARAMETER WhatIf
		If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.
	
	.EXAMPLE
		PS C:\> Update-MDFolderPermission -DaemonUser 'domain\srv_server1mail$'
	
		Grants Daemon User privileges on the local computer to the service account 'domain\srv_server1mail$'
#>
	[CmdletBinding(SupportsShouldProcess = $true)]
	Param (
		[Parameter(ValueFromPipeline = $true)]
		[PSFComputer[]]
		$ComputerName = $env:COMPUTERNAME,
		
		[PSCredential]
		$Credential,
		
		[string]
		$DaemonUser = " ",
		
		[string[]]
		$WriteUser = " "
	)
	
	begin
	{
		#region Permission Assigning Scriptblock
		$permissionScript = {
			param (
				[string]
				$DaemonUser,
				
				[string[]]
				$WriteUser
			)
			
			Import-Module MailDaemon
			
			$pickupPath = (Get-PSFConfigValue -FullName 'MailDaemon.Daemon.MailPickupPath')
			$sentPath = (Get-PSFConfigValue -FullName 'MailDaemon.Daemon.MailSentPath')
			
			if ($DaemonUser.Trim())
			{
				Write-PSFMessage -String 'Update-MDFolderPermission.Granting.DaemonUser' -StringValues $DaemonUser, $pickupPath, $sentPath
				$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($DaemonUser, 'Read, Write', 'Allow')
				
				$acl = Get-Acl -Path $pickupPath
				$acl.AddAccessRule($rule)
				$acl | Set-Acl -Path $pickupPath
				$acl = Get-Acl -Path $sentPath
				$acl.AddAccessRule($rule)
				$acl | Set-Acl -Path $sentPath
			}
			foreach ($user in $WriteUser)
			{
				if ($user.Trim()) { continue }
				Write-PSFMessage -String 'Update-MDFolderPermission.Granting.WriteUser' -StringValues $user, $pickupPath
				$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($user, 'Write', 'Allow')
				
				$acl = Get-Acl -Path $pickupPath
				$acl.AddAccessRule($rule)
				$acl | Set-Acl -Path $pickupPath
			}
		}
		#endregion Permission Assigning Scriptblock
	}
	process
	{
		#region Modules must be installed and current
		if ($moduleResult = Test-Module -ComputerName $ComputerName -Credential $Credential -Module @{
				MailDaemon  = $script:ModuleVersion
				PSFramework = (Get-Module -Name PSFramework).Version
			} | Where-Object Success -EQ $false)
		{
			Stop-PSFFunction -String 'General.ModuleMissing' -StringValues ($moduleResult.ComputerName -join ", ") -EnableException $true -Cmdlet $PSCmdlet
		}
		#endregion Modules must be installed and current
		
		if (Test-PSFShouldProcess -PSCmdlet $PSCmdlet -Target ($ComputerName -join ", ") -Action "Granting the write permissions needed by the Daemon User ($($DaemonUser)) and Write User ($($WriteUser -join ', '))")
		{
			Invoke-PSFCommand -ComputerName $ComputerName -Credential $Credential -ScriptBlock $permissionScript -ArgumentList $DaemonUser, $WriteUser
		}
	}
}