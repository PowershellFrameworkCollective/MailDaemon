function Connect-MDGraph {
	<#
	.SYNOPSIS
		Connects to graph as configured. If configured.
	
	.DESCRIPTION
		Connects to graph as configured. If configured.
		
	.EXAMPLE
		PS C:\> Connect-MDGraph

		Connects to graph as configured. If configured.
	#>
	[CmdletBinding()]
	param ()
	process {
		$settings = Select-PSFConfig -FullName 'MailDaemon.Daemon.Graph.*'
		if ($settings.NoAuth) { return }

		if ($settings.Identity) {
			Connect-EntraService -Service Graph -Identity
			return
		}

		if (-not $settings.ClientID -or -not $settings.TenantID) {
			Stop-PSFFunction -String 'Connect-MDGraph.Error.NoClientIDorTenantID' -EnableException $true -Cmdlet $PSCmdlet -Category InvalidData
		}

		if (
			-not $settings.CertificateName -and
			-not $settings.CertificateThumbprint -and
			-not $settings.Federated
		) {
			Stop-PSFFunction -String 'Connect-MDGraph.Error.NoAuthPath' -EnableException $true -Cmdlet $PSCmdlet -Category InvalidData
		}

		$idParam = $settings | ConvertTo-PSFHashtable -Include ClientID, TenantID

		if ($settings.Federated) {
			Connect-EntraService @idParam -Federated
			return
		}
		if ($settings.CertificateThumbprint) {
			Connect-EntraService @idParam -CertificateThumbprint $settings.CertificateThumbprint
			return
		}
		if ($settings.CertificateName) {
			Connect-EntraService @idParam -CertificateName $settings.CertificateName
			return
		}
	}
}