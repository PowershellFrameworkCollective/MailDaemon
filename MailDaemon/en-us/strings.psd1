# This is where the strings go, that are written by
# Write-PSFMessage, Stop-PSFFunction or the PSFramework validation scriptblocks
@{
	# General
	'General.ModuleMissing'						    = 'The MailDaemon module could not be found in sufficient version on: {0}. Terminating Execution. To install or update to the current version, use Install-MDDaemon or access the PSGallery directly using "Install-Module MailDaemon".'
	
	# Invoke-MDDaemon
	'Invoke-MDDaemon.SendMail.Start'			    = '{0} - Sending Mail: "{1}" From {2} to {3}'
	'Invoke-MDDaemon.SendMail.Failed'			    = '{0} - Failed to send email!'
	'Invoke-MDDaemon.SendMail.Success'			    = '{0} - Email sent successfully'
	'Invoke-MDDaemon.ManageSuccessJob.Failed'	    = '{0} - Failed to move mail task to the "sent" folder!'
	
	# Copy-Module
	'Copy-Module.ReceivingModule'				    = 'Receiving Module from {0}: {1}'
	'Copy-Module.ReceivingModule.Failed'		    = 'Failed to receive Module from {0}: {1}'
	'Copy-Module.InstallingModule'				    = 'Installing module {0} on: {1}'
	
	# Send-MDMail
	'Send-MDMail.Folder.CreationFailed'			    = 'Failed to create outgoing mail folder: {0}'
	'Send-MDMail.Email.NotRegisteredYet'		    = 'No email has been set up yet!'
	'Send-MDMail.Email.Sending'					    = 'Queueing email for sending: {0}'
	'Send-MDMail.Email.SendingFailed'			    = 'Failed to queue email for sending: {0}'
	'Send-MDMail.Email.TriggerFailed'			    = 'Failed to trigger the Mail Daemon task to send {0}'
	
	# Set-MDDaemon
	'Set-MDDaemon.UpdatingSettings'				    = 'Starting Daemon configuration update on {0}'
	'Set-MDDaemon.UpdateSetting'				    = 'Updating the Daemon configuration setting {0} to {1}'
	
	# Update-MDFolderPermission
	'Update-MDFolderPermission.Granting.DaemonUser' = 'Assigning write permissions as daemon account to {0} on "{1}" and "{2}"'
	'Update-MDFolderPermission.Granting.WriteUser'  = 'Assigning write permissions as mail submitter to {0} on "{1}"'
}