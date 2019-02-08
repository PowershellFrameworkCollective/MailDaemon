function Save-MDCredential
{
	<#
		.SYNOPSIS
			Stores credentials securely for use by the specified account.

		.DESCRIPTION
			This command encrypts credentials to a protected credentials file in the file system.
			This is designed to allow storing credential objects for use by scheduled task that run as SYSTEM or a service account.

		.PARAMETER Credential
			The credentials to encrypt and write to file.

		.PARAMETER Path
			The path where to store the credential.
			Always considered as local path from the computer it is registered on.

		.PARAMETER AccessAccount
			The account that should have access to the credential.
			Defaults to the system account.
			Offer a full credentials object for a regular user account.

		.PARAMETER ComputerName
			The computer(s) to write the credential to.

		.EXAMPLE
			PS C:\> Save-MDCredential -ComputerName DC1,DC2,DC3 -Credential $cred -Path "C:\ProgramData\PowerShell\Tasks\tesk1_credential.clixml"

			Saves the credentials stored in $cred on the computers DC1, DC2, DC3 for use by the SYSTEM account
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[PSCredential]
		$Credential,

		[Parameter(Mandatory = $true)]
		[string]
		$Path,

		[PSCredential]
		$AccessAccount,

		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias('DNSHostName')]
		[string[]]
		$ComputerName = $env:COMPUTERNAME
	)

	process
	{
		$parameters = @{
			ArgumentList = $Credential, $Path, $AccessAccount
		}
		if ($env:COMPUTERNAME -ne $ComputerName) { $parameters['ComputerName'] = $ComputerName }
		Invoke-Command @parameters -ScriptBlock {
			Param (
				[PSCredential]
				$Credential,

				[string]
				$Path,

				[PSCredential]
				$AccessAccount
			)

			#region Folder Management
			if (Test-Path -Path $Path)
			{
				$item = Get-Item $Path
				if ($item.PSIsContainer)
				{
					$folder = $item.FullName
					$file = Join-Path $folder 'Credential.clixml'
				}
				else
				{
					$folder = Split-Path $item.FullName
					$file = $item.FullName
				}
			}
			else
			{
				if ([System.IO.Path]::GetExtension($Path))
				{
					$folder = Split-Path $Path
					$file = $Path
				}
				else
				{
					$folder = $Path
					$file = Join-Path $folder 'Credential.clixml'
				}
			}
			if (-not (Test-Path -Path $folder))
			{
				$null = New-Item -Path $folder -ItemType Directory -Force -ErrorAction Stop
			}
			#endregion Folder Management

			#region Access Privileges
			$accessUserName = $AccessAccount.UserName
			if (-not $accessUserName) { $accessUserName = "SYSTEM" }
			$acl = Get-Acl -Path $folder
			if (-not ($acl.Access | Where-Object IdentityReference -like $accessUserName | Where-Object {
				($_.FileSystemRights -Band 278) -and ($_.FileSystemRights -Band 65536)
			}))
			{
				$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($accessUserName, 'Read, Write', 'Allow')
				$null = $acl.AddAccessRule($rule)
				$acl | Set-Acl -Path $folder
			}
			#endregion Access Privileges

			#region Create Task
			$folderCleaned = (Get-Item $folder).FullName
			$credFile = "{0}\{1}.txt" -f $folderCleaned, ([guid]::NewGuid())
			$task = {
				$password = [System.IO.File]::ReadAllText("<credfile>")
				Remove-Item -Path "<credfile>"
				$credential = New-Object PSCredential("<username>", ($password | ConvertTo-SecureString -AsPlainText -Force))
				$credential | Export-Clixml -Path "<exportPath>"
			}
			$commandString = $task.ToString().Replace("<credfile>", $credFile).Replace("<username>", $Credential.UserName).Replace("<exportPath>", $file)
			$encodedCommand = [convert]::ToBase64String(([System.Text.Encoding]::Unicode.GetBytes($commandString)))

			$action = New-ScheduledTaskAction -Execute powershell.exe -Argument "-NoProfile -EncodedCommand $encodedCommand"
			
			if ($accessUserName -ne "SYSTEM") { $principal = New-ScheduledTaskPrincipal -UserId $accessUserName -LogonType Interactive }
			else { $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType Interactive }
			$taskItem = New-ScheduledTask -Action $action -Principal $principal -Description "Temporary Task"
			$parametersRegister = @{
				TaskName = "TempTask_$([guid]::NewGuid())"
				InputObject = $taskItem
			}
			if ($accessUserName -ne "SYSTEM")
			{
				$parametersRegister["User"] = $AccessAccount.UserName
				$parametersRegister["Password"] = $AccessAccount.GetNetworkCredential().Password
			}
			$null = Register-ScheduledTask @parametersRegister
			#endregion Create Task

			#region Perform Encryption
			[System.IO.File]::WriteAllText($credFile, $Credential.GetNetworkCredential().Password)
			Start-ScheduledTask -TaskName $parametersRegister.TaskName
			Start-Sleep -Seconds 5
			#endregion Perform Encryption

			#region Cleanup
			Unregister-ScheduledTask -TaskName $parametersRegister.TaskName -Confirm:$false
			if (Test-Path -Path $credFile)
			{
				try { Remove-Item $credFile -Force -ErrorAction Stop }
				catch
				{
					Write-Warning "[$env:COMPUTERNAME] Clear Text Credential File still exists!! $credFile | $_"
				}
			}
			if (-not (Test-Path -Path $file))
			{
				throw "[$env:COMPUTERNAME] Failed to create credential file! ($file)"
			}
			#endregion Cleanup
		}
	}
}
