function Test-Module
{
<#
	.SYNOPSIS
		Tests for module existence.
	
	.DESCRIPTION
		Tests whether a module - or set of modules - exists on the target machine(s).
		Includes support for version requirements (minimum or maximum).
	
	.PARAMETER Name
		Name of the module(s) to search for.
	
	.PARAMETER Version
		The version constraint.
		Whether that is the minimum, maximum or exactly this version is governed by the -Test parameter.
		The same version constraint will be applied to all modules specified!
		For custom versions per module, please use the -Module parameter to specify a hashtable with the mapping.
	
	.PARAMETER Module
		The combination of modules and versions to test.
		Specify the modulename as key and the version as value.
		E.g.: @{ MailDaemon = '1.0.0' }
		Specify '0.0' in order to not test about any specific version.
	
	.PARAMETER Test
		How to test for version.
		By default, the test will search for 'GreaterEqual' (that is: At least the specified version).
		Supported scenarios: 'LesserThan', 'LesserEqual', 'Equal', 'GreaterEqual', 'GreaterThan'
		Note on Lesser* comparisons: This only tests whether a version below the limit is present. It does not Test that NO greater version is available!
	
	.PARAMETER Quiet
		Disables output objects and instead returns $true if all modules specified meet the requirements, $false if not so.
	
	.PARAMETER ComputerName
		The computers on which to test.
		Uses WinRM / PowerShell Remoting to perform test.
	
	.PARAMETER Credential
		The credentials to use for connecting to computers for the test.
		Will be ignored for localhost.
	
	.EXAMPLE
		PS C:\> Test-Module -Name 'MyModule'
	
		Tests whether the module MyModule is available in any version.
	
	.EXAMPLE
		PS C:\> Test-Module -Name MailDaemon -Version 1.1.0 -ComputerName 'server1', 'Server2'
	
		Tests whether the module MailDaemon is available in at least version 1.1.0 on the computers server1 and server2.
	
	.EXAMPLE
		PS C:\> Test-Module -Name PSFramework -Version 1.0.0 -Quiet -Test 'Equal'
	
		Returns $true if the module PSFramework exists locally in exactly version 1.0.0, $false otherwise.
	
	.EXAMPLE
		PS C:\> Test-Module -Module @{ PSFramework = '1.0.0'; MailDaemon = '1.1.0' } -Test 'LesserThan'
	
		Returns whether PSFramework is present in any version less than 1.0.0
		Returns whether MailDaemon is present in any version less than 1.1.0
#>
	[CmdletBinding(DefaultParameterSetName = 'Name')]
	param (
		[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Name')]
		[string[]]
		$Name,
		
		[Parameter(Position = 1, ParameterSetName = 'Name')]
		[version]
		$Version = '0.0.0.0',
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Hash')]
		[hashtable]
		$Module = @{ },
		
		[ValidateSet('LesserThan', 'LesserEqual', 'Equal', 'GreaterEqual', 'GreaterThan')]
		[string]
		$Test = 'GreaterEqual',
		
		[switch]
		$Quiet,
		
		[Parameter(ValueFromPipeline = $true)]
		[PSFComputer[]]
		$ComputerName = $env:COMPUTERNAME,
		
		[AllowNull()]
		[PSCredential]
		$Credential
	)
	
	begin
	{
		#region Prepare Module parameter
		$moduleHash = $Module
		foreach ($moduleName in $Name)
		{
			$moduleHash[$moduleName] = $Version
		}
		foreach ($key in ([string[]]$moduleHash.Keys))
		{
			$moduleHash[$key] = $moduleHash[$key] -as [Version]
			if (-not $moduleHash[$key]) { $moduleHash[$key] = ([Version]'0.0.0.0') }
		}
		#endregion Prepare Module parameter
		
		#region Validation Scriptblock
		$scriptBlock = {
			param (
				[hashtable]
				$ModuleHash,
				
				[string]
				$Test,
				
				[bool]
				$Quiet
			)
			
			#region Utility Functions
			function Write-Result
			{
				[CmdletBinding()]
				param (
					[string]
					$Name,
					
					$Success,
					
					[AllowNull()]
					[AllowEmptyCollection()]
					$VersionsFound,
					
					[string]
					$Test
				)
				
				$result = [bool]$Success
				
				[PSCustomObject]@{
					Name		  = $Name
					Success	      = $result
					VersionsFound = $VersionsFound
					ComputerName  = $env:COMPUTERNAME
					Test		  = $Test
				}
			}
			#endregion Utility Functions
			
			#region Validate each module specified
			foreach ($module in $ModuleHash.Keys)
			{
				$modulesFound = Get-Module -Name $module -ListAvailable
				if ($Quiet -and (-not $modulesFound)) { return $false }
				
				if ($ModuleHash[$module] -le '0.0.0.0')
				{
					Write-Result -Name $module -Success $modulesFound -VersionsFound $modulesFound.Version -Test $Test
					continue
				}
				
				#region Quiet Validation [Calls Continue]
				if ($Quiet)
				{
					switch ($Test)
					{
						'LesserThan' { if (-not ($modulesFound | Where-Object Version -LT $ModuleHash[$module])) { return $false } }
						'LesserEqual' { if (-not ($modulesFound | Where-Object Version -LE $ModuleHash[$module])) { return $false } }
						'Equal' { if (-not ($modulesFound | Where-Object Version -EQ $ModuleHash[$module])) { return $false } }
						'GreaterEqual' { if (-not ($modulesFound | Where-Object Version -GE $ModuleHash[$module])) { return $false } }
						'GreaterThan' { if (-not ($modulesFound | Where-Object Version -GT $ModuleHash[$module])) { return $false } }
					}
					continue
				}
				#endregion Quiet Validation [Calls Continue]
				
				switch ($Test)
				{
					'LesserThan' { Write-Result -Name $module -Success ($modulesFound | Where-Object Version -LT $ModuleHash[$module]) -VersionsFound $modulesFound.Version -Test $Test }
					'LesserEqual' { Write-Result -Name $module -Success ($modulesFound | Where-Object Version -LE $ModuleHash[$module]) -VersionsFound $modulesFound.Version -Test $Test }
					'Equal' { Write-Result -Name $module -Success ($modulesFound | Where-Object Version -EQ $ModuleHash[$module]) -VersionsFound $modulesFound.Version -Test $Test }
					'GreaterEqual' { Write-Result -Name $module -Success ($modulesFound | Where-Object Version -GE $ModuleHash[$module]) -VersionsFound $modulesFound.Version -Test $Test }
					'GreaterThan' { Write-Result -Name $module -Success ($modulesFound | Where-Object Version -GT $ModuleHash[$module]) -VersionsFound $modulesFound.Version -Test $Test }
				}
			}
			#endregion Validate each module specified
			
			if ($Quiet) { return $true }
		}
		#endregion Validation Scriptblock
	}
	process
	{
		Invoke-PSFCommand -ComputerName $ComputerName -Credential $Credential -ScriptBlock $scriptBlock -ArgumentList $moduleHash, $Test, $Quiet.ToBool() -HideComputerName
	}
}