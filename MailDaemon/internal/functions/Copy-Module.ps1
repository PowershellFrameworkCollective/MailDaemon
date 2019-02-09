function Copy-Module
{
<#
	.SYNOPSIS
		Copies a module from one computer to another.
	
	.DESCRIPTION
		Copies a module from one computer to another.
		All transfers done via WinRM / Powershell Remoting.
	
	.PARAMETER ModuleName
		The name of the module to copy.
		Also accepts a path to the module root folder.
	
	.PARAMETER ModuleObject
		A specific module instance to copy (returned by Get-Module).
	
	.PARAMETER FromComputer
		The computer from which to pick up the module.
		Localhost by default.
		Accepts and reuses PSSession objects.
	
	.PARAMETER ToComputer
		The computer(s) on which to install the module.
		Accepts and reuses PSSession objects.
	
	.PARAMETER Credential
		The credentials to use when connecting to computers.
	
	.EXAMPLE
		PS C:\> Copy-Module -ModuleName BeerFactory -ToComputer server1
	
		Copies the module 'BeerFactory' from localhost to server1
#>
	
	[CmdletBinding(DefaultParameterSetName = 'Object')]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'String', Position = 0)]
		[string[]]
		$ModuleName,
		
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'Object')]
		[PSModuleInfo[]]
		$ModuleObject,
		
		[Parameter(Mandatory = $true)]
		[PSFComputer[]]
		$ToComputer,
		
		[PSFComputer]
		$FromComputer = $env:COMPUTERNAME,
		
		[PSCredential]
		$Credential
	)
	
	begin
	{
		$receiveScript = {
			param (
				[string]
				$Module
			)
			
			#region Specified a path
			$uri = [uri]$Module
			if ($uri.IsFile)
			{
				if (-not (Test-Path $Module))
				{
					return [pscustomobject]@{
						Module  = $Module
						Success = $false
						Data    = @()
					}
				}
				
				$sourcePath = "$($Module)\*"
				$moduleName = (Get-Module $Module -ListAvailable).Name
				$moduleVersion = (Get-Module $Module -ListAvailable).Version
			}
			#endregion Specified a path
			#region Specified a module name
			else
			{
				$moduleObject = Get-Module $Module | Sort-Object Version -Descending | Select-Object -First 1
				if (-not $moduleObject)
				{
					return [pscustomobject]@{
						Module = $Module
						Success = $false
						Data = @()
					}
				}
				
				$sourcePath = "$($moduleObject.ModuleBase)\*"
				$moduleName = $moduleObject.Name
				$moduleVersion = $moduleObject.Version
			}
			#endregion Specified a module name
			
			#region Gather module object
			$tempPath = "$($env:TEMP)\$(New-Guid).zip"
			$workingFolder = New-Item -Path $env:TEMP -Name (New-Guid) -ItemType Directory
			# Copy item is important, as the zip commands cannot access locked dlls, copy-item can.
			Copy-Item -Path $sourcePath -Destination $workingFolder.FullName -Recurse
			Compress-Archive -Path "$($workingFolder.FullName)\*" -DestinationPath $tempPath
			[pscustomobject]@{
				Name    = $moduleName
				Version = $moduleVersion
				Data    = [System.IO.File]::ReadAllBytes($tempPath)
				Module  = $Module
				Success = $true
			}
			Remove-Item $tempPath
			Remove-Item $workingFolder.FullName -Recurse -Force
			#endregion Gather module object
		}
		
		$installScript = {
			param (
				$Modules
			)
			
			#region Update the modules
			foreach ($module in $Modules)
			{
				$installRoot = "$($env:ProgramFiles)\WindowsPowerShell\Modules"
				if (-not (Test-Path "$($installRoot)\$($module.Name)")) { $null = New-Item -Path $installRoot -Name $module.Name -ItemType Directory -Force }
				$root = New-Item -Path "$($installRoot)\$($module.Name)" -Name $module.Version -ItemType Directory -Force
				$tempPath = "$($env:TEMP)\$(New-Guid).zip"
				[System.IO.File]::WriteAllBytes($tempPath, $Module.Data)
				Expand-Archive -Path $tempPath -DestinationPath $root.FullName -Force
				Remove-Item $tempPath
			}
			#endregion Update the modules
		}
	}
	process
	{
		foreach ($name in $ModuleName)
		{
			Write-PSFMessage -String 'Copy-Module.ReceivingModule' -StringValues $FromComputer, $name
			$module = Invoke-PSFCommand -ComputerName $FromComputer -Credential $Credential -ScriptBlock $receiveScript -ArgumentList $name
			if (-not $module.Success)
			{
				Stop-PSFFunction -String 'Copy-Module.ReceivingModule.Failed' -StringValues $FromComputer, $name -Continue -SilentlyContinue -Cmdlet $PSCmdlet
			}
			Write-PSFMessage -String 'Copy-Module.InstallingModule' -StringValues $name, ($ToComputer -join ", ")
			Invoke-PSFCommand -ComputerName $ToComputer -Credential $Credential -ScriptBlock $installScript -ArgumentList $module
		}
		foreach ($object in $ModuleObject)
		{
			Write-PSFMessage -String 'Copy-Module.ReceivingModule' -StringValues $FromComputer, $object.ModuleBase
			$module = Invoke-PSFCommand -ComputerName $FromComputer -Credential $Credential -ScriptBlock $receiveScript -ArgumentList $object.ModuleBase
			if (-not $module.Success)
			{
				Stop-PSFFunction -String 'Copy-Module.ReceivingModule.Failed' -StringValues $FromComputer, $object.ModuleBase -Continue -SilentlyContinue -Cmdlet $PSCmdlet
			}
			Write-PSFMessage -String 'Copy-Module.InstallingModule' -StringValues $object.ModuleBase, ($ToComputer -join ", ")
			Invoke-PSFCommand -ComputerName $ToComputer -Credential $Credential -ScriptBlock $installScript -ArgumentList $module
		}
	}
}