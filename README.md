# Description

The mail daemon module implements mailing infrastructure that enables tasks to reliably send email reports.

Benefits:

 - Will automatically retry on send failure during network issues
 - Centrally manageable email configuration
 - Tasks do not need access to mailing credentials
 - Eventlog entries on send failure and access to sent and pending emails for troubleshooting

# Setting up the Daemon

To start using this module, you need to first install it using `Install-MDDaemon`.

This step _cannot_ be replaced by `Install-Module`, as it is also used to set up intial configuration and setting up the task. However source code deployment can be done via `Install-Module`.

# Sending emails

To send emails, have your script use the following commands:

 - `Set-MDMail` to configure email parameters, such as subject, attachments or recipient
 - `Add-MDMailContent` to add content to the email body
 - `Send-MDMail` to queue the email for delivery and manually trigger the daemon task to try send right away