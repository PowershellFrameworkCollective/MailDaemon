Register-PSFConfigValidation -Name 'MailDaemon.Protocol' -ScriptBlock {
	param (
		$Value
	)

	$Result = [PSCustomObject]@{
		Success = $True
		Value   = $null
		Message = ""
	}

	$legalValues = 'Smtp', 'Graph'

	if ("$Value" -notin $legalValues) {
		$Result.Message = "Illegal Mail Protocol: $Value | Legal Options: $($legalValues -join ', ')"
		$Result.Success = $False
		return $Result
	}

	$Result.Value = "$Value"

	return $Result
}