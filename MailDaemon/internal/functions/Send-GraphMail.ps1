function Send-GraphMail {
	<#
	.SYNOPSIS
		Sends an email via Graph API.
	
	.DESCRIPTION
		Sends an email via Graph API.
		Must be connected to Graph first using Connect-EntraService.
	
	.PARAMETER From
		Who sends the email.
		Provide the UPN to the user account, will use the default email address only.
	
	.PARAMETER To
		Recipient of the email.
	
	.PARAMETER Cc
		Additional recipients of the email.
	
	.PARAMETER Bcc
		Even more recpients of the email.
		Invisible to each other.
	
	.PARAMETER Subject
		Subject of the email to send.
		Defaults to "<no subject>"
	
	.PARAMETER Body
		Body (text) of the email.
	
	.PARAMETER BodyAsHtml
		Whether the email is to be sent as html body.
		Will be sent as a plaintext email if not specified.
	
	.PARAMETER Attachments
		Any files to include in the email.
	
	.PARAMETER Priority
		The priority to assign to the email
	
	.EXAMPLE
		PS C:\> Send-GraphMail -From fred@contoso.com -To Max@contoso.com -Subject Test -Body "Test Mail"

		Sends a simple test email.
	#>
	[CmdletBinding()]
	param (
		[string]
		$From,

		[string[]]
		$To,

		[string[]]
		$Cc,

		[string[]]
		$Bcc,
		
		[string]
		$Subject = '<no subject>',

		[string]
		$Body,
		
		[switch]
		$BodyAsHtml,

		[string[]]
		$Attachments,

		[ValidateSet('Low', 'Normal', 'High')]
		[string]
		$Priority
	)

	Assert-EntraConnection -Service Graph -Cmdlet $PSCmdlet

	$draft = $null

	try{
		# Step 1: Create Draft
		$reqBody = @{
			subject = $Subject
		}
		if ($Body) {
			$reqBody["body"] = @{
				contentType = 'text'
				content = $Body
			}
			if ($BodyAsHtml) { $reqBody.body.contentType = 'html' }
		}
		if ($To) {
			$reqBody['toRecipients'] = @()
			foreach ($entry in $To) {
				$reqBody['toRecipients'] += @{ emailAddress = @{ address = $entry } }
			}
		}
		if ($Cc) {
			$reqBody['ccRecipients'] = @()
			foreach ($entry in $Cc) {
				$reqBody['ccRecipients'] += @{ emailAddress = @{ address = $entry } }
			}
		}
		if ($Bcc) {
			$reqBody['bccRecipients'] = @()
			foreach ($entry in $Bcc) {
				$reqBody['bccRecipients'] += @{ emailAddress = @{ address = $entry } }
			}
		}
		if ($Priority) {
			$reqBody['importance'] = $Priority.ToLower()
		}

		$draft = Invoke-EntraRequest -Method Post -Path "users/$From/messages" -Header @{
			'Content-Type' = 'application/json'
		} -Body $reqBody

		# Step 2: Upload Attachments
		foreach ($attachment in $Attachments) {
			Publish-GraphAttachment -Path $attachment -Message "users/$From/messages/$($draft.id)"
		}

		# Step 3: Send
		$null = Invoke-EntraRequest -Method POST -Path "users/$From/messages/$($draft.id)/send"
	}
	catch {
		# Step X: Undo on failure
		if ($draft) {
			Invoke-EntraRequest -Method DELETE -Path "users/$From/messages/$($draft.id)"
		}
		throw
	}
}