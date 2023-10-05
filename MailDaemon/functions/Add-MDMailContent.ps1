function Add-MDMailContent {
	<#
		.SYNOPSIS
			Adds content to a pending email.

		.DESCRIPTION
			Adds content to a pending email.
			Use this command to incrementally add to the mail sent.

		.PARAMETER Body
			Add text to the mail body.

		.PARAMETER Attachments
			Add files to the list of files to send.

		.EXAMPLE
			PS C:\> Add-MDMailContent -Body "Phase 3: Completed"

			Adds the line "Phase 3: Completed" to the email body.
	#>
	[CmdletBinding()]
	Param (
		[string]
		$Body,

		[string[]]
		$Attachments
	)
	
	begin {
		if (-not $script:mail) {
			$script:mail = @{ }
		}
	}
	process {
		if ($Body) {
			if (-not ($script:mail["Body"])) { $script:mail["body"] = $Body }
			else { $script:mail["Body"] = $script:mail["Body"], $Body -join "`n" }
		}
		if ($Attachments) { 
			if (-not $script:mail["Attachments"]) { $script:mail["Attachments"] = $Attachments }
			else { $script:mail["Attachments"] = @($script:mail["Attachments"]) + @($Attachments) }
		}
	}
}
