function Publish-GraphAttachment {
	<#
	.SYNOPSIS
		Adds a file-attachment to an email draft.
	
	.DESCRIPTION
		Adds a file-attachment to an email draft.
		Uses an upload session and can upload attachments up to 150MB.
	
	.PARAMETER Path
		Path to the file to upload.
	
	.PARAMETER Message
		The graph-path to the email draft.
		E.g.: "users/<userid>/messages/$($draft.id)"
	
	.EXAMPLE
		PS C:\> Publish-GraphAttachment -Path $attachment -Message "users/$From/messages/$($draft.id)"
		
		Uploads the specified file as attachment to the specified draft message.
	#>
	[CmdletBinding()]
	param (
		[string]
		$Path,

		[string]
		$Message
	)

	$file = Get-Item -Path $Path
	$session = Invoke-EntraRequest -Method POST -Path "$Message/attachments/createUploadSession" -ContentType 'application/json' -Body @{
		AttachmentItem = @{
			attachmentType = 'file'
			name = $file.Name
			size = $file.Length
		}
	}

	$null = Invoke-RestMethod -Method Put -Uri $session.uploadUrl -InFile $file.FullName -Headers @{
		'Content-Range' = "bytes 0-$($file.Length - 1)/$($file.Length)"
		'Content-Type'  = 'application/octet-stream'
	}
}