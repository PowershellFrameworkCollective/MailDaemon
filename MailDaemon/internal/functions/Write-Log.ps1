function Write-Log
{
	<#
		.SYNOPSIS
			Writes an eventlog message.

		.DESCRIPTION
			Writes eventlog messages for the module's commands
			Use sparingly.
		
		.PARAMETER Type
			The type of message to write.

		.PARAMETER Message
			The message to write.

		.EXAMPLE
			PS C:\> Write-Log -Message 'Email sent'

			Writes an eventlog message with the text 'Email Sent' as informational message to the eventlog.
	#>
	[CmdletBinding()]
	Param (
		[ValidateSet('Information', 'Error')]
		[string]
		$Type = 'Information',

		[string]
		$Message
	)
	
	$source = 'Application'
	$id = 1000
	if ($Type -eq 'Error') {
		$source = 'Application Error'
		$id = 666
	}
	
	Write-EventLog -LogName Application -Source $source -EntryType $Type -Category 1 -EventId $id -Message "[PS Mail Daemon] $Message"
}
