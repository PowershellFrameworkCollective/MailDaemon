@{
	# Script module or binary module file associated with this manifest
	RootModule = 'MailDaemon.psm1'
	
	# Version number of this module.
	ModuleVersion = '1.0.0'
	
	# ID used to uniquely identify this module
	GUID = 'd5ba333f-5210-4d69-83f0-150dd0909139'
	
	# Author of this module
	Author = 'Friedrich Weinmann'
	
	# Company or vendor of this module
	CompanyName = ' '
	
	# Copyright statement for this module
	Copyright = 'Copyright (c) 2019 Friedrich Weinmann'
	
	# Description of the functionality provided by this module
	Description = 'Mail Daemon as PowerShell Module'
	
	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion = '5.0'
	
	# Modules that must be imported into the global environment prior to importing
	# this module
	RequiredModules = @(
		@{ ModuleName='PSFramework'; ModuleVersion='1.9.310' }
	)
	
	# Assemblies that must be loaded prior to importing this module
	# RequiredAssemblies = @('bin\MailDaemon.dll')
	
	# Type files (.ps1xml) to be loaded when importing this module
	# TypesToProcess = @('xml\MailDaemon.Types.ps1xml')
	
	# Format files (.ps1xml) to be loaded when importing this module
	# FormatsToProcess = @('xml\MailDaemon.Format.ps1xml')
	
	# Functions to export from this module
	FunctionsToExport = @(
		'Add-MDMailContent'
		'Install-MDDaemon'
		'Invoke-MDDaemon'
		'Save-MDCredential'
		'Send-MDMail'
		'Set-MDDaemon'
		'Set-MDMail'
		'Update-MDFolderPermission'
	)
	
	# Cmdlets to export from this module
	CmdletsToExport = @()
	
	# Variables to export from this module
	VariablesToExport = @()
	
	# Aliases to export from this module
	AliasesToExport = @()
	
	# List of all modules packaged with this module
	ModuleList = @()
	
	# List of all files packaged with this module
	FileList = @()
	
	# Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData = @{
		
		#Support for PowerShellGet galleries.
		PSData = @{
			
			# Tags applied to this module. These help with module discovery in online galleries.
			Tags = @('mail')
			
			# A URL to the license for this module.
			LicenseUri = 'https://github.com/PowershellFrameworkCollective/MailDaemon/blob/master/LICENSE'
			
			# A URL to the main website for this project.
			ProjectUri = 'https://github.com/PowershellFrameworkCollective/MailDaemon'
			
			# A URL to an icon representing this module.
			# IconUri = ''
			
			# ReleaseNotes of this module
			ReleaseNotes = 'https://github.com/PowershellFrameworkCollective/MailDaemon/blob/master/MailDaemon/changelog.md'
			
		} # End of PSData hashtable
		
	} # End of PrivateData hashtable
}