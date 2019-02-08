function Set-MDMail
{
	<#
		.SYNOPSIS
			Changes properties for the upcoming mail to queue.

		.DESCRIPTION
			This command sets up the email to send, configuring properties such as the sender, recipient or content.

		.PARAMETER From
			The email address of the sender.

		.PARAMETER To
			The email address to send to.

		.PARAMETER Cc
			Additional addresses to keep in the information flow.

		.PARAMETER Subject
			The subject to send the email under.

		.PARAMETER Body
			The body of the email to send.
			You can individually add content to the body using Add-MDMailContent.
		
		.PARAMETER BodyAsHtml
			Whether the body is to be understood as html text.

		.PARAMETER Attachments
			Any attachments to send.
			Avoid sending large attachments with emails.
			You can individually add attachments to the email using Add-MDMailContent (using this parameter will replace attachments sent).
		
		.PARAMETER RemoveAttachments
			After sending the email, remove the attachments sent.
			Use this to have the system clean up temporary files you wrote before sending this report.

		.PARAMETER NotBefore
			Do not send this email before this timestamp has come to pass.

		.EXAMPLE
			PS C:\> Set-MDMail -From 'script@contoso.com' -To 'support@contoso.com' -Subject 'Daily Update Report' -Body $body

			Sends an email as script@contoso.com to support@contoso.com, reporting on the daily update status.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	Param (
		[string]
		$From,

		[string]
		$To,

		[string[]]
		$Cc,

		[string]
		$Subject,

		[string]
		$Body,

		[switch]
		$BodyAsHtml,

		[string]
		$Attachments,

		[switch]
		$RemoveAttachments,

		[datetime]
		$NotBefore
	)
	
	begin
	{
		if (-not $script:mail)
		{
			$script:mail = @{ }
		}
	}
	process
	{
		if ($From) { $script:mail["From"] = $From }
		if ($To) { $script:mail["To"] = $To }
		if ($Cc) { $script:mail["Cc"] = $Cc }
		if ($Subject) { $script:mail["Subject"] = $Subject }
		if ($Body) { $script:mail["Body"] = $Body }
		if ($BodyAsHtml.IsPresent) { $script:mail["BodyAsHtml"] = ([bool]$BodyAsHtml) }
		if ($Attachments) { $script:mail["Attachments"] = $Attachments }
		if ($RemoveAttachments.IsPresent) { $script:mail["RemoveAttachments"] = ([bool]$RemoveAttachments) }
		if ($NotBefore) { $script:mail["NotBefore"] = $NotBefore }
	}
}
