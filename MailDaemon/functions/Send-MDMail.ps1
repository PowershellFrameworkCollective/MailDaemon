function Send-MDMail
{
	<#
		.SYNOPSIS
			Queues current email for delivery.

		.DESCRIPTION
			Uses the data prepared by Set-MDMail or Add-MDMailContent and queues the email for delivery.
			Writes to eventlog with ID 666 if this fails.

		.PARAMETER TaskName
			Name of the task that is sending the email.
			Used in the name of the file used to queue messages in order to reduce likelyhood of accidental clash.
		
		.EXAMPLE
			PS C:\> Send-MDMail -TaskName "Logrotate"

			Queues the currently prepared email under the name "Logrotate"
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$TaskName
	)
	
	begin
	{
		# Ensure the pickup patch exists
		if (-not (Test-Path $script:_Config.MailPickupPath))
		{
			try { $null = New-Item -Path $script:_Config.MailPickupPath -ItemType Directory -Force -ErrorAction Stop }
			catch
			{
				Write-Log -Type 'Error' -Message "Failed to create outgoing mail folder: $_"
				throw
			}
		}
	}
	process
	{
		# Don't send an email if nothing was set up
		if (-not $script:mail) { throw "No mail queued yet!" }

		$script:mail['Taskname'] = $TaskName

		# Send the email
		try { [PSCustomObject]$script:mail | Export-Clixml -Path "$($script:_Config.MailPickupPath)\$($TaskName)-$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').clixml" -ErrorAction Stop }
		catch
		{
			Write-Log -Type 'Error' -Message "Failed to write outgoing email: $_"
			throw
		}

		# Reset email, now that it is queued
		$script:mail = $null

		try { Start-ScheduledTask -TaskName MailDaemon -ErrorAction Stop }
		catch
		{
			Write-Log -Type 'Error' -Message "Failed to start daemon task: $_"
			throw
		}
	}
}
