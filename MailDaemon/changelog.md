# Changelog

## 1.3.19 (2026-05-28)

+ Major: Added capability to send emails by Graph API, rather than SMTP.
+ New: Configuration Setting 'MailDaemon.Daemon.Type' - determins whether to send email by Smtp or Graph.
+ New: Configuration Settings to define Graph behavior: 'MailDaemon.Daemon.Graph.*'
+ Upd: New dependency: EntraAuth - implements the Graph API authentication and interaction.
+ Upd: Mail Tasks are now stored in PSFramework CliDat format to save disk space. New client tasks cannot be processed by old agent versions.

## 1.2.14 (2026-02-12)

+ Fix: Update-MDFolderPermission - does not set permissions for the failed folder

## 1.2.13 (2026-02-11)

+ New: Emails that could not be sent will no longer be permanently attempted to resend - after 14 days
+ Upd: Install-MDDaemon - now supports remote-deployment of the daemon task using credentials
+ Upd: Install-MDDaemon - now installs eventlog for MailDaemon
+ Upd: Invoke-MDDaemon - adds logging to the Windows Eventlog by default
+ Fix: Install-MDDaemon - no longer fails when the daemon task already exists
+ Fix: Invoke-MDDaemon - fails to use authentication for SMTP

## 1.1.7 (2026-02-10)

+ Upd: Invoke-MDDaemon - implements `UseSSL` as configured
+ Upd: Set-MDDaemon - supports `-UseSSL`
+ Upd: Install-MDDaemon - supports `-UseSSL`
+ Fix: Install-MDDaemon - now exports credentials without prompting.

## 1.1.3 (2024-11-11)

+ Upd: Added ability to directly embed attachments in the email task, rather than only providing a path to them. (thanks @jebbster88 ; #10)
+ Upd: Added ability to specify mail priority. (thanks @jebbster88 ; #10)

## 1.0.1 (2023-10-06)

+ Fix: Invoke-MDDaemon - errors trying to multiply timespan

## 1.0.0 (2023-10-05)

+ General: Project Upgrade to the latest project template (including the tests).
+ Fix: Emails can only be sent from the same PowerShell edition it was installed to.
+ Fix: Add-MDMailContent - ignores attachment parameter

## 0.1.1 (2019-02-09)

+ Fix: Bug in Install-MDDaemon causing errors during installation

## 0.1.0 (2019-02-09)

+ New: Everything
